
import 'frc_platform_interface.dart';

class Frc {
  Future<String?> getPlatformVersion() {
    return FrcPlatform.instance.getPlatformVersion();
  }
}
