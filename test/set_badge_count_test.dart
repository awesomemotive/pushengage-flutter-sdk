import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<Object?> capture(Future<void> Function() act) async {
    Object? args;
    messenger.setMockMethodCallHandler(channel, (c) async {
      args = c.arguments;
      return null;
    });
    await act();
    return args;
  }

  test('forwards in-range values', () async {
    expect(await capture(() => PushEngage.setBadgeCount(5)), {'count': 5});
  });

  test('forwards zero', () async {
    expect(await capture(() => PushEngage.setBadgeCount(0)), {'count': 0});
  });

  test('preserves negatives', () async {
    expect(await capture(() => PushEngage.setBadgeCount(-2)), {'count': -2});
  });

  test('maps out-of-32-bit-range values to 0', () async {
    expect(await capture(() => PushEngage.setBadgeCount(2147483648)),
        {'count': 0});
  });
}
