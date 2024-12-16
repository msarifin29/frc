import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'frc_method_channel.dart';

abstract class FrcPlatform extends PlatformInterface {
  /// Constructs a FrcPlatform.
  FrcPlatform() : super(token: _token);

  static final Object _token = Object();

  static FrcPlatform _instance = MethodChannelFrc();

  /// The default instance of [FrcPlatform] to use.
  ///
  /// Defaults to [MethodChannelFrc].
  static FrcPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FrcPlatform] when
  /// they register themselves.
  static set instance(FrcPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
