import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum ExerciseType { pushup, squat, jumpingJack }

/// Nota finală sesiune: A, B, C, D, E.
enum SessionGrade { A, B, C, D, E }

class ExerciseCounter {
  final ExerciseType type;
  final int target;
  int repCount = 0;
  String _stage = 'up'; // up | down
  int _framesSinceRep = 0; // anti double-count

  /// Unghi minim la "bottom" în timpul rep-ului (pentru calitate).
  double _minAngleThisRep = 180;

  /// Scoruri per repetiție (0.0 - 1.0).
  final List<double> _repScores = [];

  ExerciseCounter({required this.type, required this.target});

  /// Media notelor tuturor repetițiilor.
  double get averageScore =>
      _repScores.isEmpty ? 1.0 : _repScores.reduce((a, b) => a + b) / _repScores.length;

  /// Nota finală (A-E) bazată pe calitatea formei.
  SessionGrade get sessionGrade {
    final avg = averageScore;
    if (avg >= 0.9) return SessionGrade.A;
    if (avg >= 0.75) return SessionGrade.B;
    if (avg >= 0.6) return SessionGrade.C;
    if (avg >= 0.45) return SessionGrade.D;
    return SessionGrade.E;
  }

  String get gradeLabel {
    switch (sessionGrade) {
      case SessionGrade.A:
        return 'A - Excellent form!';
      case SessionGrade.B:
        return 'B - Great job!';
      case SessionGrade.C:
        return 'C - Good, keep going!';
      case SessionGrade.D:
        return 'D - Room to improve';
      case SessionGrade.E:
        return 'E - Focus on your form';
    }
  }

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

  /// Verifică dacă corpul e orizontal (planșă) față de cameră.
  /// Dacă persoana stă în picioare, umeri și șolduri sunt pe verticală → nu numără flotări.
  bool _isBodyHorizontalForPushup(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) return false;
    if ((leftShoulder.likelihood ?? 0) < 0.5 || (rightShoulder.likelihood ?? 0) < 0.5) return false;
    if ((leftHip.likelihood ?? 0) < 0.5 || (rightHip.likelihood ?? 0) < 0.5) return false;

    final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipY = (leftHip.y + rightHip.y) / 2;
    final shoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final hipX = (leftHip.x + rightHip.x) / 2;
    final dy = hipY - shoulderY;
    final dx = hipX - shoulderX;
    final torsoAngleDeg = atan2(dy, dx) * 180 / pi;
    // Corp orizontal: unghiul torso față de orizontală aproape 0° sau 180°
    final absAngle = torsoAngleDeg.abs();
    return absAngle < 40 || absAngle > 140;
  }

  void _processPushup(Pose pose) {
    if (!_isBodyHorizontalForPushup(pose)) return;

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
    if (angle < 95 && _stage == 'up') {
      _stage = 'down';
      _minAngleThisRep = 180;
    }
    if (_stage == 'down') {
      if (angle < _minAngleThisRep) _minAngleThisRep = angle;
    }
    if (_stage == 'down' && angle > 140 && _framesSinceRep > 5) {
      repCount++;
      _repScores.add(_scorePushupDepth(_minAngleThisRep));
      _stage = 'up';
      _framesSinceRep = 0;
    }
  }

  /// Scor 0-1 pentru adâncime flotări: ideal ~90°.
  double _scorePushupDepth(double minAngle) {
    if (minAngle <= 100) return 1.0;
    if (minAngle <= 115) return 0.9;
    if (minAngle <= 130) return 0.75;
    if (minAngle <= 140) return 0.5;
    return 0.3;
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
    if (angle < 105 && _stage == 'up') {
      _stage = 'down';
      _minAngleThisRep = 180;
    }
    if (_stage == 'down') {
      if (angle < _minAngleThisRep) _minAngleThisRep = angle;
    }
    if (_stage == 'down' && angle > 145 && _framesSinceRep > 5) {
      repCount++;
      _repScores.add(_scoreSquatDepth(_minAngleThisRep));
      _stage = 'up';
      _framesSinceRep = 0;
    }
  }

  /// Scor 0-1 pentru adâncime genuflexiuni: ideal ~90°.
  double _scoreSquatDepth(double minAngle) {
    if (minAngle <= 105) return 1.0;
    if (minAngle <= 120) return 0.9;
    if (minAngle <= 135) return 0.75;
    if (minAngle <= 145) return 0.5;
    return 0.3;
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
      _repScores.add(0.85); // Jumping jack: detectare binară, notă default bună
      _stage = 'down';
      _framesSinceRep = 0;
    }
    if (!armsUp) _stage = 'down';
  }

  bool get isComplete => repCount >= target;
}
