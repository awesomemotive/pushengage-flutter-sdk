import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('getInitialNotification forwards the call and propagates the payload',
      () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'PushEngage#getInitialNotification') {
        return {
          'deepLink': 'app://x',
          'data': {'k': 'v'}
        };
      }
      return null;
    });

    final res = await PushEngage.getInitialNotification();
    expect(res.isSuccess, true);
    expect(res.data, {
      'deepLink': 'app://x',
      'data': {'k': 'v'}
    });
    expect(calls.single.method, 'PushEngage#getInitialNotification');
  });

  test('getInitialNotification returns null when native returns null',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    final res = await PushEngage.getInitialNotification();
    expect(res.isSuccess, true);
    expect(res.data, isNull);
  });
}
