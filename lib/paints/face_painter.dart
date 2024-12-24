// ignore_for_file: public_member_api_docs, sort_constructors_first

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

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = (face!.headEulerAngleY! > 10 || face!.headEulerAngleY! < -10)
          ? Colors.blue
          : Colors.green;

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

class FaceFramePainter extends CustomPainter {
  final bool isWellPositioned;
  final double screenWidth;
  final double screenHeight;
  final Face? face;

  FaceFramePainter({
    required this.isWellPositioned,
    required this.screenWidth,
    required this.screenHeight,
    required this.face,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 5.0;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.red.shade900;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final radius = screenWidth * 0.45;
    final circlePath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(screenWidth / 2, screenHeight / 2.5),
        radius: radius,
      ));

    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, screenWidth, screenHeight));
    final overlayPath = Path.combine(PathOperation.difference, outerPath, circlePath);

    paint
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    if (face != null) {
      double x = face!.boundingBox.left + face!.boundingBox.width / 2;
      double y = face!.boundingBox.top + face!.boundingBox.height / 2.5;
      final wellPositioned = isPositionCenter(x, y);
      if (wellPositioned) {
        borderPaint.color = Colors.blue;
      }
    }

    canvas.drawPath(overlayPath, paint);
    canvas.drawCircle(
      Offset(screenWidth / 2, screenHeight / 2.5),
      radius,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FaceFramePainter oldDelegate) {
    return oldDelegate.face != face;
  }
}

bool isPositionCenter(double x, double y) {
  if ((x > 210.0 && x < 250.0) && (y > 370.0 && y < 420.0)) return true;
  return false;
}

class HolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          Path()
            ..addOval(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: 160))
            ..close(),
        ),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
