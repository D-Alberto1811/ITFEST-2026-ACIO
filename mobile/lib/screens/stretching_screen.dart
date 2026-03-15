import 'package:flutter/material.dart';

import 'stretch_tutorial_screen.dart';

class StretchingScreen extends StatelessWidget {
  const StretchingScreen({super.key});

  static const Color _bg = Color(0xFF0F172A);
  static const Color _panel = Color(0xFF111827);
  static const Color _card = Color(0xFF1E293B);
  static const Color _border = Color(0xFF334155);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _text = Colors.white;
  static const Color _accent = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final exercises = _stretchExercises;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Stretching',
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recovery & Mobility',
                    style: TextStyle(
                      color: _text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use these stretches before or after workouts to improve mobility and reduce muscle tension.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'STRETCH EXERCISES',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            ...exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _StretchExerciseCard(exercise: exercise),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StretchExerciseCard extends StatelessWidget {
  final StretchExercise exercise;

  const _StretchExerciseCard({
    required this.exercise,
  });

  static const Color _card = Color(0xFF1E293B);
  static const Color _border = Color(0xFF334155);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _text = Colors.white;
  static const Color _accent = Color(0xFF8B5CF6);
  static const Color _bg = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Center(
              child: Text(
                exercise.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${exercise.durationSeconds}s • ${exercise.bodyArea}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  exercise.shortDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StretchTutorialScreen(exercise: exercise),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: const Text(
              'Tutorial',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StretchExercise {
  final String id;
  final String title;
  final int durationSeconds;
  final String bodyArea;
  final String emoji;
  final String shortDescription;
  final List<String> steps;
  final List<String> tips;

  const StretchExercise({
    required this.id,
    required this.title,
    required this.durationSeconds,
    required this.bodyArea,
    required this.emoji,
    required this.shortDescription,
    required this.steps,
    required this.tips,
  });
}

const List<StretchExercise> _stretchExercises = [
  StretchExercise(
    id: 'neck_stretch',
    title: 'Neck Stretch',
    durationSeconds: 20,
    bodyArea: 'Neck',
    emoji: '🧘',
    shortDescription: 'Gently stretch your neck side to side to release tension.',
    steps: [
      'Sit or stand upright with your shoulders relaxed.',
      'Slowly tilt your head toward your right shoulder.',
      'Hold the position gently without forcing.',
      'Return to center and repeat on the left side.',
    ],
    tips: [
      'Do not raise your shoulders.',
      'Move slowly and keep breathing normally.',
      'Stop if you feel sharp pain.',
    ],
  ),
  StretchExercise(
    id: 'shoulder_stretch',
    title: 'Shoulder Stretch',
    durationSeconds: 25,
    bodyArea: 'Shoulders',
    emoji: '💪',
    shortDescription: 'Loosen your shoulders and upper back with a cross-arm stretch.',
    steps: [
      'Bring one arm across your chest.',
      'Use the opposite hand to support the arm.',
      'Pull gently toward your chest.',
      'Hold, then switch arms.',
    ],
    tips: [
      'Keep your shoulders down.',
      'Do not twist your torso.',
      'Stretch gently, not aggressively.',
    ],
  ),
  StretchExercise(
    id: 'quad_stretch',
    title: 'Quad Stretch',
    durationSeconds: 30,
    bodyArea: 'Quadriceps',
    emoji: '🦵',
    shortDescription: 'Stretch the front thigh muscles while balancing on one leg.',
    steps: [
      'Stand tall and hold onto a wall if needed.',
      'Bend one knee and bring your heel toward your glutes.',
      'Hold your ankle with the same-side hand.',
      'Keep knees close together and hold, then switch.',
    ],
    tips: [
      'Keep your chest upright.',
      'Do not arch your lower back.',
      'Use support if your balance is unstable.',
    ],
  ),
  StretchExercise(
    id: 'hamstring_stretch',
    title: 'Hamstring Stretch',
    durationSeconds: 30,
    bodyArea: 'Hamstrings',
    emoji: '🦶',
    shortDescription: 'Lengthen the back of your legs with a controlled forward reach.',
    steps: [
      'Stand with one leg slightly forward.',
      'Keep the front leg almost straight and hinge at the hips.',
      'Reach toward your shin or foot.',
      'Hold and repeat on the other side.',
    ],
    tips: [
      'Keep your back straight.',
      'Bend from the hips, not the waist.',
      'Do not bounce during the stretch.',
    ],
  ),
  StretchExercise(
    id: 'side_stretch',
    title: 'Side Stretch',
    durationSeconds: 20,
    bodyArea: 'Core / Side body',
    emoji: '↔️',
    shortDescription: 'Open the side body and improve mobility with an overhead reach.',
    steps: [
      'Stand with feet shoulder-width apart.',
      'Raise one arm overhead.',
      'Lean gently to the opposite side.',
      'Hold and repeat on the other side.',
    ],
    tips: [
      'Keep both feet grounded.',
      'Avoid twisting forward.',
      'Stretch upward first, then sideways.',
    ],
  ),
  StretchExercise(
    id: 'calf_stretch',
    title: 'Calf Stretch',
    durationSeconds: 25,
    bodyArea: 'Calves',
    emoji: '🏃',
    shortDescription: 'Release calf tightness by pressing the heel into the floor.',
    steps: [
      'Place your hands against a wall.',
      'Step one leg back.',
      'Keep the back heel flat on the floor.',
      'Lean forward slightly and hold, then switch sides.',
    ],
    tips: [
      'Keep the back leg straight.',
      'Keep your heel fully down.',
      'Do not rush the movement.',
    ],
  ),
];