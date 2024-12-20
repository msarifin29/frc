import 'package:flutter/material.dart';
import 'package:frc/models/detected_image.dart';

/// Returns message based on face position
typedef MessageBuilder = Widget Function(BuildContext context, DetectedFace? detectedFace);

/// Returns widget for detector
typedef IndicatorBuilder = Widget Function(
    BuildContext context, DetectedFace? detectedFace, Size? imageSize);

/// Returns widget for capture control
typedef CaptureControlBuilder = Widget Function(BuildContext context, DetectedFace? detectedFace);
