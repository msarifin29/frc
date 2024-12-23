import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:frc/frc.dart';
import 'package:frc/paints/face_painter.dart';
import 'dart:math' as math;

class FaceCamera extends StatefulWidget {
  /// Set false to hide all controls.
  final bool showControls;

  /// Set false to hide capture control icon.
  final bool showCaptureControl;

  /// Use this pass a message above the camera.
  final String message;

  /// Use this pass a message above face not detected.
  final String emptyFaceMessage;

  /// Use this pass a message above description position.
  final String positionMessage;

  /// Use this pass a message center face into frame.
  final String centerMessage;

  /// Style applied to the message widget.
  final TextStyle messageStyle;

  /// Set true to automatically disable capture control widget when no face is detected.
  final bool autoDisableCaptureControl;

  /// The controller for the [FaceCamera] widget.
  final FRCController controller;

  /// Use this to build custom widgets for the description widget
  final Widget? descriptionWidget;

  final void Function(File? image, Uint8List? imageCropped)? captureControl;

  const FaceCamera({
    required this.controller,
    this.showControls = true,
    this.showCaptureControl = false,
    this.message = 'No Camera Detected',
    this.messageStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    this.autoDisableCaptureControl = false,
    this.descriptionWidget,
    this.emptyFaceMessage = 'Face not Detected',
    this.positionMessage = 'Please position your face in the camera frame',
    this.centerMessage = 'Center your face in the camera',
    this.captureControl,
    super.key,
  });

  @override
  State<FaceCamera> createState() => _FaceCameraState();
}

class _FaceCameraState extends State<FaceCamera> with WidgetsBindingObserver {
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
              Transform.scale(
                scale: 1.0,
                child: AspectRatio(
                  aspectRatio: size.aspectRatio,
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.fitHeight,
                      child: SizedBox(
                        width: size.width,
                        height: size.width * cameraController.value.aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            _cameraDisplayWidget(value),
                            if (value.detectedFace != null) ...[
                              SizedBox(
                                width: cameraController.value.previewSize!.width,
                                height: cameraController.value.previewSize!.height,
                                child: CustomPaint(
                                  painter: FacePainter(
                                    face: value.detectedFace!.face,
                                    imageSize: Size(
                                      cameraController.value.previewSize!.height,
                                      cameraController.value.previewSize!.width,
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ] else ...[
              Text(widget.message, style: widget.messageStyle),
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
                        if (value.detectedFace?.face == null)
                          messageDetectedFace(widget.emptyFaceMessage)
                        else if (value.detectedFace?.face != null &&
                            !value.detectedFace!.wellPositioned)
                          messageDetectedFace(widget.centerMessage),
                      ],
                    ),
                  ),
            ),
            if (widget.showControls) ...[
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      descriptionMessage(widget.positionMessage),
                      const SizedBox(height: 50),
                      if (widget.showCaptureControl) ...[
                        _captureControlWidget(value),
                      ],
                    ],
                  ),
                ),
              )
            ]
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
        child: CameraPreview(
          cameraController,
          child: Builder(
            builder: (context) => const SizedBox.shrink(),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// Determines when to disable the capture control button.
  bool get _disableCapture =>
      widget.autoDisableCaptureControl && widget.controller.value.detectedFace?.face == null;

  /// Determines the camera controls color.
  Color? get iconColor => widget.controller.enableControls ? null : Theme.of(context).disabledColor;

  // Determines if the face is well positioned
  bool get _wellPositioned => widget.controller.value.detectedFace?.wellPositioned ?? false;

  /// Display the control buttons to take pictures.
  Widget _captureControlWidget(CameraState value) {
    return InkWell(
      onTap: !_disableCapture && _wellPositioned
          ? () async {
              final result = await widget.controller.captureControl();
              widget.captureControl!(result.$1, result.$2);
            }
          : null,
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _disableCapture ? Colors.grey.shade300 : Colors.white,
        ),
        child: Container(
          width: 70,
          height: 70,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _disableCapture ? Colors.grey.shade300 : Colors.white,
            border: Border.all(color: Colors.black38, width: 4),
          ),
        ),
      ),
    );
  }

  /// Display a message above description message
  Widget descriptionMessage(String msg) {
    return Text(
      msg,
      style: const TextStyle(fontSize: 14, color: Colors.white),
    );
  }

  Widget closeButton() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
        child: const Icon(Icons.close, color: Colors.black),
      ),
    );
  }

  Widget messageDetectedFace(String message) {
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
}
