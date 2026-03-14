import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/player_progress.dart';
import '../models/quest.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import 'login_screen.dart';
import 'path_screen.dart';
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

  int _selectedTabIndex = 0;

  int level = 1;
  int xp = 0;
  int xpForNext = 100;
  int gems = 0;
  int streakDays = 0;
  int totalXp = 0;

  Set<int> completedQuestIds = <int>{};

  final List<Quest> dailyQuests = [
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

  late final List<Quest> pathQuests = _buildPathQuests();

  List<Quest> get allQuests => [...dailyQuests, ...pathQuests];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndProgress();
  }

  List<Quest> _buildPathQuests() {
    final List<Quest> result = [];
    int id = 100;

    final difficulties = [
      _DifficultyPreset(
        label: 'Beginner',
        xp: 30,
        gems: 1,
        targets: [5, 8, 10],
      ),
      _DifficultyPreset(
        label: 'Intermediate',
        xp: 45,
        gems: 2,
        targets: [12, 15, 18],
      ),
      _DifficultyPreset(
        label: 'Medium',
        xp: 60,
        gems: 3,
        targets: [20, 24, 28],
      ),
      _DifficultyPreset(
        label: 'Hard',
        xp: 85,
        gems: 4,
        targets: [30, 35, 40],
      ),
      _DifficultyPreset(
        label: 'Extreme',
        xp: 120,
        gems: 6,
        targets: [45, 50, 60],
      ),
    ];

    const exerciseTypes = ['pushup', 'squat', 'jumping_jack'];
    const exerciseTitles = ['Push-up', 'Squat', 'Jumping Jack'];
    const exerciseIcons = ['💪', '🦵', '🦘'];

    for (int difficultyIndex = 0; difficultyIndex < difficulties.length; difficultyIndex++) {
      final preset = difficulties[difficultyIndex];

      for (int i = 0; i < 10; i++) {
        final exerciseIndex = i % 3;
        final type = exerciseTypes[exerciseIndex];
        final exerciseTitle = exerciseTitles[exerciseIndex];
        final icon = exerciseIcons[exerciseIndex];
        final target = preset.targets[exerciseIndex] + ((i ~/ 3) * 2);

        result.add(
          Quest(
            id: id++,
            title: '${preset.label} $exerciseTitle ${i + 1}',
            type: type,
            target: target,
            rewardXp: preset.xp + (i * 3),
            rewardGems: preset.gems + (i ~/ 4),
            icon: icon,
            desc: 'Complete $target ${exerciseTitle.toLowerCase()}s',
          ),
        );
      }
    }

    return result;
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

  void _onQuestComplete(int rewardXp, int rewardGems) {
    setState(() {
      xp += rewardXp;
      gems += rewardGems;

    while (xp >= xpForNext) {
      xp -= xpForNext;
      level++;
      xpForNext = (xpForNext * 1.5).toInt();
    }

      streakDays += 1;
    });
  }

  void _showAccountSheet() {
    final name = _currentUser?.name.trim().isNotEmpty == true
        ? _currentUser!.name.trim()
        : 'Athlete';

    final email = _currentUser?.email ?? 'No email available';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF22C55E),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withOpacity(0.20),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildAccountStatCard(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Streak',
                        value: '$streakDays',
                        color: const Color(0xFFF97316),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAccountStatCard(
                        icon: Icons.diamond_rounded,
                        label: 'Currency',
                        value: '$gems',
                        color: const Color(0xFFA855F7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAccountStatCard(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Level',
                        value: '$level',
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAccountStatCard(
                        icon: Icons.bolt_rounded,
                        label: 'XP',
                        value: '$xp / $xpForNext',
                        color: const Color(0xFF06B6D4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  _buildTopBar(),
                  const SizedBox(height: 20),
                  if (_selectedTabIndex == 0) ...[
                    _buildHeroCard(displayName),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Daily Quests',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Complete your daily fitness missions',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Quest Path',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Tap the unlocked circles to start the next mission.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _DailyQuestsTab(
                    quests: dailyQuests,
                    completedQuestIds: completedQuestIds,
                    onQuestTap: _openWorkout,
                  ),
                  PathScreen(
                    quests: pathQuests,
                    completedQuestIds: completedQuestIds,
                    onQuestTap: _openWorkout,
                  ),
                ],
              ),
            ),
            _buildBottomTabs(),
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

  Widget _buildBottomTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BottomTabButton(
              label: 'Quests',
              icon: Icons.flag_rounded,
              isSelected: _selectedTabIndex == 0,
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BottomTabButton(
              label: 'Path',
              icon: Icons.alt_route_rounded,
              isSelected: _selectedTabIndex == 1,
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
              },
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
}

class _DifficultyPreset {
  final String label;
  final int xp;
  final int gems;
  final List<int> targets;

  const _DifficultyPreset({
    required this.label,
    required this.xp,
    required this.gems,
    required this.targets,
  });
}

class _DailyQuestsTab extends StatelessWidget {
  final List<Quest> quests;
  final Set<int> completedQuestIds;
  final ValueChanged<Quest> onQuestTap;

  const _DailyQuestsTab({
    required this.quests,
    required this.completedQuestIds,
    required this.onQuestTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        final isCompleted = completedQuestIds.contains(quest.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _DailyQuestCard(
            quest: quest,
            isCompleted: isCompleted,
            onTap: isCompleted ? null : () => onQuestTap(quest),
          ),
        );
      },
    );
  }
}

class _DailyQuestCard extends StatelessWidget {
  final Quest quest;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _DailyQuestCard({
    required this.quest,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                        _RewardTag(
                          icon: Icons.bolt_rounded,
                          text: '+${quest.rewardXp} XP',
                          color: const Color(0xFF06B6D4),
                        ),
                        const SizedBox(width: 8),
                        if (quest.rewardGems > 0)
                          _RewardTag(
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
}

class _RewardTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _RewardTag({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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

class _BottomTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
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
            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF334155),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}