import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk_example/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Stub every native call (getInitialNotification -> null, setters -> null).
    messenger.setMockMethodCallHandler(channel, (call) async => null);
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('boots through AppBootstrap to the PushEngage home screen',
      (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    // The home app bar title + first section header are shown once bootstrap
    // completes (later sections are below the fold in the lazy ListView).
    expect(find.text('PushEngage'), findsWidgets);
    expect(find.text('SUBSCRIPTION'), findsOneWidget);
  });
}
