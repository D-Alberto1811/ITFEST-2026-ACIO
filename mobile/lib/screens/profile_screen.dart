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
import 'login_screen.dart';

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
  static const Color _bg = Color(0xFF0F172A);
  static const Color _panel = Color(0xFF111827);
  static const Color _card = Color(0xFF1E293B);
  static const Color _border = Color(0xFF334155);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _text = Colors.white;
  static const Color _accent = Color(0xFF06B6D4);
  static const Color _gold = Color(0xFFFACC15);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _orange = Color(0xFFF97316);
  static const Color _purple = Color(0xFFA78BFA);

  bool _isLoading = true;

  PlayerProgress? _progress;
  Set<int> _completedQuestIds = <int>{};

  late String _displayName;

  @override
  void initState() {
    super.initState();
    _displayName = widget.user.name;
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

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openEditProfileSheet() {
    final controller = TextEditingController(text: _displayName);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: _border),
                left: BorderSide(color: _border),
                right: BorderSide(color: _border),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Edit profile',
                      style: TextStyle(
                        color: _text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Display name',
                      style: TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: const TextStyle(color: _muted),
                        filled: true,
                        fillColor: _card,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _accent),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _danger),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _danger),
                        ),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Please enter a name';
                        if (text.length < 2) return 'Name is too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        widget.user.email,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: _text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;

                              setState(() {
                                _displayName = controller.text.trim();
                              });

                              Navigator.pop(context);

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated'),
                                  backgroundColor: Color(0xFF1E293B),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: _bg,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: _border),
              left: BorderSide(color: _border),
              right: BorderSide(color: _border),
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
                    color: _border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: _text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildSettingsTile(
                  icon: Icons.edit_rounded,
                  iconColor: _accent,
                  title: 'Edit profile',
                  subtitle: 'Change your display name',
                  onTap: () {
                    Navigator.pop(context);
                    _openEditProfileSheet();
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: _danger,
                  title: 'Log out',
                  subtitle: 'Sign out from your account',
                  onTap: () async {
                    Navigator.pop(context);
                    await _logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _muted,
            ),
          ],
        ),
      ),
    );
  }

  String get _usernameSlug {
    final value = _displayName.trim().toLowerCase().replaceAll(' ', '');
    return value.isEmpty ? 'athlete' : value;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress ?? PlayerProgress.initial(widget.user.id ?? 0);
    final completedQuestCount = _completedQuestIds.length;

    return Scaffold(
      backgroundColor: _bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _accent,
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildTopHeader(progress),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIdentitySection(),
                            const SizedBox(height: 22),
                            _buildStatsRow(progress),
                            const SizedBox(height: 22),
                            _buildProgressCard(progress),
                            const SizedBox(height: 22),
                            _buildAchievementsCard(
                              progress: progress,
                              completedQuestCount: completedQuestCount,
                            ),
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

  Widget _buildTopHeader(PlayerProgress progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF111827),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _TopCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              _TopCircleButton(
                icon: Icons.settings_outlined,
                onTap: _openSettingsSheet,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _card,
              border: Border.all(color: _border, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 68,
              color: _accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Level ${progress.level} athlete',
            style: const TextStyle(
              fontSize: 14,
              color: _muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROFILE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _muted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: const Icon(
                  Icons.alternate_email_rounded,
                  color: _accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '@$_usernameSlug',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  color: _gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.user.email,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(PlayerProgress progress) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: '${progress.streakDays}',
            label: 'Streak',
            icon: Icons.local_fire_department_rounded,
            iconColor: _orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: '${progress.totalXp}',
            label: 'Total XP',
            icon: Icons.star_rounded,
            iconColor: _gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: '${progress.gems}',
            label: 'Gems',
            icon: Icons.diamond_rounded,
            iconColor: _purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(PlayerProgress progress) {
    final currentXp = progress.xp;
    final xpForNext = progress.xpForNext;
    final progressValue = xpForNext == 0 ? 0.0 : currentXp / xpForNext;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LEVEL PROGRESS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _muted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoPill(
                icon: Icons.fitness_center_rounded,
                iconColor: _accent,
                text: 'Level ${progress.level}',
              ),
              const SizedBox(width: 10),
              _buildInfoPill(
                icon: Icons.emoji_events_rounded,
                iconColor: _gold,
                text: '${_completedQuestIds.length} quests',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: _bg,
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currentXp / $xpForNext XP to next level',
            style: const TextStyle(
              fontSize: 12,
              color: _muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard({
    required PlayerProgress progress,
    required int completedQuestCount,
  }) {
    final previewAchievements = getPreviewAchievements(
      progress,
      limit: 4,
    );
    final unlockedCount = getUnlockedAchievementCount(progress);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ACHIEVEMENTS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _muted,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _openAchievements(progress),
                child: const Row(
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$unlockedCount / ${achievementCatalog.length} unlocked',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
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
        color: isUnlocked ? _card : const Color(0xFF172033),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUnlocked ? _accent.withOpacity(0.25) : _border,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 60,
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
              color: isUnlocked ? _text : _muted,
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
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
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