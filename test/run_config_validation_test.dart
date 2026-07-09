import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('runConfigValidation forwards ids and returns the native bool',
      () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (c) async {
      calls.add(c);
      return true;
    });

    final res = await PushEngage.runConfigValidation('sender-1', 'project-1');

    expect(res.isSuccess, true);
    expect(res.data, true);
    expect(calls.single.method, 'PushEngage#runConfigValidation');
    expect(calls.single.arguments,
        {'senderId': 'sender-1', 'projectId': 'project-1'});
  });

  test('runConfigValidation propagates false', () async {
    messenger.setMockMethodCallHandler(channel, (c) async => false);
    final res = await PushEngage.runConfigValidation('s', 'p');
    expect(res.data, false);
  });
}
