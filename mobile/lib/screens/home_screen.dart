import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/achievements_data.dart';
import '../data/quest_data.dart';
import '../models/achievement.dart';
import '../models/app_user.dart';
import '../models/player_progress.dart';
import '../models/quest.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/home/home_daily_quests_tab.dart';
import '../widgets/home/home_hero_card.dart';
import '../widgets/home/home_section_headers.dart';
import 'path_screen.dart';
import 'profile_screen.dart';
import 'stretching_screen.dart';
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
  int bestStreakDays = 0;

  int totalPushups = 0;
  int totalSquats = 0;
  int totalJumpingJacks = 0;
  int totalWorkoutsCompleted = 0;
  int totalDailyChallengesCompleted = 0;
  String? lastStreakDate;

  Set<int> completedQuestIds = <int>{};

  List<_HomeNotificationItem> _notifications = [];

  late final List<Quest> _pathQuests = buildPathQuests();
  List<Quest> get _dailyQuests => dailyQuests;
  List<Quest> get _allQuests => getAllQuests();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndProgress();
  }

  String _notificationsStorageKey(int userId) {
    return 'home_notifications_user_$userId';
  }

  String _welcomeNotificationKey(int userId) {
    return 'welcome_notification_created_user_$userId';
  }

  Future<List<_HomeNotificationItem>> _loadNotificationsForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsStorageKey(userId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => _HomeNotificationItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistNotificationsForUser(
    int userId,
    List<_HomeNotificationItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notificationsStorageKey(userId),
      jsonEncode(items.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> _addNotification({
    required String title,
    required String message,
  }) async {
    final user = _currentUser;
    if (user == null || user.id == null) return;

    final newItem = _HomeNotificationItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      message: message,
      createdAt: DateTime.now().toIso8601String(),
      isRead: false,
    );

    final updated = [newItem, ..._notifications];

    if (!mounted) return;
    setState(() {
      _notifications = updated;
    });

    await _persistNotificationsForUser(user.id!, updated);
  }

  Future<void> _markNotificationsAsRead() async {
    final user = _currentUser;
    if (user == null || user.id == null) return;

    final updated = _notifications
        .map((e) => e.copyWith(isRead: true))
        .toList();

    if (!mounted) return;
    setState(() {
      _notifications = updated;
    });

    await _persistNotificationsForUser(user.id!, updated);
  }

  Future<void> _ensureWelcomeNotificationForUser(int userId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyCreated = prefs.getBool(_welcomeNotificationKey(userId)) ?? false;

    if (alreadyCreated) return;

    final welcomeItem = _HomeNotificationItem(
      id: 'welcome_$userId',
      title: 'Welcome!',
      message: 'Welcome $name! Your account is ready. Let�s start training.',
      createdAt: DateTime.now().toIso8601String(),
      isRead: false,
    );

    final updated = [welcomeItem, ..._notifications];

    if (mounted) {
      setState(() {
        _notifications = updated;
      });
    }

    await _persistNotificationsForUser(userId, updated);
    await prefs.setBool(_welcomeNotificationKey(userId), true);
  }

  List<Achievement> _getUnlockedAchievementsFromProgress({
  required int levelValue,
  required int xpValue,
  required int totalXpValue,
  required int xpForNextValue,
  required int gemsValue,
  required int streakDaysValue,
  required int totalPushupsValue,
  required int totalSquatsValue,
  required int totalJumpingJacksValue,
  required String? lastStreakDateValue,
}) {
  final userId = _currentUser?.id ?? 0;

  final tempProgress = PlayerProgress(
    userId: userId,
    level: levelValue,
    xp: xpValue,
    totalXp: totalXpValue,
    xpForNext: xpForNextValue,
    gems: gemsValue,
    streakDays: streakDaysValue,
    bestStreakDays: bestStreakDays > streakDaysValue
        ? bestStreakDays
        : streakDaysValue,
    totalPushups: totalPushupsValue,
    totalSquats: totalSquatsValue,
    totalJumpingJacks: totalJumpingJacksValue,
    totalWorkoutsCompleted: totalWorkoutsCompleted,
    totalDailyChallengesCompleted: totalDailyChallengesCompleted,
    lastStreakDate: lastStreakDateValue,
    updatedAt: DateTime.now().toIso8601String(),
  );

  return achievementCatalog
      .where((achievement) => achievement.isUnlocked(tempProgress))
      .toList();
}

  Future<void> _addAchievementNotifications({
    required List<Achievement> beforeAchievements,
    required List<Achievement> afterAchievements,
  }) async {
    final beforeTitles = beforeAchievements.map((e) => e.title).toSet();
    final newlyUnlocked = afterAchievements
        .where((achievement) => !beforeTitles.contains(achievement.title))
        .toList();

    for (final achievement in newlyUnlocked) {
      await _addNotification(
        title: 'Achievement unlocked',
        message: 'You unlocked "${achievement.title}".',
      );
    }
  }

  int get _unreadNotificationCount =>
      _notifications.where((e) => !e.isRead).length;

  Future<void> _openNotificationsSheet() async {
    await _markNotificationsAsRead();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF111827),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF334155)),
              left: BorderSide(color: Color(0xFF334155)),
              right: BorderSide(color: Color(0xFF334155)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_notifications.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Text(
                      'No notifications yet.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.message,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadCurrentUserAndProgress() async {
    try {
      final user = await AuthService.instance.getCurrentUser();

      if (user != null) {
        final localProgress =
            await LocalStorageService.instance.getOrCreateProgress(user.id!);

        final localNotifications = await _loadNotificationsForUser(user.id!);

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

                bestStreakDays = localProgress.bestStreakDays > progressRes.streakDays
                    ? localProgress.bestStreakDays
                    : progressRes.streakDays;
                totalPushups = localProgress.totalPushups;
                totalSquats = localProgress.totalSquats;
                totalJumpingJacks = localProgress.totalJumpingJacks;
                totalWorkoutsCompleted = localProgress.totalWorkoutsCompleted > 0
                    ? localProgress.totalWorkoutsCompleted
                    : progressRes.completedQuestIds.length;
                totalDailyChallengesCompleted =
                    localProgress.totalDailyChallengesCompleted > 0
                        ? localProgress.totalDailyChallengesCompleted
                        : progressRes.completedQuestIds
                            .where((questId) =>
                                _dailyQuests.any((quest) => quest.id == questId))
                            .length;
                lastStreakDate = localProgress.lastStreakDate;

                _notifications = localNotifications;
                _isLoadingUser = false;
              });

              await _ensureWelcomeNotificationForUser(
                user.id!,
                user.name.trim().isEmpty ? 'Athlete' : user.name.trim(),
              );
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
          bestStreakDays = progress.bestStreakDays > progress.streakDays
              ? progress.bestStreakDays
              : progress.streakDays;
          totalPushups = progress.totalPushups;
          totalSquats = progress.totalSquats;
          totalJumpingJacks = progress.totalJumpingJacks;
          totalWorkoutsCompleted = progress.totalWorkoutsCompleted > 0
              ? progress.totalWorkoutsCompleted
              : questIds.length;
          totalDailyChallengesCompleted =
              progress.totalDailyChallengesCompleted > 0
                  ? progress.totalDailyChallengesCompleted
                  : questIds
                      .where((questId) =>
                          _dailyQuests.any((quest) => quest.id == questId))
                      .length;
          lastStreakDate = progress.lastStreakDate;
          _notifications = localNotifications;
          _isLoadingUser = false;
        });

        await _ensureWelcomeNotificationForUser(
          user.id!,
          user.name.trim().isEmpty ? 'Athlete' : user.name.trim(),
        );
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
      bestStreakDays: bestStreakDays,
      totalPushups: totalPushups,
      totalSquats: totalSquats,
      totalJumpingJacks: totalJumpingJacks,
      totalWorkoutsCompleted: totalWorkoutsCompleted,
      totalDailyChallengesCompleted: totalDailyChallengesCompleted,
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

  bool _isDailyChallenge(Quest quest) {
    return _dailyQuests.any((dailyQuest) => dailyQuest.id == quest.id);
  }

  void _applyActivityTotals(Quest quest) {
    totalWorkoutsCompleted += 1;

    if (_isDailyChallenge(quest)) {
      totalDailyChallengesCompleted += 1;
    }
  }

  void _updateBestStreak() {
    if (streakDays > bestStreakDays) {
      bestStreakDays = streakDays;
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

    final previousLevel = level;
    final previousStreak = streakDays;

    final achievementsBefore = _getUnlockedAchievementsFromProgress(
      levelValue: level,
      xpValue: xp,
      totalXpValue: totalXp,
      xpForNextValue: xpForNext,
      gemsValue: gems,
      streakDaysValue: streakDays,
      totalPushupsValue: totalPushups,
      totalSquatsValue: totalSquats,
      totalJumpingJacksValue: totalJumpingJacks,
      lastStreakDateValue: lastStreakDate,
    );

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
            _applyActivityTotals(quest);
            lastStreakDate = _normalizeDate(DateTime.now());
            _updateBestStreak();

            completedQuestIds.add(quest.id);
          });

          await LocalStorageService.instance.markQuestCompleted(
            _currentUser!.id!,
            quest.id,
          );
          await _saveProgress();

          await _addNotification(
            title: 'Quest completed',
            message:
                'You finished "${quest.title}" and earned ${quest.rewardXp} XP + ${quest.rewardGems} gems.',
          );

          if (level > previousLevel) {
            await _addNotification(
              title: 'Level up',
              message: 'Nice work! You reached level $level.',
            );
          }

          if (streakDays > previousStreak) {
            await _addNotification(
              title: 'Streak updated',
              message:
                  'Your streak is now $streakDays day${streakDays == 1 ? '' : 's'}.',
            );
          }

          final achievementsAfter = _getUnlockedAchievementsFromProgress(
            levelValue: level,
            xpValue: xp,
            totalXpValue: totalXp,
            xpForNextValue: xpForNext,
            gemsValue: gems,
            streakDaysValue: streakDays,
            totalPushupsValue: totalPushups,
            totalSquatsValue: totalSquats,
            totalJumpingJacksValue: totalJumpingJacks,
            lastStreakDateValue: lastStreakDate,
          );

          await _addAchievementNotifications(
            beforeAchievements: achievementsBefore,
            afterAchievements: achievementsAfter,
          );
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
      _applyActivityTotals(quest);
      _updateDailyStreak();
      _updateBestStreak();
      completedQuestIds.add(quest.id);
    });

    await LocalStorageService.instance.markQuestCompleted(
      _currentUser!.id!,
      quest.id,
    );
    await _saveProgress();

    await _addNotification(
      title: 'Quest completed',
      message:
          'You finished "${quest.title}" and earned ${quest.rewardXp} XP + ${quest.rewardGems} gems.',
    );

    if (level > previousLevel) {
      await _addNotification(
        title: 'Level up',
        message: 'Nice work! You reached level $level.',
      );
    }

    if (streakDays > previousStreak) {
      await _addNotification(
        title: 'Streak updated',
        message: 'Your streak is now $streakDays day${streakDays == 1 ? '' : 's'}.',
      );
    }

    final achievementsAfter = _getUnlockedAchievementsFromProgress(
      levelValue: level,
      xpValue: xp,
      totalXpValue: totalXp,
      xpForNextValue: xpForNext,
      gemsValue: gems,
      streakDaysValue: streakDays,
      totalPushupsValue: totalPushups,
      totalSquatsValue: totalSquats,
      totalJumpingJacksValue: totalJumpingJacks,
      lastStreakDateValue: lastStreakDate,
    );

    await _addAchievementNotifications(
      beforeAchievements: achievementsBefore,
      afterAchievements: achievementsAfter,
    );
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

  void _openStretching() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StretchingScreen(),
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
          currentUserExerciseTotals: {
            RankingCategory.pushUps: totalPushups,
            RankingCategory.squats: totalSquats,
            RankingCategory.jumpingJacks: totalJumpingJacks,
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
                    unreadNotifications: _unreadNotificationCount,
                    onNotificationsTap: _openNotificationsSheet,
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
                  onStretchTap: _openStretching,
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
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  const _HomeTopBar({
    required this.streakDays,
    required this.gems,
    required this.unreadNotifications,
    required this.onNotificationsTap,
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
        _TopIconButtonWithBadge(
          icon: Icons.notifications_none_rounded,
          badgeCount: unreadNotifications,
          onTap: onNotificationsTap,
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

class _TopIconButtonWithBadge extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _TopIconButtonWithBadge({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF0F172A), width: 2),
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeBottomDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onStretchTap;
  final VoidCallback onLeaderboardTap;

  const _HomeBottomDock({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onStretchTap,
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
              icon: Icons.self_improvement_rounded,
              isSelected: false,
              onTap: onStretchTap,
              selectedBorderColor: const Color(0xFF8B5CF6),
              selectedIconColor: const Color(0xFF8B5CF6),
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

class _HomeNotificationItem {
  final String id;
  final String title;
  final String message;
  final String createdAt;
  final bool isRead;

  const _HomeNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  _HomeNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? createdAt,
    bool? isRead,
  }) {
    return _HomeNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  factory _HomeNotificationItem.fromMap(Map<String, dynamic> map) {
    return _HomeNotificationItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      isRead: map['isRead'] == true,
    );
  }
}