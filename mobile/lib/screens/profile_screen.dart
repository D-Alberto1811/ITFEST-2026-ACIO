import 'package:flutter/material.dart';

import '../data/achievements_data.dart';
import '../models/achievement.dart';
import '../models/app_user.dart';
import '../models/player_progress.dart';
import '../models/quest.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/achievement_icon.dart';
import 'achievements_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;
  final List<Quest> allQuests;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.allQuests,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;

  PlayerProgress? _progress;
  Set<int> _completedQuestIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final localProgress =
          await LocalStorageService.instance.getOrCreateProgress(widget.user.id!);
      final localCompleted =
          await LocalStorageService.instance.getCompletedQuestIds(widget.user.id!);

      final isServer = await AuthService.instance.isServerSession();
      if (isServer) {
        final token = await AuthService.instance.getToken();
        if (token != null) {
          final res = await ApiClient.getProgress(token);

          if (res != null && mounted) {
            setState(() {
              _progress = PlayerProgress(
                userId: widget.user.id ?? 0,
                level: res.level,
                xp: res.xp,
                totalXp: res.totalXp,
                xpForNext: res.xpForNext,
                gems: res.gems,
                streakDays: res.streakDays,
                totalPushups: localProgress.totalPushups,
                totalSquats: localProgress.totalSquats,
                totalJumpingJacks: localProgress.totalJumpingJacks,
                lastStreakDate: localProgress.lastStreakDate,
                updatedAt: DateTime.now().toIso8601String(),
              );
              _completedQuestIds = res.completedQuestIds.toSet();
              _isLoading = false;
            });
            return;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _progress = localProgress;
        _completedQuestIds = localCompleted;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _progress = PlayerProgress.initial(widget.user.id ?? 0);
        _completedQuestIds = <int>{};
        _isLoading = false;
      });
    }
  }

  void _openAchievements(PlayerProgress progress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AchievementsScreen(progress: progress),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress ?? PlayerProgress.initial(widget.user.id ?? 0);
    final completedQuestCount = _completedQuestIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF58CC02),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildTopHeader(),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIdentitySection(),
                            const SizedBox(height: 24),
                            _buildStatsRow(progress),
                            const SizedBox(height: 24),
                            _buildOverviewCard(
                              progress: progress,
                              completedQuestCount: completedQuestCount,
                            ),
                            const SizedBox(height: 28),
                            _buildSectionTitle('ACHIEVEMENTS'),
                            const SizedBox(height: 14),
                            _buildAchievementsSection(progress),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      decoration: const BoxDecoration(
        color: Color(0xFFB8F28E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3C3C3C),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 32,
                  color: Color(0xFF4B4B4B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD9C8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF7A4A35),
                  width: 6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 14,
                    child: Container(
                      width: 95,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8B8D6),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(40),
                          bottom: Radius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.person_rounded,
                    size: 110,
                    color: Color(0xFF6E4A3B),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '@${widget.user.name.toLowerCase().replaceAll(' ', '')}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFFA8A8A8),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.user.email,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF7B7B7B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(PlayerProgress progress) {
    return Row(
      children: [
        Expanded(
          child: _buildMainStat(
            value: '${progress.streakDays}',
            label: 'Streak',
          ),
        ),
        Expanded(
          child: _buildMainStat(
            value: '${progress.totalXp}',
            label: 'Total XP',
          ),
        ),
        Expanded(
          child: _buildMainStat(
            value: '${progress.level}',
            label: 'Level',
          ),
        ),
        Expanded(
          child: _buildMainStat(
            value: '${progress.gems}',
            label: 'Gems',
          ),
        ),
      ],
    );
  }

  Widget _buildMainStat({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF3C3C3C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8A8A8A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required PlayerProgress progress,
    required int completedQuestCount,
  }) {
    final currentXp = progress.xp;
    final xpForNext = progress.xpForNext;
    final progressValue = xpForNext == 0 ? 0.0 : currentXp / xpForNext;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OVERVIEW',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFFA8A8A8),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  icon: '🔥',
                  text: '${progress.streakDays} days',
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  icon: '💎',
                  text: '${progress.gems} gems',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  icon: '🏆',
                  text: '$completedQuestCount quests',
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  icon: '⭐',
                  text: '${progress.totalXp} XP',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'LEVEL PROGRESS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8F8F8F),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: const Color(0xFFEDEDED),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF58CC02),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currentXp / $xpForNext XP to next level',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8A8A8A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem({
    required String icon,
    required String text,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: Color(0xFFA8A8A8),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildAchievementsSection(PlayerProgress progress) {
    final previewAchievements = getPreviewAchievements(
      progress,
      limit: 4,
    );
    final unlockedCount = getUnlockedAchievementCount(progress);

    return GestureDetector(
      onTap: () => _openAchievements(progress),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE7E7E7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$unlockedCount / ${achievementCatalog.length} unlocked',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const Spacer(),
                const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF58CC02),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF58CC02),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: previewAchievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final achievement = previewAchievements[index];
                  return _buildAchievementPreviewCard(
                    achievement,
                    progress,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementPreviewCard(
    Achievement achievement,
    PlayerProgress progress,
  ) {
    final isUnlocked = achievement.isUnlocked(progress);

    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFFDFF3CF)
              : const Color(0xFFE1E1E1),
        ),
      ),
      child: Column(
        children: [
          Container(
            child: Center(
              child: AchievementIcon(
                iconPath: achievement.iconPath,
                isUnlocked: isUnlocked,
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isUnlocked
                  ? const Color(0xFF4A4A4A)
                  : const Color(0xFF7A7A7A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isUnlocked ? 'Unlocked' : achievement.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.2,
              color: Color(0xFF9A9A9A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}