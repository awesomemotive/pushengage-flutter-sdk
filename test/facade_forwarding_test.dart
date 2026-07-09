import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

/// Characterization tests for the pre-existing facade methods: each one
/// forwards to the correct method-channel name with the expected arguments,
/// and maps the native result into a [PushEngageResult].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  dynamic Function(MethodCall call)? responder;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return responder?.call(call);
    });
  });

  tearDown(() {
    responder = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('channel routing', () {
    test('facade calls route through the "PushEngage" channel', () async {
      final wrong = <MethodCall>[];
      const wrongChannel = MethodChannel('NotPushEngage');
      messenger.setMockMethodCallHandler(wrongChannel, (c) async {
        wrong.add(c);
        return null;
      });

      responder = (_) => null;
      await PushEngage.setAppId('x');

      expect(calls.single.method, 'PushEngage#setAppId');
      expect(wrong, isEmpty);
      messenger.setMockMethodCallHandler(wrongChannel, null);
    });
  });

  group('setAppId / enableLogging', () {
    test('setAppId forwards the appId and the wrapper sdkVersion', () async {
      responder = (_) => null;
      await PushEngage.setAppId('APP123');
      expect(calls.single.method, 'PushEngage#setAppId');
      expect(calls.single.arguments,
          {'appId': 'APP123', 'sdkVersion': PushEngage.getSdkVersion()});
    });

    test('enableLogging forwards the status flag', () async {
      responder = (_) => null;
      PushEngage.enableLogging(true);
      await Future<void>.delayed(Duration.zero);
      expect(calls.single.method, 'PushEngage#enableLogging');
      expect(calls.single.arguments, {'status': true});
    });
  });

  group('automated notification / triggers / goals / alerts', () {
    test('automatedNotification(enabled) forwards status:true + success',
        () async {
      responder = (_) => 'Automated notification enabled successfully';
      final res =
          await PushEngage.automatedNotification(TriggerStatusType.enabled);
      expect(calls.single.method, 'PushEngage#automatedNotification');
      expect(calls.single.arguments, {'status': true});
      expect(res.isSuccess, true);
      expect(res.data, 'Automated notification enabled successfully');
    });

    test('automatedNotification(disabled) forwards status:false', () async {
      responder = (_) => 'ok';
      await PushEngage.automatedNotification(TriggerStatusType.disabled);
      expect(calls.single.arguments, {'status': false});
    });

    test('sendTriggerEvent forwards trigger.toMap', () async {
      responder = (_) => 'Trigger sent successfully';
      final res = await PushEngage.sendTriggerEvent(TriggerCampaign(
        campaignName: 'c',
        eventName: 'e',
        referenceId: 'r',
        profileId: 'p',
        data: {'k': 'v'},
      ));
      expect(calls.single.method, 'PushEngage#sendTriggerEvent');
      expect(calls.single.arguments, {
        'campaignName': 'c',
        'eventName': 'e',
        'referenceId': 'r',
        'profileId': 'p',
        'data': {'k': 'v'},
      });
      expect(res.isSuccess, true);
    });

    test('sendGoal forwards goal.toMap + success', () async {
      responder = (_) => 'Goal sent successfully';
      final res =
          await PushEngage.sendGoal(Goal(name: 'g', count: 2, value: 1.5));
      expect(calls.single.method, 'PushEngage#sendGoal');
      expect(calls.single.arguments, {'name': 'g', 'count': 2, 'value': 1.5});
      expect(res.data, 'Goal sent successfully');
    });

    test('sendGoal maps a PlatformException to failure', () async {
      responder =
          (_) => throw PlatformException(code: 'FAILURE', message: 'boom');
      final res = await PushEngage.sendGoal(Goal(name: 'g'));
      expect(res.isSuccess, false);
    });

    test('addAlert forwards alert.toMap', () async {
      responder = (_) => 'Alert added successfully';
      final res = await PushEngage.addAlert(TriggerAlert(
        type: TriggerAlertType.priceDrop,
        productId: 'p1',
        link: 'https://x',
        price: 9.99,
      ));
      expect(calls.single.method, 'PushEngage#addAlert');
      final args = calls.single.arguments as Map;
      expect(args['type'], 'priceDrop');
      expect(args['productId'], 'p1');
      expect(args['link'], 'https://x');
      expect(args['price'], 9.99);
      expect(res.isSuccess, true);
    });
  });

  group('subscription status getters', () {
    test('subscribe returns the native bool', () async {
      responder = (_) => true;
      final res = await PushEngage.subscribe();
      expect(calls.single.method, 'PushEngage#subscribe');
      expect(res.data, true);
    });

    test('unsubscribe returns the native bool', () async {
      responder = (_) => false;
      final res = await PushEngage.unsubscribe();
      expect(calls.single.method, 'PushEngage#unsubscribe');
      expect(res.data, false);
    });

    test('getSubscriptionStatus returns the native bool', () async {
      responder = (_) => true;
      final res = await PushEngage.getSubscriptionStatus();
      expect(calls.single.method, 'PushEngage#getSubscriptionStatus');
      expect(res.data, true);
    });

    test('getSubscriptionNotificationStatus returns the native bool', () async {
      responder = (_) => true;
      final res = await PushEngage.getSubscriptionNotificationStatus();
      expect(
          calls.single.method, 'PushEngage#getSubscriptionNotificationStatus');
      expect(res.data, true);
    });

    test('getSubscriptionStatus defaults to false on null', () async {
      responder = (_) => null;
      final res = await PushEngage.getSubscriptionStatus();
      expect(res.data, false);
    });

    test('getSubscriberId returns the id', () async {
      responder = (_) => 'sub-123';
      final res = await PushEngage.getSubscriberId();
      expect(calls.single.method, 'PushEngage#getSubscriberId');
      expect(res.data, 'sub-123');
    });
  });

  group('permission status', () {
    test('getNotificationPermissionStatus returns the status', () async {
      responder = (_) => 'granted';
      final res = await PushEngage.getNotificationPermissionStatus();
      expect(calls.single.method, 'PushEngage#getNotificationPermissionStatus');
      expect(res.data, 'granted');
    });

    test('getNotificationPermissionStatus defaults to denied on null',
        () async {
      responder = (_) => null;
      final res = await PushEngage.getNotificationPermissionStatus();
      expect(res.data, 'denied');
    });

    test('requestNotificationPermission propagates the native grant bool',
        () async {
      responder = (_) => true;
      final granted = await PushEngage.requestNotificationPermission();
      expect(calls.single.method, 'PushEngage#requestNotificationPermission');
      expect(granted.isSuccess, true);
      expect(granted.data, true);

      calls.clear();
      responder = (_) => false;
      final denied = await PushEngage.requestNotificationPermission();
      expect(calls.single.method, 'PushEngage#requestNotificationPermission');
      expect(denied.isSuccess, true);
      expect(denied.data, false);
    });
  });

  group('subscriber details & attributes', () {
    test('getSubscriberDetails forwards values and decodes the JSON response',
        () async {
      responder = (_) => '{"city":"NY","country":"US"}';
      final res = await PushEngage.getSubscriberDetails(['city', 'country']);
      expect(calls.single.method, 'PushEngage#getSubscriberDetails');
      expect(calls.single.arguments, {
        'values': ['city', 'country']
      });
      expect(res.isSuccess, true);
      expect(res.data, {'city': 'NY', 'country': 'US'});
    });

    test('getSubscriberDetails treats a not-subscribed reply as failure',
        () async {
      // Not subscribed surfaces as a native error on both platforms (matching
      // the native SDKs and the React Native wrapper). There is no
      // success(null) contract — an absent/non-string details reply is a
      // failure, not an empty success.
      responder = (_) => null;
      final res = await PushEngage.getSubscriberDetails(['city']);
      expect(res.isSuccess, false);
    });

    test('getSubscriberDetails forwards a null values list ("all fields")',
        () async {
      // null means "all fields". The native side resolves it per platform:
      // iOS passes nil to the SDK (omits the fields param → full record);
      // Android sends an empty list (its SDK NPEs on a null list). The facade
      // must forward the null unchanged so the native layer can make that
      // choice.
      responder = (_) => '{"city":"NY"}';
      await PushEngage.getSubscriberDetails(null);
      expect(calls.single.method, 'PushEngage#getSubscriberDetails');
      expect(calls.single.arguments, {'values': null});
    });

    test('getSubscriberAttributes returns the attribute map', () async {
      responder = (_) => {'age': 25, 'city': 'NY'};
      final res = await PushEngage.getSubscriberAttributes();
      expect(calls.single.method, 'PushEngage#getSubscriberAttributes');
      expect(res.isSuccess, true);
      expect(res.data, {'age': 25, 'city': 'NY'});
    });

    test('getSubscriberAttributes fails on a non-map response', () async {
      responder = (_) => 'not-a-map';
      final res = await PushEngage.getSubscriberAttributes();
      expect(res.isSuccess, false);
    });

    test('addSubscriberAttributes json-encodes the attributes', () async {
      responder = (_) => 'ok';
      final res =
          await PushEngage.addSubscriberAttributes({'age': 25, 'city': 'NY'});
      expect(calls.single.method, 'PushEngage#addSubscriberAttributes');
      final encoded = (calls.single.arguments as Map)['attributes'] as String;
      expect(jsonDecode(encoded), {'age': 25, 'city': 'NY'});
      expect(res.isSuccess, true);
    });

    test('setSubscriberAttributes json-encodes the attributes', () async {
      responder = (_) => 'ok';
      final res = await PushEngage.setSubscriberAttributes({'age': 30});
      expect(calls.single.method, 'PushEngage#setSubscriberAttributes');
      final encoded = (calls.single.arguments as Map)['attributes'] as String;
      expect(jsonDecode(encoded), {'age': 30});
      expect(res.isSuccess, true);
    });

    test('deleteSubscriberAttributes forwards the list', () async {
      responder = (_) => 'ok';
      final res = await PushEngage.deleteSubscriberAttributes(['age', 'city']);
      expect(calls.single.method, 'PushEngage#deleteSubscriberAttributes');
      expect(calls.single.arguments, {
        'attributes': ['age', 'city']
      });
      expect(res.isSuccess, true);
    });

    test('addProfileId forwards the profileId', () async {
      responder = (_) => 'Profile Id added successfully';
      final res = await PushEngage.addProfileId('user_42');
      expect(calls.single.method, 'PushEngage#addProfileId');
      expect(calls.single.arguments, {'profileId': 'user_42'});
      expect(res.isSuccess, true);
    });
  });

  group('segments', () {
    test('addSegment forwards the list', () async {
      responder = (_) => 'ok';
      final res = await PushEngage.addSegment(['sports', 'news']);
      expect(calls.single.method, 'PushEngage#addSegment');
      expect(calls.single.arguments, {
        'segments': ['sports', 'news']
      });
      expect(res.isSuccess, true);
    });

    test('removeSegment forwards the list', () async {
      responder = (_) => 'ok';
      final res = await PushEngage.removeSegment(['sports']);
      expect(calls.single.method, 'PushEngage#removeSegment');
      expect(calls.single.arguments, {
        'segments': ['sports']
      });
      expect(res.isSuccess, true);
    });

    test('addDynamicSegment serializes the segments', () async {
      responder = (_) => 'ok';
      final res = await PushEngage.addDynamicSegment([
        DynamicSegment(name: 'sports', duration: 5),
        DynamicSegment(name: 'news', duration: 10),
      ]);
      expect(calls.single.method, 'PushEngage#addDynamicSegment');
      expect(calls.single.arguments, {
        'segments': [
          {'name': 'sports', 'duration': 5},
          {'name': 'news', 'duration': 10},
        ]
      });
      expect(res.isSuccess, true);
    });
  });

  group('Android-only platform guards (non-Android host)', () {
    test('getDeviceTokenHash fails on non-Android without a channel call',
        () async {
      final res = await PushEngage.getDeviceTokenHash();
      expect(res.isSuccess, false);
      expect(res.error, 'Platform is not Android');
      expect(calls, isEmpty);
    });

    test('setSmallIconResource is a no-op on non-Android', () async {
      await PushEngage.setSmallIconResource('ic_notify');
      expect(calls, isEmpty);
    });
  });
}
