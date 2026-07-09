## 1.0.0

First stable release. Adds subscriber identification, custom event tracking,
environment switching, badge control, cold-boot notification recovery, and FCM
configuration diagnostics, with behaviour aligned across iOS and Android.

### Added
- `setEnvironment(Environment)` — switch between staging and production. Must be called before `setAppId`.
- `getInitialNotification()` — recover the notification that cold-launched the app from a terminated state (iOS); resolves `null` on Android.
- `setBadgeCount(int)` — set or clear the app icon badge.
- `identify(IdentifyFields)` and `logout(List<String>?)` — subscriber identification across the 12 predefined fields.
- `trackEvent(TrackEventPayload)` — send custom workflow events.
- `runConfigValidation(senderId, projectId)` — validate the device's Firebase configuration (Android).
- `onFcmConfigError` stream — observe FCM configuration errors (Android).
- New models: `Environment`, `IdentifyFields`, `TrackEventPayload`, `FcmConfigError`.

### Changed
- `TriggerAlert.expiryTimestamp` is now serialized as a UTC ISO-8601 timestamp (fractional seconds + `Z`) so iOS and Android parse it identically.
- The SDK now reports its platform and wrapper version to PushEngage for attribution.
- `deepLinkStream` events now always carry `data` as a `Map` on both platforms (Android previously delivered a JSON string).
- `getSubscriberDetails` accepts a `null`/empty field list to fetch all fields, and returns a failure when the user is not subscribed (consistent across iOS, Android, and the native SDKs).

### Fixed
- iOS notifications that launch the app from a terminated state are no longer dropped — recover them via `getInitialNotification()`.
- Native SDK error callbacks with a null error code no longer crash on Android.

## 0.0.2

For detailed version history and comprehensive release notes, visit our GitHub releases page: https://github.com/awesomemotive/pushengage-flutter-sdk/releases

