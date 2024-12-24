import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

export 'handlers/recognizer_handler.dart';
export 'controllers/camera_state.dart';
export 'controllers/frc_camera_controller.dart';
export 'face_camera.dart';
export 'face_camera_circle.dart';
export 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class Frc {
  static List<CameraDescription> _cameras = [];

  /// Initialize device cameras
  static Future<void> initialize() async {
    /// Fetch the available cameras before initializing the app.
    try {
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      logError(e.code, e.description);
    }
  }

  /// Returns available cameras
  static List<CameraDescription> get cameras {
    return _cameras;
  }
}

void logError(String message, [String? code]) {
  if (code != null) {
    debugPrint('Error: $code\nError Message: $message');
  } else {
    debugPrint('Error: $code');
  }
}
