<p align="center">
  <a href="https://www.pushengage.com">
    <img src="https://assetscdn.pushengage.com/site_assets/img/pushengage-logo.png" width="300" alt="PushEngage"/>
  </a>
</p>

<p align="center">
  <strong>Flutter Push Notification SDK</strong><br/>
  Add cross-platform push notifications to your Flutter app.
</p>

<p align="center">
  <a href="https://pub.dev/packages/pushengage_flutter_sdk"><img src="https://img.shields.io/pub/v/pushengage_flutter_sdk.svg?style=flat-square" alt="pub.dev"/></a>
  <a href="#"><img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue.svg?style=flat-square" alt="Platform"/></a>
  <a href="#"><img src="https://img.shields.io/badge/Flutter-%3E%3D%203.3.0-02569B.svg?style=flat-square" alt="Flutter"/></a>
  <a href="#"><img src="https://img.shields.io/badge/Dart-%3E%3D%203.4.3-0175C2.svg?style=flat-square" alt="Dart"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat-square" alt="License"/></a>
</p>

---

## Why PushEngage?

PushEngage is a complete push notification platform that supports **web and mobile** from a single dashboard. Unlike wiring up Firebase Cloud Messaging and APNs yourself, PushEngage gives you a full marketing toolkit on top of reliable cross-platform delivery: audience segmentation, automated drip campaigns, A/B testing, analytics, and a no-code campaign builder.

**Key features of the Flutter SDK:**

- **Cross-Platform** -- single API for both Android and iOS
- **Rich Notifications** -- images, action buttons, custom sounds
- **Deep Linking** -- native `Stream`-based deep link handling
- **Audience Segmentation** -- static and dynamic segments based on user behavior
- **Triggered Campaigns** -- send notifications based on in-app events
- **Goal Tracking** -- measure conversions tied to notifications
- **Price Drop & Inventory Alerts** -- e-commerce trigger notifications
- **Subscriber Attributes** -- store custom key-value data per subscriber
- **Type-Safe Results** -- all async methods return `PushEngageResult<T>` with built-in error handling

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  pushengage_flutter_sdk: ^1.0.0
```

Then run:

```bash
flutter pub get
```

> **Prerequisites:** Firebase project (Android) + Apple Developer account (iOS). See the [Getting Started Guide](https://www.pushengage.com/documentation/setting-up-app-push-notification-in-flutter-using-pushengage/) for platform-specific setup.

---

## Quick Start

### 1. Initialize the SDK

```dart
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  PushEngage.setAppId('YOUR_APP_ID');

  runApp(MyApp());
}
```

### 2. Request Permission & Subscribe

```dart
final permResult = await PushEngage.requestNotificationPermission();
if (permResult.data == true) {
  final subResult = await PushEngage.subscribe();
  print('Subscribed: ${subResult.data}');
}
```

### 3. Handle Deep Links

```dart
PushEngage.deepLinkStream.listen((data) {
  if (data != null) {
    // Navigate to the appropriate screen based on data
    print('Deep link received: $data');
  }
});
```

### 4. Send a Goal Event

```dart
final goal = Goal(name: 'purchase_complete', count: 1, value: 49.99);
await PushEngage.sendGoal(goal);
```

---

## API Overview

| Category | Methods |
|----------|---------|
| **Setup** | `setAppId`, `getSdkVersion`, `setSmallIconResource` (Android), `setBadgeCount`, `runConfigValidation` (Android), `enableLogging` |
| **Permissions** | `requestNotificationPermission`, `getNotificationPermissionStatus` |
| **Subscription** | `subscribe`, `unsubscribe`, `getSubscriptionStatus`, `getSubscriptionNotificationStatus` |
| **Subscriber Data** | `getSubscriberId`, `getSubscriberDetails`, `getDeviceTokenHash` (Android), `addProfileId`, `identify`, `logout` |
| **Attributes** | `addSubscriberAttributes`, `setSubscriberAttributes`, `getSubscriberAttributes`, `deleteSubscriberAttributes` |
| **Segments** | `addSegment`, `removeSegment`, `addDynamicSegment` |
| **Events** | `sendTriggerEvent`, `sendGoal`, `addAlert`, `trackEvent` |
| **Notifications** | `getInitialNotification` (iOS) |
| **Campaigns** | `automatedNotification` (enable/disable) |
| **Streams** | `deepLinkStream` (deep link data), `onFcmConfigError` (Android FCM config errors) |

All async methods return `PushEngageResult<T>` which wraps the response data and any errors for safe handling.

Full API reference: [Flutter SDK Public APIs](https://pushengage.com/api/mobile-sdk/flutter-sdk)

---

## Example Project

The **`example/`** directory contains a complete Flutter app demonstrating:

- Push notification setup and permission handling
- Home screen with subscriber management
- Alert entries (price drop / inventory)
- Trigger campaigns
- Goal tracking

To run the example:

```bash
cd example
flutter pub get
flutter run
```

---

## Documentation

- [Getting Started Guide](https://www.pushengage.com/documentation/setting-up-app-push-notification-in-flutter-using-pushengage/) -- step-by-step setup for Android and iOS
- [Flutter SDK API Reference](https://pushengage.com/api/mobile-sdk/flutter-sdk) -- complete API docs
- [PushEngage Dashboard](https://app.pushengage.com) -- manage campaigns and analytics

---

## Requirements

| Requirement | Minimum |
|-------------|---------|
| Flutter | 3.3.0+ |
| Dart | 3.4.3+ |
| iOS | 12.0+ |
| Android | 5.0+ (API 21) |
| Firebase | Required (Android) |
| APNs | Required (iOS) |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Support

Having trouble? We're here to help.

- **Issues & Bugs** -- [Open a GitHub issue](https://github.com/awesomemotive/pushengage-flutter-sdk/issues)
- **General Support** -- Contact us from your [PushEngage dashboard](https://app.pushengage.com) or email [care@pushengage.com](mailto:care@pushengage.com)

---

## License

MIT -- see [LICENSE](LICENSE) for details.
