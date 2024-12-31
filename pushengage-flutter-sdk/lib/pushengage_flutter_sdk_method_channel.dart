import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pushengage_flutter_sdk_platform_interface.dart';

/// An implementation of [PushengageFlutterSdkPlatform] that uses method channels.
class MethodChannelPushengageFlutterSdk extends PushengageFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pushengage_flutter_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
