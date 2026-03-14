import 'package:flutter/material.dart';

import '../../models/quest.dart';
import '../../services/exercise_counter.dart' show ExerciseType;
import 'workout_base_screen.dart';

/// Ecran workout pentru genuflexiuni (squats).
/// Poți customiza aici UI-ul sau hint-urile specifice squat.
class SquatWorkoutScreen extends StatelessWidget {
  final Quest quest;
  final VoidCallback onComplete;

  const SquatWorkoutScreen({
    super.key,
    required this.quest,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return WorkoutBaseScreen(
      quest: quest,
      exerciseType: ExerciseType.squat,
      onComplete: onComplete,
    );
  }
}
