import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  final Size imageSize;
  double? scaleX, scaleY;
  final Face? face;

  FacePainter({super.repaint, required this.imageSize, required this.face});

  @override
  void paint(Canvas canvas, Size size) {
    if (face == null) return;

    Paint paint;

    if (face!.headEulerAngleY! > 10 || face!.headEulerAngleY! < -10) {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.blue;
    } else {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.green;
    }

    scaleX = size.width / imageSize.width;
    scaleY = size.height / imageSize.height;
    canvas.drawRRect(
        _scaleRect(
          rect: face!.boundingBox,
          widgetSize: size,
          scaleX: scaleX,
          scaleY: scaleY,
        ),
        paint);
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.face != face;
  }
}

RRect _scaleRect({
  required Rect rect,
  required Size widgetSize,
  double? scaleX,
  double? scaleY,
}) {
  return RRect.fromLTRBR(
    (widgetSize.width - rect.left.toDouble() * scaleX!),
    rect.top.toDouble() * scaleY!,
    widgetSize.width - rect.right.toDouble() * scaleX,
    rect.bottom.toDouble() * scaleY,
    const Radius.circular(10),
  );
}
