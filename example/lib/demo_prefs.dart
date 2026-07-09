import 'package:pushengage_flutter_sdk/model/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the demo's app id + environment (mirrors the native
/// and RN demos' DemoPrefs). Backed by [SharedPreferences].
class DemoPrefs {
  DemoPrefs._();

  static const String _appIdKey = '@pushengage_demo/appId';
  static const String _environmentKey = '@pushengage_demo/environment';

  /// Placeholder shown until the user pastes a real PushEngage app id.
  static const String defaultAppId = 'YOUR_APP_ID';

  /// Returns the stored app id, or [defaultAppId] when unset/empty.
  static Future<String> getAppId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_appIdKey);
    return (value != null && value.isNotEmpty) ? value : defaultAppId;
  }

  /// Trims and stores the app id; a blank value removes it.
  static Future<void> setAppId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_appIdKey);
    } else {
      await prefs.setString(_appIdKey, trimmed);
    }
  }

  /// Returns [Environment.staging] only when exactly `STAGING` was stored,
  /// otherwise [Environment.production] (the default).
  static Future<Environment> getEnvironment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_environmentKey) == Environment.staging.wireValue
        ? Environment.staging
        : Environment.production;
  }

  /// Persists the environment as its wire value.
  static Future<void> setEnvironment(Environment environment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_environmentKey, environment.wireValue);
  }

  /// True when [appId] is a real, non-placeholder value.
  static bool isConfigured(String appId) =>
      appId.isNotEmpty && appId != defaultAppId;
}
