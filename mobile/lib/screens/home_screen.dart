import 'package:flutter/material.dart';

import '../data/quest_data.dart';
import '../models/app_user.dart';
import '../models/player_progress.dart';
import '../models/quest.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/home/home_daily_quests_tab.dart';
import '../widgets/home/home_hero_card.dart';
import '../widgets/home/home_section_headers.dart';
import 'login_screen.dart';
import 'path_screen.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';
import 'worldwide_rankings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUser? _currentUser;
  bool _isLoadingUser = true;

  int _selectedTabIndex = 0;

  int level = 1;
  int xp = 0;
  int totalXp = 0;
  int xpForNext = 100;
  int gems = 0;
  int streakDays = 0;

  int totalPushups = 0;
  int totalSquats = 0;
  int totalJumpingJacks = 0;
  String? lastStreakDate;

  Set<int> completedQuestIds = <int>{};

  late final List<Quest> _pathQuests = buildPathQuests();
  List<Quest> get _dailyQuests => dailyQuests;
  List<Quest> get _allQuests => getAllQuests();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndProgress();
  }

  Future<void> _loadCurrentUserAndProgress() async {
    try {
      final user = await AuthService.instance.getCurrentUser();

      if (user != null) {
        final localProgress =
            await LocalStorageService.instance.getOrCreateProgress(user.id!);

        final isServer = await AuthService.instance.isServerSession();
        if (isServer) {
          final token = await AuthService.instance.getToken();
          if (token != null) {
            final progressRes = await ApiClient.getProgress(token);

            if (progressRes != null && mounted) {
              setState(() {
                _currentUser = user;
                level = progressRes.level;
                xp = progressRes.xp;
                totalXp = progressRes.totalXp;
                xpForNext = progressRes.xpForNext;
                gems = progressRes.gems;
                streakDays = progressRes.streakDays;
                completedQuestIds = progressRes.completedQuestIds.toSet();

                totalPushups = localProgress.totalPushups;
                totalSquats = localProgress.totalSquats;
                totalJumpingJacks = localProgress.totalJumpingJacks;
                lastStreakDate = localProgress.lastStreakDate;

                _isLoadingUser = false;
              });
              return;
            }
          }
        }

        final progress =
            await LocalStorageService.instance.getOrCreateProgress(user.id!);
        final questIds =
            await LocalStorageService.instance.getCompletedQuestIds(user.id!);

        if (!mounted) return;

        setState(() {
          _currentUser = user;
          level = progress.level;
          xp = progress.xp;
          totalXp = progress.totalXp;
          xpForNext = progress.xpForNext;
          gems = progress.gems;
          streakDays = progress.streakDays;
          completedQuestIds = questIds;
          totalPushups = progress.totalPushups;
          totalSquats = progress.totalSquats;
          totalJumpingJacks = progress.totalJumpingJacks;
          lastStreakDate = progress.lastStreakDate;
          _isLoadingUser = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _saveProgress() async {
    final user = _currentUser;
    if (user == null || user.id == null) return;

    final progress = PlayerProgress(
      userId: user.id!,
      level: level,
      xp: xp,
      totalXp: totalXp,
      xpForNext: xpForNext,
      gems: gems,
      streakDays: streakDays,
      totalPushups: totalPushups,
      totalSquats: totalSquats,
      totalJumpingJacks: totalJumpingJacks,
      lastStreakDate: lastStreakDate,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await LocalStorageService.instance.saveProgress(progress);
  }

  void _applyExerciseTotals(Quest quest) {
    switch (quest.type) {
      case 'pushup':
        totalPushups += quest.target;
        break;
      case 'squat':
        totalSquats += quest.target;
        break;
      case 'jumping_jack':
        totalJumpingJacks += quest.target;
        break;
    }
  }

  String _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  void _updateDailyStreak() {
    final todayKey = _normalizeDate(DateTime.now());

    if (lastStreakDate == null) {
      streakDays = 1;
      lastStreakDate = todayKey;
      return;
    }

    final parsed = DateTime.tryParse(lastStreakDate!);
    if (parsed == null) {
      streakDays = 1;
      lastStreakDate = todayKey;
      return;
    }

    final lastDay = DateTime(parsed.year, parsed.month, parsed.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final difference = todayDay.difference(lastDay).inDays;

    if (difference <= 0) {
      return;
    }

    if (difference == 1) {
      streakDays += 1;
    } else {
      streakDays = 1;
    }

    lastStreakDate = todayKey;
  }

  Future<void> _onQuestComplete(Quest quest) async {
    if (_currentUser == null || _currentUser!.id == null) return;
    if (completedQuestIds.contains(quest.id)) return;

    final isServer = await AuthService.instance.isServerSession();
    if (isServer) {
      final token = await AuthService.instance.getToken();
      if (token != null) {
        final res = await ApiClient.completeQuest(
          token,
          questId: quest.id,
          exerciseType: quest.type,
          repsCompleted: quest.target,
          difficulty: quest.difficulty ?? 'beginner',
        );

        if (res != null && mounted) {
          setState(() {
            level = res.level;
            xp = res.xp;
            totalXp = res.totalXp;
            xpForNext = res.xpForNext;
            gems = res.gems;
            streakDays = res.streakDays;

            _applyExerciseTotals(quest);
            lastStreakDate = _normalizeDate(DateTime.now());

            completedQuestIds.add(quest.id);
          });

          await LocalStorageService.instance.markQuestCompleted(
            _currentUser!.id!,
            quest.id,
          );
          await _saveProgress();
        }
        return;
      }
    }

    setState(() {
      xp += quest.rewardXp;
      totalXp += quest.rewardXp;
      gems += quest.rewardGems;

      while (xp >= xpForNext) {
        xp -= xpForNext;
        level++;
        xpForNext = (xpForNext * 1.5).toInt();
      }

      _applyExerciseTotals(quest);
      _updateDailyStreak();
      completedQuestIds.add(quest.id);
    });

    await LocalStorageService.instance.markQuestCompleted(
      _currentUser!.id!,
      quest.id,
    );
    await _saveProgress();
  }

  void _openProfile() {
    final user = _currentUser;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          user: user,
          allQuests: _allQuests,
        ),
      ),
    );
  }

  void _openWorkout(Quest quest) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutScreen(
          quest: quest,
          onComplete: () => _onQuestComplete(quest),
        ),
      ),
    );
  }

  void _openWorldwideRankings() {
    final user = _currentUser;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorldwideRankingsScreen(
          user: user,
          currentUserExerciseTotals: const {
            RankingCategory.pushUps: 2140,
            RankingCategory.squats: 4910,
            RankingCategory.jumpingJacks: 1650,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF06B6D4),
          ),
        ),
      );
    }

    final displayName = _currentUser?.name.trim().isNotEmpty == true
        ? _currentUser!.name.trim()
        : 'Athlete';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeTopBar(
                    streakDays: streakDays,
                    gems: gems,
                    onProfileTap: _openProfile,
                  ),
                  const SizedBox(height: 20),
                  if (_selectedTabIndex == 0) ...[
                    HomeHeroCard(
                      displayName: displayName,
                      level: level,
                      xp: xp,
                      xpForNext: xpForNext,
                    ),
                    const SizedBox(height: 20),
                    const HomeDailySectionHeader(),
                  ] else ...[
                    const HomePathSectionHeader(),
                  ],
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  HomeDailyQuestsTab(
                    quests: _dailyQuests,
                    completedQuestIds: completedQuestIds,
                    onQuestTap: _openWorkout,
                  ),
                  PathScreen(
                    quests: _pathQuests,
                    completedQuestIds: completedQuestIds,
                    onQuestTap: _openWorkout,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SafeArea(
                top: false,
                child: _HomeBottomDock(
                  selectedIndex: _selectedTabIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  onLeaderboardTap: _openWorldwideRankings,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final int streakDays;
  final int gems;
  final VoidCallback onProfileTap;

  const _HomeTopBar({
    required this.streakDays,
    required this.gems,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 48,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        _HomeTopChip(
          icon: Icons.local_fire_department_rounded,
          value: streakDays.toString(),
          iconColor: const Color(0xFFF97316),
        ),
        const SizedBox(width: 8),
        _HomeTopChip(
          icon: Icons.diamond_rounded,
          value: gems.toString(),
          iconColor: const Color(0xFFA78BFA),
        ),
        const SizedBox(width: 8),
        _RoundActionButton(
          icon: Icons.person_rounded,
          onTap: onProfileTap,
        ),
      ],
    );
  }
}

class _HomeTopChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color iconColor;

  const _HomeTopChip({
    required this.icon,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _HomeBottomDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onLeaderboardTap;

  const _HomeBottomDock({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onLeaderboardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DockIconButton(
              icon: Icons.flag_rounded,
              isSelected: selectedIndex == 0,
              onTap: () => onTabSelected(0),
              selectedBorderColor: const Color(0xFF06B6D4),
              selectedIconColor: const Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DockIconButton(
              icon: Icons.alt_route_rounded,
              isSelected: selectedIndex == 1,
              onTap: () => onTabSelected(1),
              selectedBorderColor: const Color(0xFF06B6D4),
              selectedIconColor: const Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DockIconButton(
              icon: Icons.emoji_events_rounded,
              isSelected: false,
              onTap: onLeaderboardTap,
              selectedBorderColor: const Color(0xFFFACC15),
              selectedIconColor: const Color(0xFFFACC15),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedBorderColor;
  final Color selectedIconColor;

  const _DockIconButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.selectedBorderColor,
    required this.selectedIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectedBorderColor : const Color(0xFF334155),
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? selectedIconColor : const Color(0xFF94A3B8),
          size: 22,
        ),
      ),
    );
  }
}