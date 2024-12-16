import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'frc_platform_interface.dart';

/// An implementation of [FrcPlatform] that uses method channels.
class MethodChannelFrc extends FrcPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('frc');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
