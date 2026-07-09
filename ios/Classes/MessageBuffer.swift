import Foundation

/// Cold-boot replay buffer for notification-open events.
///
/// When iOS launches the app from a tapped push notification, the PushEngage
/// native SDK calls its `notificationOpenHandler` synchronously from inside
/// `setNotificationOpenHandler` — which the plugin registers during
/// `didFinishLaunchingWithOptions`, before the Dart isolate has run `main()`
/// and installed a method-call handler on the channel. Any tap delivered in
/// that gap would be lost (Flutter does not buffer native→Dart messages, and
/// the Dart `deepLinkStream` is a broadcast stream that does not replay to
/// late listeners).
///
/// `MessageBuffer` decouples the two events. The first pre-callback delivery —
/// the cold-boot tap — is captured into the initial-notification slot and is
/// exposed exclusively through `consumeInitialNotification()` (drained once by
/// the Dart `getInitialNotification()` call). Deliveries that arrive after the
/// Dart side signals readiness (`attachListeners` → `setCallback`) fire through
/// the callback immediately; any further pre-callback deliveries are queued and
/// replayed in arrival order when the callback is set. The slot and the
/// callback channel never carry the same payload. Access is serialized via
/// NSLock so concurrent deliveries from the SDK are safe.
final class MessageBuffer {
    /// Cap on the replay queue: an app that never signals Dart readiness must
    /// not accumulate payloads for the process lifetime. Oldest drop first.
    private static let maxPendingMessages = 32

    private var callback: (([String: Any]) -> Void)?
    private var pendingMessages: [[String: Any]] = []
    private var initialNotification: [String: Any]?
    private var initialConsumed: Bool = false
    private let lock = NSLock()

    /// Deliver a notification payload. Fires the callback synchronously if one
    /// is registered, otherwise buffers the payload (first → initial slot,
    /// subsequent → replay queue).
    func deliver(_ args: [String: Any]) {
        lock.lock()
        if let cb = callback {
            lock.unlock()
            cb(args)
            return
        }
        if initialNotification == nil && !initialConsumed {
            initialNotification = args
        } else {
            if pendingMessages.count >= MessageBuffer.maxPendingMessages {
                pendingMessages.removeFirst()
            }
            pendingMessages.append(args)
        }
        lock.unlock()
    }

    /// Register (or replace) the callback and immediately replay any buffered
    /// messages in FIFO order.
    func setCallback(_ callback: @escaping ([String: Any]) -> Void) {
        lock.lock()
        self.callback = callback
        let queued = pendingMessages
        pendingMessages.removeAll()
        lock.unlock()
        queued.forEach { callback($0) }
    }

    /// Pop and return the first delivered notification, if any. Idempotent —
    /// returns nil on subsequent calls.
    func consumeInitialNotification() -> [String: Any]? {
        lock.lock()
        let n = initialNotification
        initialNotification = nil
        initialConsumed = true
        lock.unlock()
        return n
    }
}
