## 1.1.0

Adds In-App Messaging and raises the minimum iOS version to 15.0.

### Breaking — minimum iOS raised to 15.0

This release pins the native iOS SDK **1.1.0**, which requires **iOS 15.0** (was 12.0).
Set `platform :ios, '15.0'` in your app's `ios/Podfile` (and the Runner target's
minimum deployment target) before upgrading. Apps that must still support iOS 12–14
should stay on version **1.0.0** of this plugin —
it remains available but does not receive In-App Messaging or later features.
The Android minimum is unchanged (API 21).

### Added

- **In-App Messaging.** Campaigns are fetched from the dashboard, stored locally and
  shown inside the app, with no push subscription or notification permission required.
  - `triggerIAMEvent(eventName, [parameters])` — show event-driven campaigns.
    Parameters are stringified natively before trigger matching, so numbers and
    booleans are accepted but compared as strings (`2` matches `"2"`).
  - `onIAMCustomAction` stream — emits an `IAMCustomAction` (`actionId` plus string
    `parameters`) when the user taps a `custom`-type button. Route on
    `parameters['action']` (the button's Action name on the dashboard); `actionId` is a
    dashboard-generated internal key. Buttons also support `open_url` (http/https only,
    opened externally), `dismiss` and `request_notification_permission`.
  - Audience targeting over device and subscriber-backed fields, per-campaign date
    windows, `one_time` / `capped` / `recurring` frequency caps, four display
    positions (`top`, `bottom`, `center`, `full`) with a priority queue, and
    impression/click analytics queued offline.

### Changed

- Native SDK pins raised: iOS `1.0.0` → `1.1.0`, Android `0.1.0` → `1.0.0` (the
  In-App Messaging releases of each).

### Fixed

- **iOS: apps on the UIScene life cycle.** Apps built with the iOS 27 SDK must use
  UIScene, which makes Flutter register plugins later, after app launch has finished.
  On older Flutter versions (seen on 3.35) the plugin's launch hook then never ran, so
  notification-tap and In-App Messaging custom-action callbacks were never set up. The
  plugin now sets up the native SDK as soon as it is registered, so it works on every
  Flutter version, with or without scenes. Your PushEngage integration needs no changes;
  to move the app itself to UIScene, follow Flutter's
  [UIScene migration guide](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)
  (Flutter 3.41+ migrates an unmodified `AppDelegate` automatically).

## 1.0.0

Adds subscriber identification, custom event tracking,
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

