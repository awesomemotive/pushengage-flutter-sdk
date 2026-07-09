import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('deepLinkStream emits when native calls onDeepLink', () async {
    // Swallow the outgoing attachListeners call triggered on first listen.
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    final events = <Map<String, dynamic>?>[];
    final sub = PushEngage.deepLinkStream.listen(events.add);

    await messenger.handlePlatformMessage(
      'PushEngage',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onDeepLink', {
          'deepLink': 'app://x',
          'data': {'k': 'v'}
        }),
      ),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);

    expect(events.single, {
      'deepLink': 'app://x',
      'data': {'k': 'v'}
    });
    await sub.cancel();
  });

  test('deepLinkStream decodes a JSON-string data field (Android wire shape)',
      () async {
    // The Android SDK stores the notification's additional data in the
    // deep-link intent as a Gson JSON string; iOS sends a map. Dart must
    // normalize both to a Map so consumers see one shape.
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    final events = <Map<String, dynamic>?>[];
    final sub = PushEngage.deepLinkStream.listen(events.add);

    await messenger.handlePlatformMessage(
      'PushEngage',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onDeepLink', {
          'deepLink': 'app://x',
          'data': '{"k":"v"}',
        }),
      ),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);

    expect(events.single, {
      'deepLink': 'app://x',
      'data': {'k': 'v'}
    });
    await sub.cancel();
  });

  test('deepLinkStream leaves a non-JSON string data field untouched',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    final events = <Map<String, dynamic>?>[];
    final sub = PushEngage.deepLinkStream.listen(events.add);

    await messenger.handlePlatformMessage(
      'PushEngage',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onDeepLink', {
          'deepLink': 'app://x',
          'data': 'not json',
        }),
      ),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);

    expect(events.single, {'deepLink': 'app://x', 'data': 'not json'});
    await sub.cancel();
  });
}
