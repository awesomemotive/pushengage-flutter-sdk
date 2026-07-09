import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('setEnvironment(staging) forwards STAGING', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (c) async {
      calls.add(c);
      return null;
    });
    await PushEngage.setEnvironment(Environment.staging);
    expect(calls.single.method, 'PushEngage#setEnvironment');
    expect(calls.single.arguments, {'environment': 'STAGING'});
  });

  test('setEnvironment(production) forwards PRODUCTION', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (c) async {
      calls.add(c);
      return null;
    });
    await PushEngage.setEnvironment(Environment.production);
    expect(calls.single.arguments, {'environment': 'PRODUCTION'});
  });
}
