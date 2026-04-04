
import 'sharara_blu_platform_interface.dart';

class ShararaBlu {
  Future<String?> getPlatformVersion() {
    return ShararaBluPlatform.instance.getPlatformVersion();
  }
}
