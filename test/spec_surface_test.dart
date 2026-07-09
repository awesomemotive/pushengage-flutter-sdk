import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('public API exposes the expected methods (tear-offs)', () {
    // Referencing each tear-off fails to compile if a method is removed or
    // renamed — a guard against accidental public-surface drift.
    final members = <Object?>[
      PushEngage.setAppId,
      PushEngage.getSdkVersion,
      PushEngage.setEnvironment,
      PushEngage.setSmallIconResource,
      PushEngage.getDeviceTokenHash,
      PushEngage.enableLogging,
      PushEngage.setBadgeCount,
      PushEngage.automatedNotification,
      PushEngage.sendTriggerEvent,
      PushEngage.sendGoal,
      PushEngage.addAlert,
      PushEngage.getSubscriberDetails,
      PushEngage.requestNotificationPermission,
      PushEngage.getInitialNotification,
      PushEngage.getNotificationPermissionStatus,
      PushEngage.getSubscriptionStatus,
      PushEngage.getSubscriptionNotificationStatus,
      PushEngage.getSubscriberId,
      PushEngage.unsubscribe,
      PushEngage.subscribe,
      PushEngage.getSubscriberAttributes,
      PushEngage.addSegment,
      PushEngage.removeSegment,
      PushEngage.addDynamicSegment,
      PushEngage.addSubscriberAttributes,
      PushEngage.deleteSubscriberAttributes,
      PushEngage.addProfileId,
      PushEngage.setSubscriberAttributes,
      PushEngage.identify,
      PushEngage.logout,
      PushEngage.trackEvent,
      PushEngage.runConfigValidation,
    ];
    for (final m in members) {
      expect(m, isA<Function>());
    }
  });

  test('exposes the deepLink and FCM config-error streams', () {
    messenger.setMockMethodCallHandler(channel, (c) async => null);
    expect(PushEngage.deepLinkStream, isA<Stream<Map<String, dynamic>?>>());
    expect(PushEngage.onFcmConfigError, isA<Stream<FcmConfigError>>());
  });
}
