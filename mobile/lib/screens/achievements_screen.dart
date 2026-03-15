import 'package:flutter/material.dart';

import '../data/achievements_data.dart';
import '../models/achievement.dart';
import '../models/player_progress.dart';
import '../widgets/achievement_icon.dart';

class AchievementsScreen extends StatelessWidget {
  static const Color _bg = Color(0xFF0F172A);
  static const Color _panel = Color(0xFF111827);
  static const Color _card = Color(0xFF1E293B);
  static const Color _border = Color(0xFF334155);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _text = Colors.white;
  static const Color _accent = Color(0xFF06B6D4);
  static const Color _gold = Color(0xFFFACC15);

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        elevation: 0,
        title: const Text(
          'Achievements',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(unlockedCount),
            const SizedBox(height: 28),
            for (final entry in groupedAchievements.entries) ...[
              Text(
                entry.key.toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _muted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                itemCount: entry.value.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.66,
                ),
                itemBuilder: (context, index) {
                  final achievement = entry.value[index];
                  return _AchievementGridCard(
                    achievement: achievement,
                    progress: progress,
                  );
                },
              ),
              const SizedBox(height: 26),
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
        color: _panel,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _card,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 34,
              color: _gold,
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
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlockedCount / ${achievementCatalog.length} achievements unlocked',
                  style: const TextStyle(
                    fontSize: 14,
                    color: _muted,
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
  static const Color _bg = Color(0xFF0F172A);
  static const Color _card = Color(0xFF1E293B);
  static const Color _lockedCard = Color(0xFF172033);
  static const Color _border = Color(0xFF334155);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _text = Colors.white;
  static const Color _accent = Color(0xFF06B6D4);
  static const Color _gold = Color(0xFFFACC15);

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
        color: isUnlocked ? _card : _lockedCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnlocked ? _accent.withOpacity(0.28) : _border,
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _bg.withOpacity(0.55),
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: Center(
                child: AchievementIcon(
                  iconPath: achievement.iconPath,
                  isUnlocked: isUnlocked,
                  size: 58,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
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
                color: isUnlocked ? _text : _muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                achievement.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: _bg.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Text(
              isUnlocked ? 'Unlocked' : '$displayValue / ${achievement.target}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isUnlocked ? _gold : _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}