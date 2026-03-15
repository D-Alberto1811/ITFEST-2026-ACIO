import 'player_progress.dart';

enum AchievementType {
  streak,
  pushup,
  squat,
  jumpingJack,
  level,
}

class Achievement {
  final String id;
  final String sectionTitle;
  final String title;
  final String description;
  final String iconPath;
  final AchievementType type;
  final int target;

  const Achievement({
    required this.id,
    required this.sectionTitle,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.type,
    required this.target,
  });

  int currentValue(PlayerProgress progress) {
    switch (type) {
      case AchievementType.streak:
        return progress.streakDays;
      case AchievementType.pushup:
        return progress.totalPushups;
      case AchievementType.squat:
        return progress.totalSquats;
      case AchievementType.jumpingJack:
        return progress.totalJumpingJacks;
      case AchievementType.level:
        return progress.level;
    }
  }

  bool isUnlocked(PlayerProgress progress) {
    return currentValue(progress) >= target;
  }
}