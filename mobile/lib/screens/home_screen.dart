import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/player_progress.dart';
import '../models/quest.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUser? _currentUser;
  bool _isLoadingUser = true;

  int level = 1;
  int xp = 0;
  int xpForNext = 100;
  int gems = 0;
  int streakDays = 0;

  Set<int> completedQuestIds = <int>{};

  final List<Quest> quests = [
    Quest(
      id: 1,
      title: 'Rookie Push-ups',
      type: 'pushup',
      target: 5,
      rewardXp: 40,
      rewardGems: 2,
      icon: '💪',
      desc: 'Do 5 Push-ups',
    ),
    Quest(
      id: 2,
      title: 'Leg Day Basics',
      type: 'squat',
      target: 10,
      rewardXp: 50,
      rewardGems: 3,
      icon: '🦵',
      desc: 'Do 10 Squats',
    ),
    Quest(
      id: 3,
      title: 'Jumping Jacks Intro',
      type: 'jumping_jack',
      target: 10,
      rewardXp: 45,
      rewardGems: 2,
      icon: '🦘',
      desc: 'Do 10 Jumping Jacks',
    ),
    Quest(
      id: 4,
      title: "Warrior's Test",
      type: 'pushup',
      target: 15,
      rewardXp: 80,
      rewardGems: 5,
      icon: '⚔️',
      desc: 'Do 15 Push-ups',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndProgress();
  }

  Future<void> _loadCurrentUserAndProgress() async {
    try {
      final user = await AuthService.instance.getCurrentUser();

      if (user != null) {
        final progress =
            await LocalStorageService.instance.getOrCreateProgress(user.id!);
        final questIds =
            await LocalStorageService.instance.getCompletedQuestIds(user.id!);

        if (!mounted) return;

        setState(() {
          _currentUser = user;
          level = progress.level;
          xp = progress.xp;
          xpForNext = progress.xpForNext;
          gems = progress.gems;
          streakDays = progress.streakDays;
          completedQuestIds = questIds;
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
      xpForNext: xpForNext,
      gems: gems,
      streakDays: streakDays,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await LocalStorageService.instance.saveProgress(progress);
  }

  Future<void> _onQuestComplete(Quest quest) async {
    if (_currentUser == null || _currentUser!.id == null) return;
    if (completedQuestIds.contains(quest.id)) return;

    setState(() {
      xp += quest.rewardXp;
      gems += quest.rewardGems;

      while (xp >= xpForNext) {
        xp -= xpForNext;
        level++;
        xpForNext = (xpForNext * 1.5).toInt();
      }

      streakDays += 1;
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
          allQuests: quests,
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 20),
                    _buildHeroCard(displayName),
                    const SizedBox(height: 24),
                    const Text(
                      'Daily Quests',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Complete your daily fitness missions',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: quests.length,
                itemBuilder: (context, index) {
                  final quest = quests[index];
                  final isCompleted = completedQuestIds.contains(quest.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildQuestCard(
                      quest,
                      isCompleted: isCompleted,
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 92,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const Spacer(),
        _buildTopChip(
          icon: Icons.local_fire_department_rounded,
          value: streakDays.toString(),
          iconColor: const Color(0xFFF97316),
        ),
        const SizedBox(width: 8),
        _buildTopChip(
          icon: Icons.diamond_rounded,
          value: gems.toString(),
          iconColor: const Color(0xFFA78BFA),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _openProfile,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(String displayName) {
    final progress = xpForNext == 0 ? 0.0 : (xp / xpForNext).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF422006),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD97706)),
            ),
            child: const Center(
              child: Icon(
                Icons.fitness_center_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $displayName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ready for today’s workout quests?',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildMiniStat('Level', '$level'),
                    const SizedBox(width: 10),
                    _buildMiniStat('XP', '$xp / $xpForNext'),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFF0F172A),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF06B6D4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopChip({
    required IconData icon,
    required String value,
    required Color iconColor,
  }) {
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

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(Quest quest, {required bool isCompleted}) {
    return GestureDetector(
      onTap: isCompleted
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutScreen(
                    quest: quest,
                    onComplete: () => _onQuestComplete(quest),
                  ),
                ),
              );
            },
      child: Opacity(
        opacity: isCompleted ? 0.70 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF334155),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Center(
                  child: Text(
                    quest.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted ? 'Completed' : quest.desc,
                      style: TextStyle(
                        color: isCompleted
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRewardTag(
                          icon: Icons.bolt_rounded,
                          text: '+${quest.rewardXp} XP',
                          color: const Color(0xFF06B6D4),
                        ),
                        const SizedBox(width: 8),
                        if (quest.rewardGems > 0)
                          _buildRewardTag(
                            icon: Icons.diamond_rounded,
                            text: '+${quest.rewardGems}',
                            color: const Color(0xFFA78BFA),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
                color: isCompleted
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF64748B),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}