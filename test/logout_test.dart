import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<MethodCall> capture(Future<void> Function() act) async {
    late MethodCall mc;
    messenger.setMockMethodCallHandler(channel, (c) async {
      mc = c;
      return 'Logout successful';
    });
    await act();
    return mc;
  }

  test('logout forwards null (default PII set)', () async {
    final mc = await capture(() => PushEngage.logout(null));
    expect(mc.method, 'PushEngage#logout');
    expect(mc.arguments, {'fieldNames': null});
  });

  test('logout forwards a field list', () async {
    final mc = await capture(() => PushEngage.logout(['email', 'profile_id']));
    expect(mc.arguments, {
      'fieldNames': ['email', 'profile_id']
    });
  });
}
