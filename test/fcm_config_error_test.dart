import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('onFcmConfigError stream emits typed events from native', () async {
    // Swallow the outgoing attachListeners call triggered on first listen.
    messenger.setMockMethodCallHandler(channel, (c) async => null);

    final events = <FcmConfigError>[];
    final sub = PushEngage.onFcmConfigError.listen(events.add);

    await messenger.handlePlatformMessage(
      'PushEngage',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall(
            'onFcmConfigError', {'code': 5001, 'message': 'sender mismatch'}),
      ),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);

    expect(events.single.code, 5001);
    expect(events.single.message, 'sender mismatch');
    await sub.cancel();
  });
}
