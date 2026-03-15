import 'package:flutter/material.dart';

import '../data/achievements_data.dart';
import '../models/achievement.dart';
import '../models/player_progress.dart';
import '../widgets/achievement_icon.dart';

class AchievementsScreen extends StatelessWidget {
  final PlayerProgress progress;

  const AchievementsScreen({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final groupedAchievements = groupAchievementsBySection();
    final unlockedCount = getUnlockedAchievementCount(progress);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(unlockedCount),
            const SizedBox(height: 24),
            for (final entry in groupedAchievements.entries) ...[
              Text(
                entry.key.toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: entry.value.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final achievement = entry.value[index];
                  return _AchievementGridCard(
                    achievement: achievement,
                    progress: progress,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int unlockedCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 30,
              color: Color(0xFFFACC15),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlockedCount / ${achievementCatalog.length} achievements unlocked',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementGridCard extends StatelessWidget {
  final Achievement achievement;
  final PlayerProgress progress;

  const _AchievementGridCard({
    required this.achievement,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked(progress);
    final currentValue = achievement.currentValue(progress);
    final displayValue =
        currentValue > achievement.target ? achievement.target : currentValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFF111827) : const Color(0xFF172033),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFF06B6D4)
              : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: AchievementIcon(
              iconPath: achievement.iconPath,
              isUnlocked: isUnlocked,
              size: 90,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Text(
              achievement.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isUnlocked ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.25,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUnlocked
                    ? const Color(0xFF06B6D4)
                    : const Color(0xFF334155),
              ),
            ),
            child: Text(
              isUnlocked ? 'Unlocked' : '$displayValue / ${achievement.target}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isUnlocked
                    ? const Color(0xFF06B6D4)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}