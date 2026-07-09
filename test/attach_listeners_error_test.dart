import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

/// Runs in its own file so the facade's static listener latch is fresh.
///
/// In a real app without a native implementation (or before plugin
/// registration), the outgoing `attachListeners` call completes with
/// MissingPluginException. The facade must swallow that internally — an
/// unhandled async error here fails the test — and release the latch so a
/// later stream access retries the attach.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('a failed attachListeners is swallowed and retried on next access',
      () async {
    var attempts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      attempts++;
      throw MissingPluginException();
    });

    // First access: the attach failure must not surface as an unhandled
    // async error.
    PushEngage.deepLinkStream;
    await Future<void>.delayed(Duration.zero);
    expect(attempts, 1);

    // The latch must be released on failure so the next access retries.
    PushEngage.onFcmConfigError;
    await Future<void>.delayed(Duration.zero);
    expect(attempts, 2);
  });
}
