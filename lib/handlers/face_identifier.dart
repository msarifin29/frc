import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc/frc.dart';
import 'package:image/image.dart' as img;

class FaceIdentifier {
  static Future<DetectedFace?> scanImage({
    required CameraImage cameraImage,
    required CameraController? controller,
  }) async {
    final orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    DetectedFace? result;
    final face = await _detectFace(
        visionImage: _inputImageFromCameraImage(cameraImage, controller, orientations));
    if (face != null) {
      result = face;
    }

    return result;
  }

  static InputImage? _inputImageFromCameraImage(
      CameraImage image, CameraController? controller, Map<DeviceOrientation, int> orientations) {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final camera = controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      // front-facing
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null || (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;
    final bytes = Platform.isAndroid
        ? image.getNv21Uint8List()
        : Uint8List.fromList(
            image.planes.fold(<int>[],
                (List<int> previousValue, element) => previousValue..addAll(element.bytes)),
          );
    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: Platform.isIOS ? format : InputImageFormat.nv21, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  static Future<DetectedFace?> _detectFace({required visionImage}) async {
    if (visionImage == null) return null;
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    final faceDetector = FaceDetector(options: options);
    try {
      final List<Face> faces = await faceDetector.processImage(visionImage);
      final faceDetect = _extractFace(faces);
      return faceDetect;
    } catch (error) {
      debugPrint(error.toString());
      return null;
    }
  }

  static _extractFace(List<Face> faces) {
    //List<Rect> rect = [];
    bool wellPositioned = faces.isNotEmpty;
    Face? detectedFace;

    for (Face face in faces) {
      // rect.add(face.boundingBox);
      detectedFace = face;
      // Head is rotated to the right rotY degrees
      if (face.headEulerAngleY! > 5 || face.headEulerAngleY! < -5) {
        wellPositioned = false;
      }

      // Head is tilted sideways rotZ degrees
      if (face.headEulerAngleZ! > 5 || face.headEulerAngleZ! < -5) {
        wellPositioned = false;
      }

      // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
      // eyes, cheeks, and nose available):
      final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];
      final FaceLandmark? rightEar = face.landmarks[FaceLandmarkType.rightEar];
      final FaceLandmark? bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
      final FaceLandmark? rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
      final FaceLandmark? leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
      final FaceLandmark? noseBase = face.landmarks[FaceLandmarkType.noseBase];
      if (leftEar == null ||
          rightEar == null ||
          bottomMouth == null ||
          rightMouth == null ||
          leftMouth == null ||
          noseBase == null) {
        wellPositioned = false;
      }

      if (face.leftEyeOpenProbability != null) {
        if (face.leftEyeOpenProbability! < 0.5) {
          wellPositioned = false;
        }
      }

      if (face.rightEyeOpenProbability != null) {
        if (face.rightEyeOpenProbability! < 0.5) {
          wellPositioned = false;
        }
      }
      if (wellPositioned) {
        break;
      }
    }
    return DetectedFace(wellPositioned: wellPositioned, face: detectedFace);
  }

  static Future<Uint8List?> cropedImage(File image) async {
    Uint8List? uint8list;
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    );

    final faceDetector = FaceDetector(options: options);

    final bytes = await image.readAsBytes();
    final decodeImage = await decodeImageFromList(bytes);

    InputImage inputImage = InputImage.fromFile(image);
    final faces = await faceDetector.processImage(inputImage);
    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      num left = faceRect.left < 0 ? 0 : faceRect.left;
      num top = faceRect.top < 0 ? 0 : faceRect.top;
      num right = faceRect.right > decodeImage.width ? decodeImage.width - 1 : faceRect.right;
      num bottom = faceRect.bottom > decodeImage.height ? decodeImage.height - 1 : faceRect.bottom;
      num width = right - left;
      num height = bottom - top;
      img.Image? faceImg = img.decodeImage(bytes);
      img.Image? faceImg2 = img.copyCrop(
        faceImg!,
        x: left.toInt(),
        y: top.toInt(),
        width: width.toInt(),
        height: height.toInt(),
      );
      uint8list = Uint8List.fromList(img.encodeBmp(faceImg2));
    }
    return uint8list;
  }
}
