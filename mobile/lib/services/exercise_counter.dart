import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum ExerciseType { pushup, squat, jumpingJack }

class ExerciseCounter {
  final ExerciseType type;
  final int target;
  int repCount = 0;
  String _stage = 'up'; // up | down

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

    final shoulder = leftVis > rightVis ? leftShoulder! : rightShoulder!;
    final elbow = leftVis > rightVis ? leftElbow! : rightElbow!;
    final wrist = leftVis > rightVis ? leftWrist! : rightWrist!;

    final angle = _angle(shoulder, elbow, wrist);

    if (angle > 160) _stage = 'up';
    if (angle < 90 && _stage == 'up') _stage = 'down';
    if (_stage == 'down' && angle > 150) {
      repCount++;
      _stage = 'up';
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

    final hip = leftVis > rightVis ? leftHip! : rightHip!;
    final knee = leftVis > rightVis ? leftKnee! : rightKnee!;
    final ankle = leftVis > rightVis ? leftAnkle! : rightAnkle!;

    final angle = _angle(hip, knee, ankle);

    if (angle > 160) _stage = 'up';
    if (angle < 100 && _stage == 'up') _stage = 'down';
    if (_stage == 'down' && angle > 150) {
      repCount++;
      _stage = 'up';
    }
  }

  void _processJumpingJack(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null || rightShoulder == null || leftWrist == null || rightWrist == null) return;
    if ((leftShoulder.likelihood ?? 0) < 0.5 || (rightWrist.likelihood ?? 0) < 0.5) return;

    final avgWristY = (leftWrist.y + rightWrist.y) / 2;
    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final armsUp = avgWristY < avgShoulderY - 0.05;

    if (armsUp) _stage = 'up';
    if (!armsUp && _stage == 'up') {
      repCount++;
      _stage = 'down';
    }
    if (!armsUp) _stage = 'down';
  }

  bool get isComplete => repCount >= target;
}
