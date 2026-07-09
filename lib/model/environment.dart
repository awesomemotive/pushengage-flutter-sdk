/// The SDK backend environment.
///
/// Call [PushEngage.setEnvironment] BEFORE [PushEngage.setAppId] — the native
/// Android SDK caches its base URLs when the app id is set.
enum Environment {
  staging,
  production;

  /// The wire value sent to the native SDK.
  String get wireValue =>
      this == Environment.staging ? 'STAGING' : 'PRODUCTION';
}
