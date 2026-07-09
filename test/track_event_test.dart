import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('toMap with only eventName strips null optionals', () {
    expect(TrackEventPayload(eventName: 'view').toMap(), {'eventName': 'view'});
  });

  test('toMap throws on empty eventName', () {
    expect(() => TrackEventPayload(eventName: '').toMap(), throwsArgumentError);
  });

  test('toMap includes all set fields', () {
    final m = TrackEventPayload(
      eventName: 'AddToCart',
      data: {'id': '1', 'qty': 2},
      profileId: 'u1',
      provider: 'PushEngage',
      eventType: 'PushEngage.CustomEvent',
    ).toMap();
    expect(m, {
      'eventName': 'AddToCart',
      'data': {'id': '1', 'qty': 2},
      'profileId': 'u1',
      'provider': 'PushEngage',
      'eventType': 'PushEngage.CustomEvent',
    });
  });

  test('trackEvent forwards the payload and returns success', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (c) async {
      calls.add(c);
      return 'Track event successful';
    });

    final res =
        await PushEngage.trackEvent(TrackEventPayload(eventName: 'view'));

    expect(res.isSuccess, true);
    expect(calls.single.method, 'PushEngage#trackEvent');
    expect(calls.single.arguments, {'eventName': 'view'});
  });
}
