import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/player_progress.dart';
import '../models/quest.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

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

  final List<_AchievementPlaceholder> _achievementPlaceholders = const [
    _AchievementPlaceholder(
      emoji: '🔥',
      title: 'Streak Master',
      targetText: '7 day streak',
    ),
    _AchievementPlaceholder(
      emoji: '⭐',
      title: 'XP Collector',
      targetText: 'Reach 500 XP',
    ),
    _AchievementPlaceholder(
      emoji: '💎',
      title: 'Gem Hunter',
      targetText: 'Collect 50 gems',
    ),
    _AchievementPlaceholder(
      emoji: '🏆',
      title: 'Quest Hero',
      targetText: 'Complete 10 quests',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final isServer = await AuthService.instance.isServerSession();
      if (isServer) {
        final token = await AuthService.instance.getToken();
        if (token != null) {
          final res = await ApiClient.getProgress(token);
          if (res != null && mounted) {
            setState(() {
              _progress = PlayerProgress(
                userId: res.userId,
                level: res.level,
                xp: res.xp,
                totalXp: res.totalXp,
                xpForNext: res.xpForNext,
                gems: res.gems,
                streakDays: res.streakDays,
                updatedAt: res.updatedAt,
              );
              _completedQuestIds = res.completedQuestIds.toSet();
              _isLoading = false;
            });
            return;
          }
        }
      }
      final progress =
          await LocalStorageService.instance.getOrCreateProgress(widget.user.id!);
      final completed =
          await LocalStorageService.instance.getCompletedQuestIds(widget.user.id!);

      if (!mounted) return;

      setState(() {
        _progress = progress;
        _completedQuestIds = completed;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
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
                            _buildAchievementsRow(),
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

  Widget _buildStatsRow(PlayerProgress? progress) {
    return Row(
      children: [
        Expanded(
          child: _buildMainStat(
            value: '${progress?.streakDays ?? 0}',
            label: 'Streak',
          ),
        ),
        Expanded(
          child: _buildMainStat(
            value: '${progress?.totalXp ?? 0}',
            label: 'Total XP',
          ),
        ),
        Expanded(
          child: _buildMainStat(
            value: '${progress?.level ?? 1}',
            label: 'Level',
          ),
        ),
        Expanded(
          child: _buildMainStat(
            value: '${progress?.gems ?? 0}',
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
    required PlayerProgress? progress,
    required int completedQuestCount,
  }) {
    final currentXp = progress?.xp ?? 0;
    final xpForNext = progress?.xpForNext ?? 100;
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
                  text: '${progress?.streakDays ?? 0} days',
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  icon: '💎',
                  text: '${progress?.gems ?? 0} gems',
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
                  text: '${progress?.totalXp ?? 0} XP',
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

  Widget _buildAchievementsRow() {
    return SizedBox(
      height: 145,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _achievementPlaceholders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = _achievementPlaceholders[index];
          return _buildAchievementCard(item);
        },
      ),
    );
  }

  Widget _buildAchievementCard(_AchievementPlaceholder achievement) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3BF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.targetText,
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

class _AchievementPlaceholder {
  final String emoji;
  final String title;
  final String targetText;

  const _AchievementPlaceholder({
    required this.emoji,
    required this.title,
    required this.targetText,
  });
}