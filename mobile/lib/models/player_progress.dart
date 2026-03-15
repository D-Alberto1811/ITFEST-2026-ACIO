class PlayerProgress {
  final int userId;
  final int level;
  final int xp;
  final int totalXp;
  final int xpForNext;
  final int gems;
  final int streakDays;
  final int bestStreakDays;
  final int totalPushups;
  final int totalSquats;
  final int totalJumpingJacks;
  final int totalWorkoutsCompleted;
  final int totalDailyChallengesCompleted;
  final String? lastStreakDate;
  final String updatedAt;

  const PlayerProgress({
    required this.userId,
    required this.level,
    required this.xp,
    required this.totalXp,
    required this.xpForNext,
    required this.gems,
    required this.streakDays,
    required this.bestStreakDays,
    required this.totalPushups,
    required this.totalSquats,
    required this.totalJumpingJacks,
    required this.totalWorkoutsCompleted,
    required this.totalDailyChallengesCompleted,
    required this.lastStreakDate,
    required this.updatedAt,
  });

  factory PlayerProgress.initial(int userId) {
    return PlayerProgress(
      userId: userId,
      level: 1,
      xp: 0,
      totalXp: 0,
      xpForNext: 100,
      gems: 0,
      streakDays: 0,
      bestStreakDays: 0,
      totalPushups: 0,
      totalSquats: 0,
      totalJumpingJacks: 0,
      totalWorkoutsCompleted: 0,
      totalDailyChallengesCompleted: 0,
      lastStreakDate: null,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'level': level,
      'xp': xp,
      'total_xp': totalXp,
      'xp_for_next': xpForNext,
      'gems': gems,
      'streak_days': streakDays,
      'best_streak_days': bestStreakDays,
      'total_pushups': totalPushups,
      'total_squats': totalSquats,
      'total_jumping_jacks': totalJumpingJacks,
      'total_workouts_completed': totalWorkoutsCompleted,
      'total_daily_challenges_completed': totalDailyChallengesCompleted,
      'last_streak_date': lastStreakDate,
      'updated_at': updatedAt,
    };
  }

  factory PlayerProgress.fromMap(Map<String, dynamic> map) {
    return PlayerProgress(
      userId: (map['user_id'] as num).toInt(),
      level: (map['level'] as num?)?.toInt() ?? 1,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      totalXp: (map['total_xp'] as num?)?.toInt() ?? 0,
      xpForNext: (map['xp_for_next'] as num?)?.toInt() ?? 100,
      gems: (map['gems'] as num?)?.toInt() ?? 0,
      streakDays: (map['streak_days'] as num?)?.toInt() ?? 0,
      bestStreakDays: (map['best_streak_days'] as num?)?.toInt() ?? 0,
      totalPushups: (map['total_pushups'] as num?)?.toInt() ?? 0,
      totalSquats: (map['total_squats'] as num?)?.toInt() ?? 0,
      totalJumpingJacks:
          (map['total_jumping_jacks'] as num?)?.toInt() ?? 0,
      totalWorkoutsCompleted:
          (map['total_workouts_completed'] as num?)?.toInt() ?? 0,
      totalDailyChallengesCompleted:
          (map['total_daily_challenges_completed'] as num?)?.toInt() ?? 0,
      lastStreakDate: map['last_streak_date'] as String?,
      updatedAt: map['updated_at'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  PlayerProgress copyWith({
    int? userId,
    int? level,
    int? xp,
    int? totalXp,
    int? xpForNext,
    int? gems,
    int? streakDays,
    int? bestStreakDays,
    int? totalPushups,
    int? totalSquats,
    int? totalJumpingJacks,
    int? totalWorkoutsCompleted,
    int? totalDailyChallengesCompleted,
    String? lastStreakDate,
    String? updatedAt,
  }) {
    return PlayerProgress(
      userId: userId ?? this.userId,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      totalXp: totalXp ?? this.totalXp,
      xpForNext: xpForNext ?? this.xpForNext,
      gems: gems ?? this.gems,
      streakDays: streakDays ?? this.streakDays,
      bestStreakDays: bestStreakDays ?? this.bestStreakDays,
      totalPushups: totalPushups ?? this.totalPushups,
      totalSquats: totalSquats ?? this.totalSquats,
      totalJumpingJacks: totalJumpingJacks ?? this.totalJumpingJacks,
      totalWorkoutsCompleted:
          totalWorkoutsCompleted ?? this.totalWorkoutsCompleted,
      totalDailyChallengesCompleted:
          totalDailyChallengesCompleted ?? this.totalDailyChallengesCompleted,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
