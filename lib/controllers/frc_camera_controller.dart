import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:frc/handlers/enum_handler.dart';
import 'package:frc/handlers/face_identifier.dart';
import 'package:frc/res/enums.dart';
import 'package:image/image.dart' as img;

import 'package:frc/frc.dart';

/// The controller for the [FRCController] widget.
class FRCController extends ValueNotifier<CameraState> {
  /// Construct a new [FRCController] instance.
  FRCController({
    this.imageResolution = ImageResolution.medium,
    this.enableAudio = true,
    this.autoCapture = false,
    this.ignoreFacePositioning = false,
    this.orientation = CameraOrientation.portraitUp,
    required this.onCapture,
    this.onFaceDetected,
  }) : super(CameraState.uninitialized());

  /// The desired resolution for the camera.
  final ImageResolution imageResolution;

  /// Set false to disable capture sound.
  final bool enableAudio;

  /// Set true to capture image on face detected.
  final bool autoCapture;

  /// Set true to trigger onCapture even when the face is not well positioned
  final bool ignoreFacePositioning;

  /// Use this to lock camera orientation.
  final CameraOrientation? orientation;

  /// Callback invoked when camera captures image.
  final void Function(File? image, Uint8List? imageCropped) onCapture;

  /// Callback invoked when camera detects face.
  final void Function(Face? face)? onFaceDetected;

  /// Gets all available camera lens and set current len
  void _getAllAvailableCameraLens() {
    int currentCameraLens = 1;
    final List<CameraLens> availableCameraLens = [];
    for (CameraDescription d in Frc.cameras) {
      final lens = EnumHandler.cameraLensDirectionToCameraLens(d.lensDirection);
      if (lens != null && !availableCameraLens.contains(lens)) {
        availableCameraLens.add(lens);
      }
    }

    value = value.copyWith(
      availableCameraLens: availableCameraLens,
      currentCameraLens: currentCameraLens,
    );
  }

  Future<void> _initCamera() async {
    final cameras = Frc.cameras.where((c) {
      return c.lensDirection ==
          EnumHandler.cameraLensToCameraLensDirection(
            value.availableCameraLens[value.currentCameraLens],
          );
    }).toList();

    if (cameras.isNotEmpty) {
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final cameraController = CameraController(
        frontCamera,
        EnumHandler.imageResolutionToResolutionPreset(imageResolution),
        enableAudio: enableAudio,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await cameraController.initialize().whenComplete(() {
        value = value.copyWith(
          isInitialized: true,
          cameraController: cameraController,
        );
      });

      await cameraController.lockCaptureOrientation(
        EnumHandler.cameraOrientationToDeviceOrientation(orientation),
      );
    }

    startImageStream();
  }

  /// The supplied [zoom] value should be between 1.0 and the maximum supported
  Future<void> setZoomLevel(double zoom) async {
    final CameraController? cameraController = value.cameraController;
    if (cameraController == null) {
      return;
    }
    await cameraController.setZoomLevel(zoom);
  }

  Future<void> changeCameraLens() async {
    value = value.copyWith(
      currentCameraLens: (value.currentCameraLens + 1) % value.availableCameraLens.length,
    );
    _initCamera();
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = value.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      logError('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      logError('A capture is already pending');
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
  }

  Future<void> startImageStream() async {
    final CameraController? cameraController = value.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (!cameraController.value.isStreamingImages) {
      await cameraController.startImageStream(_processImage);
    }
  }

  Future<void> stopImageStream() async {
    final CameraController? cameraController = value.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (cameraController.value.isStreamingImages) {
      await cameraController.stopImageStream();
    }
  }

  removeRotation(File inputImage) async {
    final img.Image? capturedImage = img.decodeImage(await File(inputImage.path).readAsBytes());
    final img.Image orientedImage = img.bakeOrientation(capturedImage!);
    return await File(inputImage.path).writeAsBytes(img.encodeJpg(orientedImage));
  }

  void _processImage(CameraImage cameraImage) async {
    final CameraController? cameraController = value.cameraController;
    if (!value.alreadyCheckingImage) {
      value = value.copyWith(alreadyCheckingImage: true);
      try {
        await FaceIdentifier.scanImage(
          cameraImage: cameraImage,
          controller: cameraController,
        ).then((result) async {
          value = value.copyWith(detectedFace: result);

          if (result != null) {
            try {
              if (result.face != null) {
                onFaceDetected?.call(result.face);
              }
              if (autoCapture && (result.wellPositioned || ignoreFacePositioning)) {
                captureImage();
              }
            } catch (e) {
              logError(e.toString());
            }
          }
        });
        value = value.copyWith(alreadyCheckingImage: false);
      } catch (ex, stack) {
        value = value.copyWith(alreadyCheckingImage: false);
        logError('$ex, $stack');
      }
    }
  }

  void captureImage() async {
    final CameraController? cameraController = value.cameraController;
    try {
      cameraController!.stopImageStream().whenComplete(() async {
        takePicture().then((XFile? file) async {
          /// Return image callback
          if (file != null) {
            final uint8List = await FaceIdentifier.cropedImage(File(file.path));
            onCapture.call(File(file.path), uint8List);
          }
        });
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<(File?, Uint8List?)> captureControl() async {
    final CameraController? cameraController = value.cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      logError('Error: select a camera first.');
      return (null, null);
    }

    if (cameraController.value.isTakingPicture) {
      logError('A capture is already pending');
      return (null, null);
    }

    if (cameraController.value.isStreamingImages) {
      await cameraController.stopImageStream();
    }

    try {
      XFile? file = await takePicture();
      if (file == null) {
        return (null, null);
      }
      final uint8List = await FaceIdentifier.cropedImage(File(file.path));
      if (uint8List == null) {
        return (null, null);
      }
      return (File(file.path), uint8List);
    } on CameraException catch (e) {
      _showCameraException(e);
      return (null, null);
    }
  }
/*  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (value.cameraController == null) {
      return;
    }

    final CameraController cameraController = value.cameraController!;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }*/

  Future<void> initialize() async {
    _getAllAvailableCameraLens();
    _initCamera();
  }

  /// Enables controls only when camera is initialized.
  bool get enableControls {
    final CameraController? cameraController = value.cameraController;
    return cameraController != null && cameraController.value.isInitialized;
  }

  /// Dispose the controller.
  ///
  /// Once the controller is disposed, it cannot be used anymore.
  @override
  Future<void> dispose() async {
    final CameraController? cameraController = value.cameraController;

    if (cameraController != null && cameraController.value.isInitialized) {
      cameraController.dispose();
    }
    super.dispose();
  }
}
