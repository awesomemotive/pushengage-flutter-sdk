import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

/// The In-App Messaging bridge surface: trigger forwarding and the
/// custom-action stream.
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

  group('triggerIAMEvent', () {
    test('forwards eventName and parameters', () async {
      responder = (_) => 'In-app message event triggered successfully';
      final res = await PushEngage.triggerIAMEvent(
          'onboarding_complete', {'step': 'complete', 'count': 2});
      expect(calls.single.method, 'PushEngage#triggerIAMEvent');
      expect(calls.single.arguments, {
        'eventName': 'onboarding_complete',
        'parameters': {'step': 'complete', 'count': 2},
      });
      expect(res.isSuccess, true);
      expect(res.data, 'In-app message event triggered successfully');
    });

    test('omitted parameters are sent as null', () async {
      responder = (_) => 'ok';
      await PushEngage.triggerIAMEvent('checkout');
      expect(calls.single.arguments,
          {'eventName': 'checkout', 'parameters': null});
    });

    test('maps a PlatformException to a failure result', () async {
      responder = (_) => throw PlatformException(
          code: '400', message: 'Event name is required');
      final res = await PushEngage.triggerIAMEvent('');
      expect(res.isSuccess, false);
      expect(res.error, isA<PlatformException>());
    });
  });

  group('onIAMCustomAction', () {
    test('stream emits typed events from native', () async {
      final events = <IAMCustomAction>[];
      final sub = PushEngage.onIAMCustomAction.listen(events.add);

      await messenger.handlePlatformMessage(
        'PushEngage',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onIAMCustomAction', {
            'actionId': 'promo_tapped',
            'parameters': {'sku': '42', 'source': 'banner'},
          }),
        ),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);

      expect(events.single.actionId, 'promo_tapped');
      expect(events.single.parameters, {'sku': '42', 'source': 'banner'});
      await sub.cancel();
    });
  });
}
