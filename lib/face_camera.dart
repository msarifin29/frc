import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:frc/frc.dart';
import 'package:frc/paints/face_painter.dart';
import 'dart:math' as math;

import 'package:frc/res/builders.dart';

class FaceCamera extends StatefulWidget {
  /// Set false to hide all controls.
  final bool showControls;

  /// Set false to hide capture control icon.
  final bool showCaptureControl;

  /// Set false to hide camera lens control icon.
  final bool showCameraLensControl;

  /// Use this pass a message above the camera.
  final String? message;

  /// Style applied to the message widget.
  final TextStyle messageStyle;

  /// Use this to build custom widgets for capture control.
  final CaptureControlBuilder? captureControlBuilder;

  /// Use this to build custom messages based on face position.
  final MessageBuilder? messageBuilder;

  /// Use this to pass an asset image when IndicatorShape is set to image.
  final String? indicatorAssetImage;

  /// Use this to build custom widgets for the face indicator
  final IndicatorBuilder? indicatorBuilder;

  /// Set true to automatically disable capture control widget when no face is detected.
  final bool autoDisableCaptureControl;

  /// The controller for the [FaceCamera] widget.
  final FRCController controller;

  const FaceCamera({
    required this.controller,
    this.showControls = true,
    this.showCaptureControl = true,
    this.showCameraLensControl = false,
    this.message,
    this.messageStyle = const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
    this.captureControlBuilder,
    this.messageBuilder,
    this.indicatorAssetImage,
    this.indicatorBuilder,
    this.autoDisableCaptureControl = false,
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
                                child: widget.indicatorBuilder?.call(
                                        context,
                                        value.detectedFace,
                                        Size(
                                          cameraController.value.previewSize!.height,
                                          cameraController.value.previewSize!.width,
                                        )) ??
                                    CustomPaint(
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
              const Text(
                'No Camera Detected',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
            if (widget.showControls) ...[
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showCaptureControl) ...[
                        const SizedBox(width: 15),
                        _captureControlWidget(value),
                        const SizedBox(width: 15)
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
            builder: (context) {
              if (widget.messageBuilder != null) {
                return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: widget.messageBuilder!.call(context, value.detectedFace));
              }
              if (widget.message != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
                  child: Text(widget.message!,
                      textAlign: TextAlign.center, style: widget.messageStyle),
                );
              }
              return const SizedBox.shrink();
            },
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

  /// Display the control buttons to take pictures.
  Widget _captureControlWidget(CameraState value) {
    return IconButton(
      icon: widget.captureControlBuilder?.call(context, value.detectedFace) ??
          CircleAvatar(
            radius: 35,
            foregroundColor: widget.controller.enableControls && !_disableCapture
                ? null
                : Theme.of(context).disabledColor,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.camera_alt, size: 35),
            ),
          ),
      onPressed: widget.controller.enableControls && !_disableCapture
          ? widget.controller.captureImage
          : null,
    );
  }
}
