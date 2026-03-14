import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Preview cameră + overlay skeleton pose (folosit de toate ecranele de workout).
class WorkoutCameraOverlay extends StatelessWidget {
  final CameraController controller;
  final Pose? lastPose;
  final double lastImageWidth;
  final double lastImageHeight;
  final int sensorOrientation;
  final CameraLensDirection lensDirection;

  const WorkoutCameraOverlay({
    super.key,
    required this.controller,
    required this.lastPose,
    required this.lastImageWidth,
    required this.lastImageHeight,
    required this.sensorOrientation,
    required this.lensDirection,
  });

  @override
  Widget build(BuildContext context) {
    final ar = controller.value.aspectRatio;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final displayAr = (isPortrait && ar > 1) ? 1 / ar : ar;
    return AspectRatio(
      aspectRatio: displayAr,
      child: CameraPreview(
        controller,
        child: lastPose != null
            ? IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _WorkoutPoseOverlayPainter(
                        pose: lastPose!,
                        imageWidth: lastImageWidth,
                        imageHeight: lastImageHeight,
                        sensorOrientation: sensorOrientation,
                        lensDirection: lensDirection,
                        previewAspectRatio: ar,
                      ),
                    );
                  },
                ),
              )
            : null,
      ),
    );
  }
}

class _WorkoutPoseOverlayPainter extends CustomPainter {
  final Pose pose;
  final double imageWidth;
  final double imageHeight;
  final int sensorOrientation;
  final CameraLensDirection lensDirection;
  final double? previewAspectRatio;

  _WorkoutPoseOverlayPainter({
    required this.pose,
    required this.imageWidth,
    required this.imageHeight,
    this.sensorOrientation = 0,
    this.lensDirection = CameraLensDirection.back,
    this.previewAspectRatio,
  });

  Offset _translatePoint(double x, double y, Size canvasSize) {
    if (Platform.isIOS) {
      return _translatePointIOS(x, y, canvasSize);
    }
    return _translatePointAndroid(x, y, canvasSize);
  }

  Offset _translatePointIOS(double x, double y, Size canvasSize) {
    final imageSize = Size(imageWidth, imageHeight);
    final rot = _rotation;
    final screenX = _translateX(x, canvasSize, imageSize, rot, true);
    final screenY = _translateY(y, canvasSize, imageSize, rot, true);
    return Offset(screenX, screenY);
  }

  InputImageRotation get _rotation {
    switch (sensorOrientation) {
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  Offset _translatePointAndroid(double x, double y, Size canvasSize) {
    final rect = _getPreviewRect(canvasSize);
    final w = imageWidth;
    final h = imageHeight;
    double localX, localY;
    switch (sensorOrientation) {
      case 90:
        localX = y * rect.width / h;
        localY = (w - x) * rect.height / w;
        break;
      case 270:
        localX = (h - y) * rect.width / h;
        localY = x * rect.height / w;
        break;
      case 180:
        localX = (w - x) * rect.width / w;
        localY = (h - y) * rect.height / h;
        break;
      default:
        localX = x * rect.width / w;
        localY = y * rect.height / h;
    }
    if (lensDirection == CameraLensDirection.front && (sensorOrientation == 0 || sensorOrientation == 180)) {
      localX = rect.width - localX;
    }
    return Offset(rect.left + localX, rect.top + localY);
  }

  Rect _getPreviewRect(Size screenSize) {
    if (previewAspectRatio == null) return Offset.zero & screenSize;
    final ar = previewAspectRatio!;
    final isPortrait = screenSize.height > screenSize.width;
    final displayAr = (isPortrait && ar > 1) ? 1 / ar : ar;
    double w = screenSize.width, h = screenSize.height;
    if (w / h > displayAr) {
      w = h * displayAr;
    } else {
      h = w / displayAr;
    }
    final left = (screenSize.width - w) / 2;
    final top = (screenSize.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  double _translateX(double x, Size canvasSize, Size imageSize, InputImageRotation rot, bool isIOS) {
    switch (rot) {
      case InputImageRotation.rotation90deg:
        return x * canvasSize.width / (isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation270deg:
        return canvasSize.width - x * canvasSize.width / (isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return lensDirection == CameraLensDirection.back
            ? x * canvasSize.width / imageSize.width
            : canvasSize.width - x * canvasSize.width / imageSize.width;
    }
  }

  double _translateY(double y, Size canvasSize, Size imageSize, InputImageRotation rot, bool isIOS) {
    switch (rot) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * canvasSize.height / (isIOS ? imageSize.height : imageSize.width);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y * canvasSize.height / imageSize.height;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final canvasSize = Size(size.width, size.height);
    final minLikelihood = Platform.isAndroid ? 0.2 : 0.5;

    final connections = [
      (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
      (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
      (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
      (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
      (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
      (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
      (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
      (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
      (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
      (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
      (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
      (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
    ];

    final linePaint = Paint()
      ..color = Platform.isAndroid ? const Color(0xFF00FFFF) : const Color(0xFF06B6D4)
      ..strokeWidth = Platform.isAndroid ? 5 : 3
      ..style = PaintingStyle.stroke;

    for (final (a, b) in connections) {
      final p1 = pose.landmarks[a];
      final p2 = pose.landmarks[b];
      if (p1 != null && p2 != null && p1.likelihood > minLikelihood && p2.likelihood > minLikelihood) {
        final pt1 = _translatePoint(p1.x, p1.y, canvasSize);
        final pt2 = _translatePoint(p2.x, p2.y, canvasSize);
        canvas.drawLine(pt1, pt2, linePaint);
      }
    }

    final pointPaint = Paint()
      ..color = Platform.isAndroid ? const Color(0xFFFFFF00) : const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;

    final pointRadius = Platform.isAndroid ? 12.0 : 6.0;
    for (final landmark in pose.landmarks.values) {
      if (landmark.likelihood > minLikelihood) {
        final pt = _translatePoint(landmark.x, landmark.y, canvasSize);
        canvas.drawCircle(pt, pointRadius, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WorkoutPoseOverlayPainter oldDelegate) => true;
}
