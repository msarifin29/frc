import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:frc/frc.dart';
import 'package:frc/paints/face_painter.dart';
import 'dart:math' as math;

class FaceCameraCircle extends StatefulWidget {
  /// Set false to hide all controls.
  final bool showControls;

  /// Set false to hide capture control icon.
  final bool showCaptureControl;

  /// Use this pass a message above the camera.
  final String message;

  /// Use this pass a message above face not detected.
  final String emptyFaceMessage;

  /// Use this pass a message center face into frame.
  final String centerMessage;

  /// Style applied to the message widget.
  final TextStyle messageStyle;

  /// Set true to automatically disable capture control widget when no face is detected.
  final bool autoDisableCaptureControl;

  /// The controller for the [FaceCameraCircle] widget.
  final FRCController controller;

  /// Use this to build custom widgets for the description widget
  final Widget? descriptionWidget;

  final void Function(File? image, Uint8List? imageCropped)? captureControl;

  const FaceCameraCircle({
    required this.controller,
    this.showControls = true,
    this.showCaptureControl = false,
    this.message = 'No Camera Detected',
    this.messageStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    this.autoDisableCaptureControl = false,
    this.descriptionWidget,
    this.emptyFaceMessage = 'Face not Detected',
    this.centerMessage = 'Center your face in the camera',
    this.captureControl,
    super.key,
  });

  @override
  State<FaceCameraCircle> createState() => _FaceCameraCircleState();
}

class _FaceCameraCircleState extends State<FaceCameraCircle> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    widget.controller.initialize();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.stopImageStream();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      widget.controller.stopImageStream();
    } else if (state == AppLifecycleState.paused) {
      widget.controller.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      widget.controller.startImageStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ValueListenableBuilder<CameraState>(
      valueListenable: widget.controller,
      builder: (BuildContext context, CameraState value, Widget? child) {
        final CameraController? cameraController = value.cameraController;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (cameraController != null && cameraController.value.isInitialized) ...[
              _cameraDisplayWidget(value),
              Positioned.fill(
                child: CustomPaint(
                  painter: FaceFramePainter(
                    isWellPositioned: _wellPositioned,
                    screenWidth: size.width,
                    screenHeight: size.height,
                    face: value.detectedFace?.face,
                  ),
                ),
              ),
            ] else ...[
              Text(widget.message, style: widget.messageStyle),
              CustomPaint(
                size: size,
                painter: HolePainter(),
              )
            ],
            Positioned(
              top: kToolbarHeight,
              child: widget.descriptionWidget ??
                  Container(
                    height: 50,
                    width: MediaQuery.sizeOf(context).width,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        closeButton(),
                        messageDetectedFace(
                          centerMessage(value.detectedFace?.face),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }

  /// Render camera.
  Widget _cameraDisplayWidget(CameraState value) {
    final CameraController? cameraController = value.cameraController;
    if (cameraController != null && cameraController.value.isInitialized) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: CameraPreview(cameraController),
      );
    }
    return const SizedBox.shrink();
  }

  /// Determines the camera controls color.
  Color? get iconColor => widget.controller.enableControls ? null : Theme.of(context).disabledColor;

  // Determines if the face is well positioned
  bool get _wellPositioned => widget.controller.value.detectedFace?.wellPositioned ?? false;

  /// Determines if the face is centered
  bool get _isPositionCenter {
    final face = widget.controller.value.detectedFace?.face;
    if (face != null) {
      final x = face.boundingBox.left + face.boundingBox.width / 2;
      final y = face.boundingBox.top + face.boundingBox.height / 2.5;
      return isPositionCenter(x, y);
    }
    return false;
  }

  /// Close button camera
  Widget closeButton() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.black),
        ),
        child: const Icon(Icons.close, color: Colors.black),
      ),
    );
  }

  /// Message detected face widget
  Widget messageDetectedFace(String message) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xff182230),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.white, size: 18),
          const SizedBox(width: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String centerMessage(Face? face) {
    if (face == null) {
      return widget.emptyFaceMessage;
    } else if (!_isPositionCenter) {
      return widget.centerMessage;
    }
    return '';
  }
}
