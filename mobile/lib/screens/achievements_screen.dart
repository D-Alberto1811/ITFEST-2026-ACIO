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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB8F28E),
        foregroundColor: const Color(0xFF3C3C3C),
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
                  color: Color(0xFFA8A8A8),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3BF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 30,
              color: Color(0xFFFFB800),
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
                    color: Color(0xFF3C3C3C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlockedCount / ${achievementCatalog.length} achievements unlocked',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7B7B7B),
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
        color: isUnlocked ? Colors.white : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFFDFF3CF)
              : const Color(0xFFE1E1E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFFFFF3BF)
                    : const Color(0xFFE7E7E7),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AchievementIcon(
                  iconPath: achievement.iconPath,
                  isUnlocked: isUnlocked,
                  size: 42,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isUnlocked
                  ? const Color(0xFF3C3C3C)
                  : const Color(0xFF7A7A7A),
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
              color: Color(0xFF8F8F8F),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFFEAF8DE)
                  : const Color(0xFFE7E7E7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isUnlocked ? 'Unlocked' : '$displayValue / ${achievement.target}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isUnlocked
                    ? const Color(0xFF58CC02)
                    : const Color(0xFF8F8F8F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}