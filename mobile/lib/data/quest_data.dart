import 'dart:math';

import '../models/quest.dart';

const bool useFastDailyQuestRotation = false;

Duration get dailyQuestRotationInterval => useFastDailyQuestRotation
    ? const Duration(seconds: 5)
    : const Duration(days: 1);

int currentDailyQuestCycle([DateTime? now]) {
  final currentTime = now ?? DateTime.now();
  return currentTime.millisecondsSinceEpoch ~/
      dailyQuestRotationInterval.inMilliseconds;
}

List<Quest> buildDailyQuestsForUser({
  required int userId,
  DateTime? now,
}) {
  final cycle = currentDailyQuestCycle(now);
  return buildDailyQuestsForCycle(
    userId: userId,
    cycle: cycle,
  );
}

List<Quest> buildDailyQuestsForCycle({
  required int userId,
  required int cycle,
}) {
  final random = Random((userId * 9973) + cycle);

  final pushupTargetOptions = [8, 10, 12, 14];
  final squatTargetOptions = [16, 18, 20, 22];
  final jumpingJackTargetOptions = [22, 24, 25, 28];

  final pushupTarget =
      pushupTargetOptions[(cycle + random.nextInt(100)) % pushupTargetOptions.length];
  final squatTarget =
      squatTargetOptions[(cycle + random.nextInt(100)) % squatTargetOptions.length];
  final jumpingJackTarget = jumpingJackTargetOptions[
      (cycle + random.nextInt(100)) % jumpingJackTargetOptions.length];

  final cycleBaseId = 100000 + (cycle * 10);

  return [
    Quest(
      id: cycleBaseId + 1,
      title: '$pushupTarget Push-ups',
      type: 'pushup',
      target: pushupTarget,
      rewardXp: 45 + ((pushupTarget - 8) * 2),
      rewardGems: 2,
      icon: '💪',
      desc: 'Do $pushupTarget push-ups',
      difficulty: 'beginner',
    ),
    Quest(
      id: cycleBaseId + 2,
      title: '$squatTarget Squats',
      type: 'squat',
      target: squatTarget,
      rewardXp: 50 + ((squatTarget - 16) * 2),
      rewardGems: 2,
      icon: '🦵',
      desc: 'Do $squatTarget squats',
      difficulty: 'beginner',
    ),
    Quest(
      id: cycleBaseId + 3,
      title: '$jumpingJackTarget Jumping Jacks',
      type: 'jumping_jack',
      target: jumpingJackTarget,
      rewardXp: 55 + ((jumpingJackTarget - 22) * 2),
      rewardGems: 3,
      icon: '🦘',
      desc: 'Do $jumpingJackTarget jumping jacks',
      difficulty: 'beginner',
    ),
  ];
}

class DifficultyPreset {
  final String label;
  final int xp;
  final int gems;
  final List<int> targets;

  const DifficultyPreset({
    required this.label,
    required this.xp,
    required this.gems,
    required this.targets,
  });
}

const List<DifficultyPreset> _pathDifficulties = [
  DifficultyPreset(
    label: 'Beginner',
    xp: 30,
    gems: 1,
    targets: [5, 8, 10],
  ),
  DifficultyPreset(
    label: 'Intermediate',
    xp: 45,
    gems: 2,
    targets: [12, 15, 18],
  ),
  DifficultyPreset(
    label: 'Medium',
    xp: 60,
    gems: 3,
    targets: [20, 24, 28],
  ),
  DifficultyPreset(
    label: 'Hard',
    xp: 85,
    gems: 4,
    targets: [30, 35, 40],
  ),
  DifficultyPreset(
    label: 'Extreme',
    xp: 120,
    gems: 6,
    targets: [45, 50, 60],
  ),
];

String pathDifficultyToApi(String label) {
  switch (label.toLowerCase()) {
    case 'hard':
      return 'advanced';
    case 'extreme':
      return 'expert';
    default:
      return label.toLowerCase();
  }
}

List<Quest> buildPathQuests() {
  final List<Quest> result = [];
  int id = 100;
  const exerciseTypes = ['pushup', 'squat', 'jumping_jack'];
  const exerciseTitles = ['Push-up', 'Squat', 'Jumping Jack'];
  const exerciseIcons = ['💪', '🦵', '🦘'];

  for (var difficultyIndex = 0;
      difficultyIndex < _pathDifficulties.length;
      difficultyIndex++) {
    final preset = _pathDifficulties[difficultyIndex];
    final difficulty = pathDifficultyToApi(preset.label);
    for (var i = 0; i < 10; i++) {
      final exerciseIndex = i % 3;
      final type = exerciseTypes[exerciseIndex];
      final exerciseTitle = exerciseTitles[exerciseIndex];
      final icon = exerciseIcons[exerciseIndex];
      final target = preset.targets[exerciseIndex] + ((i ~/ 3) * 2);
      result.add(
        Quest(
          id: id++,
          title: '${preset.label} $exerciseTitle ${i + 1}',
          type: type,
          target: target,
          rewardXp: preset.xp + (i * 3),
          rewardGems: preset.gems + (i ~/ 4),
          icon: icon,
          desc: 'Complete $target ${exerciseTitle.toLowerCase()}s',
          difficulty: difficulty,
        ),
      );
    }
  }
  return result;
}

List<Quest> getAllQuestsForUser({
  required int userId,
  DateTime? now,
}) {
  return [
    ...buildDailyQuestsForUser(userId: userId, now: now),
    ...buildPathQuests(),
  ];
}