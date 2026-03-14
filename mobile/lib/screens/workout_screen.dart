import 'package:flutter/material.dart';

import '../models/quest.dart';
import 'workout/jumping_jack_workout_screen.dart';
import 'workout/pushup_workout_screen.dart';
import 'workout/squat_workout_screen.dart';

/// Router: deschide ecranul de workout potrivit tipului de exercițiu din [quest].
class WorkoutScreen extends StatelessWidget {
  final Quest quest;
  final VoidCallback onComplete;

  const WorkoutScreen({
    super.key,
    required this.quest,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    switch (quest.type) {
      case 'pushup':
        return PushupWorkoutScreen(quest: quest, onComplete: onComplete);
      case 'squat':
        return SquatWorkoutScreen(quest: quest, onComplete: onComplete);
      case 'jumping_jack':
        return JumpingJackWorkoutScreen(quest: quest, onComplete: onComplete);
      default:
        return PushupWorkoutScreen(quest: quest, onComplete: onComplete);
    }
  }
}
