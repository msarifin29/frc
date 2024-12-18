import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:frc/frc.dart';

class EnumHandler {
  static ResolutionPreset imageResolutionToResolutionPreset(ImageResolution res) {
    switch (res) {
      case ImageResolution.low:
        return ResolutionPreset.low;
      case ImageResolution.medium:
        return ResolutionPreset.medium;
      case ImageResolution.high:
        return ResolutionPreset.high;
      case ImageResolution.veryHigh:
        return ResolutionPreset.veryHigh;
      case ImageResolution.ultraHigh:
        return ResolutionPreset.ultraHigh;
      case ImageResolution.max:
        return ResolutionPreset.max;
    }
  }

  static CameraLensDirection? cameraLensToCameraLensDirection(CameraLens? lens) {
    switch (lens) {
      case CameraLens.front:
        return CameraLensDirection.front;
      case CameraLens.back:
        return CameraLensDirection.back;
      case CameraLens.external:
        return CameraLensDirection.external;
      default:
        return null;
    }
  }

  static CameraLens? cameraLensDirectionToCameraLens(CameraLensDirection? lens) {
    switch (lens) {
      case CameraLensDirection.front:
        return CameraLens.front;
      case CameraLensDirection.back:
        return CameraLens.back;
      case CameraLensDirection.external:
        return CameraLens.external;
      default:
        return null;
    }
  }

  static DeviceOrientation? cameraOrientationToDeviceOrientation(CameraOrientation? orientation) {
    switch (orientation) {
      case CameraOrientation.portraitUp:
        return DeviceOrientation.portraitUp;
      case CameraOrientation.landscapeLeft:
        return DeviceOrientation.landscapeLeft;
      case CameraOrientation.portraitDown:
        return DeviceOrientation.portraitDown;
      case CameraOrientation.landscapeRight:
        return DeviceOrientation.landscapeRight;
      default:
        return null;
    }
  }
}
