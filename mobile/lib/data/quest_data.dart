import '../models/quest.dart';

/// Lista fixă de quest-uri zilnice.
List<Quest> get dailyQuests => [
      Quest(
        id: 1,
        title: 'Rookie Push-ups',
        type: 'pushup',
        target: 5,
        rewardXp: 40,
        rewardGems: 2,
        icon: '💪',
        desc: 'Do 5 Push-ups',
      ),
      Quest(
        id: 2,
        title: 'Leg Day Basics',
        type: 'squat',
        target: 10,
        rewardXp: 50,
        rewardGems: 3,
        icon: '🦵',
        desc: 'Do 10 Squats',
      ),
      Quest(
        id: 3,
        title: 'Jumping Jacks Intro',
        type: 'jumping_jack',
        target: 10,
        rewardXp: 45,
        rewardGems: 2,
        icon: '🦘',
        desc: 'Do 10 Jumping Jacks',
      ),
      Quest(
        id: 4,
        title: "Warrior's Test",
        type: 'pushup',
        target: 15,
        rewardXp: 80,
        rewardGems: 5,
        icon: '⚔️',
        desc: 'Do 15 Push-ups',
      ),
    ];

/// Preset dificultate pentru path quests.
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

/// Mapează label-ul path la difficulty pentru API.
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

/// Generează lista de quest-uri pentru Quest Path.
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
      final target =
          preset.targets[exerciseIndex] + ((i ~/ 3) * 2);
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

/// Toate quest-urile (daily + path).
List<Quest> getAllQuests() {
  return [...dailyQuests, ...buildPathQuests()];
}
