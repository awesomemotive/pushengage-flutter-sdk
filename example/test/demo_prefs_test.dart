import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/model/environment.dart';
import 'package:pushengage_flutter_sdk_example/demo_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('getAppId returns the default when unset', () async {
    expect(await DemoPrefs.getAppId(), DemoPrefs.defaultAppId);
  });

  test('setAppId trims and stores; getAppId returns it', () async {
    await DemoPrefs.setAppId('  APP123  ');
    expect(await DemoPrefs.getAppId(), 'APP123');
  });

  test('setAppId with blank removes the key (default returned)', () async {
    await DemoPrefs.setAppId('APP123');
    await DemoPrefs.setAppId('   ');
    expect(await DemoPrefs.getAppId(), DemoPrefs.defaultAppId);
  });

  test('getEnvironment defaults to production', () async {
    expect(await DemoPrefs.getEnvironment(), Environment.production);
  });

  test('getEnvironment returns staging only when stored STAGING', () async {
    await DemoPrefs.setEnvironment(Environment.staging);
    expect(await DemoPrefs.getEnvironment(), Environment.staging);
    await DemoPrefs.setEnvironment(Environment.production);
    expect(await DemoPrefs.getEnvironment(), Environment.production);
  });

  test('isConfigured is false for empty or the default placeholder', () {
    expect(DemoPrefs.isConfigured(''), false);
    expect(DemoPrefs.isConfigured(DemoPrefs.defaultAppId), false);
    expect(DemoPrefs.isConfigured('APP123'), true);
  });
}
