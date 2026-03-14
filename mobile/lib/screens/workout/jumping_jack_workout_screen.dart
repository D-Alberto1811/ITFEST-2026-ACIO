import 'package:flutter/material.dart';

import '../../models/quest.dart';
import '../../services/exercise_counter.dart' show ExerciseType;
import 'workout_base_screen.dart';

/// Ecran workout pentru jumping jacks.
/// Poți customiza aici UI-ul sau hint-urile specifice jumping jack.
class JumpingJackWorkoutScreen extends StatelessWidget {
  final Quest quest;
  final VoidCallback onComplete;

  const JumpingJackWorkoutScreen({
    super.key,
    required this.quest,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return WorkoutBaseScreen(
      quest: quest,
      exerciseType: ExerciseType.jumpingJack,
      onComplete: onComplete,
    );
  }
}
