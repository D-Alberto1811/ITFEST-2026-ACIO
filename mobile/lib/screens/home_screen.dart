import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/quest.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
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
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.instance.getCurrentUser();

      if (!mounted) return;

      setState(() {
        _currentUser = user;
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
        backgroundColor: Color(0xFF07111F),
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
      backgroundColor: const Color(0xFF07111F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B1220),
              Color(0xFF07111F),
              Color(0xFF050B16),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 22),
                      _buildWelcomeCard(displayName),
                      const SizedBox(height: 22),
                      _buildSectionHeader(),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                sliver: SliverList.builder(
                  itemCount: quests.length,
                  itemBuilder: (context, index) {
                    final quest = quests[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _QuestCard(
                        quest: quest,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkoutScreen(
                                quest: quest,
                                onComplete: () => _onQuestComplete(
                                  quest.rewardXp,
                                  quest.rewardGems,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          height: 52,
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const Spacer(),
        _buildPillChip(
          icon: Icons.local_fire_department_rounded,
          value: streakDays.toString(),
          iconColor: const Color(0xFFF97316),
        ),
        const SizedBox(width: 10),
        _buildPillChip(
          icon: Icons.diamond_rounded,
          value: gems.toString(),
          iconColor: const Color(0xFFA855F7),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showAccountSheet,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E293B)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
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

  Widget _buildWelcomeCard(String displayName) {
    final progress = xpForNext == 0 ? 0.0 : (xp / xpForNext).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF132238),
            Color(0xFF0B1728),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF1E293B),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF020617).withOpacity(0.45),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF22C55E),
                  Color(0xFF06B6D4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.20),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
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
                  'Welcome back, $displayName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Stay consistent and crush today’s training quests.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMiniStat(
                      label: 'Level',
                      value: '$level',
                    ),
                    const SizedBox(width: 10),
                    _buildMiniStat(
                      label: 'XP',
                      value: '$xp/$xpForNext',
                    ),
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
                      Color(0xFF22C55E),
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

  Widget _buildSectionHeader() {
    return Row(
      children: const [
        Text(
          'Today’s Quests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Spacer(),
        Text(
          'Daily goals',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPillChip({
    required IconData icon,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
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

  Widget _buildMiniStat({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
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

  Widget _buildAccountStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onTap;

  const _QuestCard({
    required this.quest,
    required this.onTap,
  });

  Color _accentColor() {
    switch (quest.type) {
      case 'pushup':
        return const Color(0xFF22C55E);
      case 'squat':
        return const Color(0xFFF97316);
      case 'jumping_jack':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1E293B)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: accent.withOpacity(0.12),
                  border: Border.all(color: accent.withOpacity(0.25)),
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
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quest.desc,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.3,
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
                            color: const Color(0xFFA855F7),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 20,
                ),
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
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
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