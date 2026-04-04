import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sharara_blu_method_channel.dart';

abstract class ShararaBluPlatform extends PlatformInterface {
  /// Constructs a ShararaBluPlatform.
  ShararaBluPlatform() : super(token: _token);

  static final Object _token = Object();

  static ShararaBluPlatform _instance = MethodChannelShararaBlu();

  /// The default instance of [ShararaBluPlatform] to use.
  ///
  /// Defaults to [MethodChannelShararaBlu].
  static ShararaBluPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ShararaBluPlatform] when
  /// they register themselves.
  static set instance(ShararaBluPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
