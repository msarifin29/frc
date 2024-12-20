import 'package:camera/camera.dart';
import 'package:frc/models/detected_image.dart';
import 'package:frc/res/enums.dart';

/// This class represents the current state of a [FaceCameraController].
class CameraState {
  /// Create a new [CameraState] instance.
  const CameraState({
    required this.currentCameraLens,
    required this.isInitialized,
    required this.availableCameraLens,
    required this.alreadyCheckingImage,
    this.cameraController,
    this.detectedFace,
  });

  /// Create a new [CameraState] instance that is uninitialized.
  CameraState.uninitialized()
      : this(
          availableCameraLens: [],
          currentCameraLens: 0,
          isInitialized: false,
          alreadyCheckingImage: false,
          cameraController: null,
          detectedFace: null,
        );

  /// Camera dependency controller
  final CameraController? cameraController;

  /// The available cameras.
  ///
  /// This is null if no camera is found.
  final List<CameraLens> availableCameraLens;

  /// The current camera lens in use.
  ///
  /// Default value is 1.
  final int currentCameraLens;

  /// Whether the face camera has initialized successfully.
  ///
  /// This is `true` if the camera is ready to be used.
  final bool isInitialized;

  final bool alreadyCheckingImage;

  final DetectedFace? detectedFace;

  /// Create a copy of this state with the given parameters.
  CameraState copyWith({
    List<CameraLens>? availableCameraLens,
    int? currentCameraLens,
    int? currentFlashMode,
    bool? isInitialized,
    bool? isRunning,
    bool? alreadyCheckingImage,
    double? zoomScale,
    CameraController? cameraController,
    DetectedFace? detectedFace,
  }) {
    return CameraState(
      availableCameraLens: availableCameraLens ?? this.availableCameraLens,
      currentCameraLens: currentCameraLens ?? this.currentCameraLens,
      isInitialized: isInitialized ?? this.isInitialized,
      alreadyCheckingImage: alreadyCheckingImage ?? this.alreadyCheckingImage,
      cameraController: cameraController ?? this.cameraController,
      detectedFace: detectedFace ?? this.detectedFace,
    );
  }
}
