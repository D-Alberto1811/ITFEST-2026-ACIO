import 'package:flutter/material.dart';

import '../config/storage_config.dart';
import '../models/app_user.dart';
import '../models/player_progress.dart';
import '../models/quest.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
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

  String _storageLabel() {
    if (isSqliteMode) {
      return 'SQLite (local)';
    }
    return 'Server auth + local SQLite progress';
  }

  String _storageDetails() {
    if (isSqliteMode) {
      return 'User account and app progress are stored locally in SQLite.';
    }
    return 'Account authentication is stored on the server. App progress is currently stored locally in SQLite.';
  }

  @override
  Widget build(BuildContext context) {
    final completedQuests = widget.allQuests
        .where((q) => _completedQuestIds.contains(q.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Account Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF06B6D4),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 16),
                  _buildStorageCard(),
                  const SizedBox(height: 16),
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildQuestCard(
                    title: 'Completed Quests',
                    subtitle:
                        '${completedQuests.length} / ${widget.allQuests.length} completed',
                    quests: completedQuests,
                    emptyText: 'No completed quests yet.',
                  ),
                  const SizedBox(height: 16),
                  _buildQuestCard(
                    title: 'All Quests',
                    subtitle: '${widget.allQuests.length} total quests',
                    quests: widget.allQuests,
                    completedIds: _completedQuestIds,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Center(
              child: Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provider: ${widget.user.authProvider}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(
              _storageLabel(),
              style: const TextStyle(
                color: Color(0xFF06B6D4),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _storageDetails(),
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _progress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStatTile('Level', '${progress?.level ?? 1}'),
              _buildStatTile('XP', '${progress?.xp ?? 0}'),
              _buildStatTile('XP For Next', '${progress?.xpForNext ?? 100}'),
              _buildStatTile('Gems', '${progress?.gems ?? 0}'),
              _buildStatTile('Streak Days', '${progress?.streakDays ?? 0}'),
              _buildStatTile(
                'Updated At',
                progress?.updatedAt.isNotEmpty == true
                    ? progress!.updatedAt
                    : '-',
                wide: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String title, String value, {bool wide = false}) {
    return Container(
      width: wide ? double.infinity : 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard({
    required String title,
    required String subtitle,
    required List<Quest> quests,
    Set<int>? completedIds,
    String? emptyText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          if (quests.isEmpty)
            Text(
              emptyText ?? 'No data.',
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            )
          else
            ...quests.map(
              (quest) {
                final isCompleted = completedIds?.contains(quest.id) ?? true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF334155),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        quest.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quest.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              quest.desc,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${quest.rewardXp} XP',
                            style: const TextStyle(
                              color: Color(0xFF06B6D4),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '+${quest.rewardGems} 💎',
                            style: const TextStyle(
                              color: Color(0xFFA78BFA),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCompleted ? 'Completed' : 'Not completed',
                            style: TextStyle(
                              color: isCompleted
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}