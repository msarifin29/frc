import 'package:flutter_test/flutter_test.dart';
import 'package:frc/frc.dart';
import 'package:frc/frc_platform_interface.dart';
import 'package:frc/frc_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFrcPlatform
    with MockPlatformInterfaceMixin
    implements FrcPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FrcPlatform initialPlatform = FrcPlatform.instance;

  test('$MethodChannelFrc is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFrc>());
  });

  test('getPlatformVersion', () async {
    Frc frcPlugin = Frc();
    MockFrcPlatform fakePlatform = MockFrcPlatform();
    FrcPlatform.instance = fakePlatform;

    expect(await frcPlugin.getPlatformVersion(), '42');
  });
}
