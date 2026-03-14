class PlayerProgress {
  final int userId;
  final int level;
  final int xp;
  final int totalXp;
  final int xpForNext;
  final int gems;
  final int streakDays;
  final String updatedAt;

  const PlayerProgress({
    required this.userId,
    required this.level,
    required this.xp,
    required this.totalXp,
    required this.xpForNext,
    required this.gems,
    required this.streakDays,
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
      updatedAt: map['updated_at'] as String? ?? '',
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
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}