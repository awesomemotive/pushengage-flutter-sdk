import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pushengage_flutter_sdk_method_channel.dart';

abstract class PushengageFlutterSdkPlatform extends PlatformInterface {
  /// Constructs a PushengageFlutterSdkPlatform.
  PushengageFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static PushengageFlutterSdkPlatform _instance =
      MethodChannelPushengageFlutterSdk();

  /// The default instance of [PushengageFlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelPushengageFlutterSdk].
  static PushengageFlutterSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PushengageFlutterSdkPlatform] when
  /// they register themselves.
  static set instance(PushengageFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
