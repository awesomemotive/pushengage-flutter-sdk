import Foundation
import XCTest

@testable import pushengage_flutter_sdk

// Unit tests for the iOS plugin's cold-boot `MessageBuffer` — the slot/queue
// that recovers a notification tap which launched the app from a force-quit
// state (delivered before the Dart isolate can listen on `deepLinkStream`).
//
// Ported from the React Native SDK's MessageBufferTests.swift; the Flutter
// `MessageBuffer` is an identical port, so the contract is verified the same
// way: the cold-boot tap lands in the initial-notification slot (drained once
// via getInitialNotification) and never also fires through the runtime
// callback (deepLinkStream).
//
// Run with: cd example/ios && xcodebuild test \
//   -workspace Runner.xcworkspace -scheme Runner \
//   -destination 'platform=iOS Simulator,name=iPhone 16'
final class MessageBufferTests: XCTestCase {

    // MARK: - Initial-notification slot (cold-boot pull API)

    func test_consumeInitialNotification_returnsFirstDeliveredMessage() {
        let buffer = MessageBuffer()
        buffer.deliver(["deepLink": "app://cold-boot", "data": ["k": "v"]])

        let initial = buffer.consumeInitialNotification()

        XCTAssertNotNil(initial)
        XCTAssertEqual(initial?["deepLink"] as? String, "app://cold-boot")
        XCTAssertEqual(initial?["data"] as? [String: String], ["k": "v"])
    }

    func test_consumeInitialNotification_secondCallReturnsNil() {
        let buffer = MessageBuffer()
        buffer.deliver(["deepLink": "app://cold-boot"])

        _ = buffer.consumeInitialNotification()
        let second = buffer.consumeInitialNotification()

        XCTAssertNil(second)
    }

    func test_consumeInitialNotification_neverDelivered_returnsNil() {
        let buffer = MessageBuffer()

        let initial = buffer.consumeInitialNotification()

        XCTAssertNil(initial)
    }

    func test_deliveryAfterSetCallback_doesNotPopulateInitialSlot() {
        // Once the runtime callback is wired, deliveries flow through it
        // exclusively — they must not also capture into the initial slot,
        // otherwise consumers see the same payload via both onDeepLink
        // and getInitialNotification.
        let buffer = MessageBuffer()
        buffer.setCallback { _ in }
        buffer.deliver(["deepLink": "app://runtime"])

        XCTAssertNil(buffer.consumeInitialNotification())
    }

    func test_consumeInitialNotification_doesNotReplaceWithLaterDeliveries() {
        // The "initial" slot represents the cold-boot launch notification —
        // subsequent runtime deliveries must not overwrite it before the
        // first pull. Once consumed, subsequent deliveries also do not
        // populate it (those are runtime taps, not cold-boot).
        let buffer = MessageBuffer()
        buffer.deliver(["deepLink": "app://first"])
        buffer.deliver(["deepLink": "app://second"])

        XCTAssertEqual(
            buffer.consumeInitialNotification()?["deepLink"] as? String,
            "app://first"
        )

        buffer.deliver(["deepLink": "app://third"])
        XCTAssertNil(buffer.consumeInitialNotification())
    }

    func test_deliver_beforeCallback_firstGoesToSlotOnly() {
        let buffer = MessageBuffer()

        // The first pre-callback delivery is the cold-boot tap. It must be
        // captured into the initial-notification slot only, NOT also queued
        // for replay through the callback — otherwise consumers that pull
        // via getInitialNotification AND have a callback subscriber active
        // would observe the same payload twice.
        buffer.deliver(["deepLink": "app://home", "data": ["k": "v"]])

        var callbackInvocations = 0
        buffer.setCallback { _ in callbackInvocations += 1 }

        XCTAssertEqual(callbackInvocations, 0,
                       "First pre-callback delivery must not replay through setCallback")
        XCTAssertEqual(
            buffer.consumeInitialNotification()?["deepLink"] as? String,
            "app://home"
        )
    }

    func test_deliver_beforeCallback_secondQueuedForCallbackReplay() {
        // Edge case: more than one pre-callback delivery (would require the SDK
        // to fire multiple queued taps before setCallback runs). The first goes
        // to the slot; subsequent ones queue for replay through the callback.
        let buffer = MessageBuffer()

        buffer.deliver(["deepLink": "app://slot"])
        buffer.deliver(["deepLink": "app://queued-1"])
        buffer.deliver(["deepLink": "app://queued-2"])

        var received: [String] = []
        buffer.setCallback { args in
            if let dl = args["deepLink"] as? String { received.append(dl) }
        }

        XCTAssertEqual(received, ["app://queued-1", "app://queued-2"])
        XCTAssertEqual(
            buffer.consumeInitialNotification()?["deepLink"] as? String,
            "app://slot"
        )
    }

    func test_deliver_afterCallback_firesImmediately() {
        let buffer = MessageBuffer()
        var received: [[String: Any]] = []
        buffer.setCallback { received.append($0) }

        buffer.deliver(["deepLink": "app://settings"])

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received[0]["deepLink"] as? String, "app://settings")
    }

    func test_setCallback_replacesPreviousCallback() {
        let buffer = MessageBuffer()

        var firstCallbackCalls = 0
        buffer.setCallback { _ in firstCallbackCalls += 1 }

        var secondCallbackCalls = 0
        buffer.setCallback { _ in secondCallbackCalls += 1 }

        buffer.deliver(["deepLink": "app://test"])

        // Only the most recently registered callback should fire.
        XCTAssertEqual(firstCallbackCalls, 0)
        XCTAssertEqual(secondCallbackCalls, 1)
    }

    func test_concurrentDeliver_threadSafe() {
        let buffer = MessageBuffer()
        let totalDeliveries = 100

        // Pre-register a callback that counts and records arrival.
        let receivedLock = NSLock()
        var received: [Int] = []
        buffer.setCallback { args in
            receivedLock.lock()
            if let idx = args["i"] as? Int { received.append(idx) }
            receivedLock.unlock()
        }

        // Hammer deliver() from many threads at once.
        DispatchQueue.concurrentPerform(iterations: totalDeliveries) { i in
            buffer.deliver(["i": i])
        }

        XCTAssertEqual(received.count, totalDeliveries,
                       "Every concurrent delivery should reach the callback exactly once")
        // Order isn't guaranteed under concurrentPerform; presence is.
        XCTAssertEqual(Set(received), Set(0..<totalDeliveries))
    }

    func test_deliver_emptyDict_handled() {
        let buffer = MessageBuffer()
        var received: [[String: Any]] = []
        buffer.setCallback { received.append($0) }

        buffer.deliver([:])

        XCTAssertEqual(received.count, 1)
        XCTAssertTrue(received[0].isEmpty)
    }
}
