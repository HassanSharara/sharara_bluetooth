import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sharara_blu_platform_interface.dart';

/// An implementation of [ShararaBluPlatform] that uses method channels.
class MethodChannelShararaBlu extends ShararaBluPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sharara_blu');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
