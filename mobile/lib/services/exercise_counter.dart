import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum ExerciseType { pushup, squat, jumpingJack }

class ExerciseCounter {
  final ExerciseType type;
  final int target;
  int repCount = 0;
  String _stage = 'up'; // up | down
  int _framesSinceRep = 0; // anti double-count

  ExerciseCounter({required this.type, required this.target});

  void processPose(Pose pose) {
    switch (type) {
      case ExerciseType.pushup:
        _processPushup(pose);
        break;
      case ExerciseType.squat:
        _processSquat(pose);
        break;
      case ExerciseType.jumpingJack:
        _processJumpingJack(pose);
        break;
    }
  }

  double _angle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    final ax = p1.x - p2.x, ay = p1.y - p2.y;
    final cx = p3.x - p2.x, cy = p3.y - p2.y;
    final radians = atan2(cy, cx) - atan2(ay, ax);
    var angle = (radians * 180 / pi).abs();
    return angle > 180 ? 360 - angle : angle;
  }

  void _processPushup(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    final leftVis = (leftShoulder?.likelihood ?? 0) + (leftElbow?.likelihood ?? 0) + (leftWrist?.likelihood ?? 0);
    final rightVis = (rightShoulder?.likelihood ?? 0) + (rightElbow?.likelihood ?? 0) + (rightWrist?.likelihood ?? 0);

    if (leftVis < 1.5 && rightVis < 1.5) return;

    _framesSinceRep++;

    // Folosește ambele brațe când sunt vizibile pentru mai multă acuratețe
    double? leftAngle, rightAngle;
    if (leftVis >= 1.5 && leftShoulder != null && leftElbow != null && leftWrist != null) {
      leftAngle = _angle(leftShoulder, leftElbow, leftWrist);
    }
    if (rightVis >= 1.5 && rightShoulder != null && rightElbow != null && rightWrist != null) {
      rightAngle = _angle(rightShoulder, rightElbow, rightWrist);
    }
    final angle = (leftAngle != null && rightAngle != null)
        ? (leftAngle + rightAngle) / 2
        : (leftAngle ?? rightAngle);
    if (angle == null) return;

    if (angle > 165) _stage = 'up';
    if (angle < 95 && _stage == 'up') _stage = 'down';
    if (_stage == 'down' && angle > 140 && _framesSinceRep > 5) {
      repCount++;
      _stage = 'up';
      _framesSinceRep = 0;
    }
  }

  void _processSquat(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    final leftVis = (leftHip?.likelihood ?? 0) + (leftKnee?.likelihood ?? 0) + (leftAnkle?.likelihood ?? 0);
    final rightVis = (rightHip?.likelihood ?? 0) + (rightKnee?.likelihood ?? 0) + (rightAnkle?.likelihood ?? 0);

    if (leftVis < 1.5 && rightVis < 1.5) return;

    _framesSinceRep++;

    // Folosește ambele picioare când sunt vizibile
    double? leftAngle, rightAngle;
    if (leftVis >= 1.5 && leftHip != null && leftKnee != null && leftAnkle != null) {
      leftAngle = _angle(leftHip, leftKnee, leftAnkle);
    }
    if (rightVis >= 1.5 && rightHip != null && rightKnee != null && rightAnkle != null) {
      rightAngle = _angle(rightHip, rightKnee, rightAnkle);
    }
    final angle = (leftAngle != null && rightAngle != null)
        ? (leftAngle + rightAngle) / 2
        : (leftAngle ?? rightAngle);
    if (angle == null) return;

    if (angle > 165) _stage = 'up';
    if (angle < 105 && _stage == 'up') _stage = 'down';
    if (_stage == 'down' && angle > 145 && _framesSinceRep > 5) {
      repCount++;
      _stage = 'up';
      _framesSinceRep = 0;
    }
  }

  void _processJumpingJack(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null || rightShoulder == null || leftWrist == null || rightWrist == null) return;
    if ((leftShoulder.likelihood ?? 0) < 0.5 || (rightWrist.likelihood ?? 0) < 0.5) return;

    _framesSinceRep++;

    final avgWristY = (leftWrist.y + rightWrist.y) / 2;
    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final armsUp = avgWristY < avgShoulderY - 0.05;

    if (armsUp) _stage = 'up';
    if (!armsUp && _stage == 'up' && _framesSinceRep > 5) {
      repCount++;
      _stage = 'down';
      _framesSinceRep = 0;
    }
    if (!armsUp) _stage = 'down';
  }

  bool get isComplete => repCount >= target;
}
