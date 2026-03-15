import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/storage_config.dart';
import '../models/app_user.dart';
import '../models/player_progress.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

enum RankingCategory {
  pushUps('Push-Ups', 'pushups'),
  squats('Squats', 'squats'),
  jumpingJacks('Jumping Jacks', 'jumping_jacks');

  final String label;
  final String apiKey;

  const RankingCategory(this.label, this.apiKey);
}

class WorldwideRankingsScreen extends StatefulWidget {
  final AppUser user;
  final Map<RankingCategory, int>? currentUserExerciseTotals;

  const WorldwideRankingsScreen({
    super.key,
    required this.user,
    this.currentUserExerciseTotals,
  });

  @override
  State<WorldwideRankingsScreen> createState() =>
      _WorldwideRankingsScreenState();
}

class _WorldwideRankingsScreenState extends State<WorldwideRankingsScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  RankingCategory _selectedCategory = RankingCategory.pushUps;

  late final RankingsRepository _repository;

  LeaderboardSnapshot? _snapshot;
  PersonalRankingsSummary? _personalSummary;

  @override
  void initState() {
    super.initState();
    _repository = isServerMode
        ? _ServerRankingsRepository(
            currentUser: widget.user,
            currentUserTotals: widget.currentUserExerciseTotals,
          )
        : _SqliteRankingsRepository(
            currentUser: widget.user,
            currentUserTotals: widget.currentUserExerciseTotals,
          );
    _loadData();
  }

  Future<void> _loadData({bool showRefreshState = false}) async {
    if (showRefreshState) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _repository.getLeaderboard(_selectedCategory),
        _repository.getPersonalSummary(),
      ]);

      if (!mounted) return;

      setState(() {
        _snapshot = results[0] as LeaderboardSnapshot;
        _personalSummary = results[1] as PersonalRankingsSummary;
        _error = null;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _onCategoryChanged(RankingCategory category) async {
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
      _isLoading = true;
      _error = null;
    });

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Worldwide Rankings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadData(showRefreshState: true),
          color: const Color(0xFF06B6D4),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const Text(
                'Compare your performance with players around the world.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              _CategoryTabs(
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategoryChanged,
              ),
              const SizedBox(height: 20),
              if (_isLoading && _snapshot == null) ...[
                const _LoadingCard(),
              ] else if (_error != null) ...[
                _ErrorCard(
                  message: _error!,
                  onRetry: _loadData,
                ),
              ] else if (_snapshot != null) ...[
                _LeaderboardCard(
                  snapshot: _snapshot!,
                  isRefreshing: _isRefreshing,
                ),
                const SizedBox(height: 18),
                if (_personalSummary != null)
                  _YourRankingsCard(summary: _personalSummary!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String playerName;
  final int score;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.playerName,
    required this.score,
    required this.isCurrentUser,
  });
}

class LeaderboardSnapshot {
  final RankingCategory category;
  final List<LeaderboardEntry> topEntries;
  final LeaderboardEntry currentUserEntry;

  const LeaderboardSnapshot({
    required this.category,
    required this.topEntries,
    required this.currentUserEntry,
  });

  bool get isCurrentUserInTopTen {
    return topEntries.any((entry) => entry.isCurrentUser);
  }

  LeaderboardEntry? get previousEntry {
    if (currentUserEntry.rank <= 1) return null;

    final all = [...topEntries];
    if (!all.any((e) => e.rank == currentUserEntry.rank)) {
      all.add(currentUserEntry);
    }

    all.sort((a, b) => a.rank.compareTo(b.rank));

    for (final entry in all) {
      if (entry.rank == currentUserEntry.rank - 1) {
        return entry;
      }
    }
    return null;
  }

  int? get scoreNeededToReachPrevious {
    final previous = previousEntry;
    if (previous == null) return null;
    final difference = previous.score - currentUserEntry.score;
    return difference < 0 ? 0 : difference + 1;
  }
}

class PersonalRankingsSummary {
  final Map<RankingCategory, LeaderboardEntry> rankings;

  const PersonalRankingsSummary({
    required this.rankings,
  });
}

abstract class RankingsRepository {
  Future<LeaderboardSnapshot> getLeaderboard(RankingCategory category);
  Future<PersonalRankingsSummary> getPersonalSummary();
}

class _SqliteRankingsRepository implements RankingsRepository {
  final AppUser currentUser;
  final Map<RankingCategory, int>? currentUserTotals;

  _SqliteRankingsRepository({
    required this.currentUser,
    this.currentUserTotals,
  });

  final DatabaseService _database = DatabaseService.instance;

  @override
  Future<LeaderboardSnapshot> getLeaderboard(RankingCategory category) async {
    final users = await _database.getAllUsers();
    final entries = <LeaderboardEntry>[];

    for (final user in users) {
      if (user.id == null) continue;

      final progress = await _database.getPlayerProgress(user.id!) ??
          PlayerProgress.initial(user.id!);

      final score = _scoreFromProgress(progress, category);

      entries.add(
        LeaderboardEntry(
          rank: 0,
          playerName: _displayName(user),
          score: score,
          isCurrentUser: user.id == currentUser.id,
        ),
      );
    }

    if (!entries.any((entry) => entry.isCurrentUser)) {
      entries.add(
        LeaderboardEntry(
          rank: 0,
          playerName: _displayName(currentUser),
          score: currentUserTotals?[category] ?? 0,
          isCurrentUser: true,
        ),
      );
    }

    entries.sort((a, b) => b.score.compareTo(a.score));

    final rankedEntries = List<LeaderboardEntry>.generate(entries.length, (index) {
      final entry = entries[index];
      return LeaderboardEntry(
        rank: index + 1,
        playerName: entry.playerName,
        score: entry.score,
        isCurrentUser: entry.isCurrentUser,
      );
    });

    final currentUserEntry = rankedEntries.firstWhere(
      (entry) => entry.isCurrentUser,
      orElse: () => rankedEntries.isNotEmpty
          ? rankedEntries.first
          : LeaderboardEntry(
              rank: 1,
              playerName: _displayName(currentUser),
              score: currentUserTotals?[category] ?? 0,
              isCurrentUser: true,
            ),
    );

    return LeaderboardSnapshot(
      category: category,
      topEntries: rankedEntries.take(10).toList(),
      currentUserEntry: currentUserEntry,
    );
  }

  @override
  Future<PersonalRankingsSummary> getPersonalSummary() async {
    final results = await Future.wait<LeaderboardSnapshot>(
      RankingCategory.values.map(getLeaderboard),
    );

    return PersonalRankingsSummary(
      rankings: {
        for (final snapshot in results) snapshot.category: snapshot.currentUserEntry,
      },
    );
  }

  int _scoreFromProgress(PlayerProgress progress, RankingCategory category) {
    switch (category) {
      case RankingCategory.pushUps:
        return progress.totalPushups;
      case RankingCategory.squats:
        return progress.totalSquats;
      case RankingCategory.jumpingJacks:
        return progress.totalJumpingJacks;
    }
  }

  String _displayName(AppUser user) {
    final trimmed = user.name.trim();
    return trimmed.isEmpty ? 'Unknown Athlete' : trimmed;
  }
}

class _ServerRankingsRepository implements RankingsRepository {
  final AppUser currentUser;
  final Map<RankingCategory, int>? currentUserTotals;

  _ServerRankingsRepository({
    required this.currentUser,
    this.currentUserTotals,
  });

  @override
  Future<LeaderboardSnapshot> getLeaderboard(RankingCategory category) async {
    final token = await AuthService.instance.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing server token.');
    }

    final uri = Uri.parse(
      '$apiBaseUrl/gamification/leaderboard?category=${category.apiKey}',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Server leaderboard endpoint is not available yet. Add /gamification/leaderboard on backend.',
      );
    }

    final decoded = jsonDecode(response.body);
    final rawList = _extractEntriesList(decoded);

    final entries = <LeaderboardEntry>[];
    for (var i = 0; i < rawList.length; i++) {
      final item = Map<String, dynamic>.from(rawList[i] as Map);

      final rank = (item['rank'] as num?)?.toInt() ?? (i + 1);
      final name = (item['name'] ??
              item['player_name'] ??
              item['username'] ??
              item['display_name'] ??
              '')
          .toString();

      final scoreNum = (item['score'] ??
              item['value'] ??
              item['total'] ??
              item['count'] ??
              item['reps'] ??
              0) as num;
      final score = scoreNum.toInt();

      final userId = (item['user_id'] as num?)?.toInt();

      final isCurrent = item['is_current_user'] == true ||
          item['isCurrentUser'] == true ||
          (userId != null && currentUser.id != null && userId == currentUser.id) ||
          name.trim() == currentUser.name.trim();

      entries.add(
        LeaderboardEntry(
          rank: rank,
          playerName: name.trim().isEmpty ? 'Unknown Athlete' : name.trim(),
          score: score,
          isCurrentUser: isCurrent,
        ),
      );
    }

    if (entries.isEmpty) {
      throw Exception('No leaderboard data returned from server.');
    }

    entries.sort((a, b) => a.rank.compareTo(b.rank));

    LeaderboardEntry? currentEntry;
    for (final entry in entries) {
      if (entry.isCurrentUser) {
        currentEntry = entry;
        break;
      }
    }

    currentEntry ??= LeaderboardEntry(
      rank: entries.length + 1,
      playerName:
          currentUser.name.trim().isEmpty ? 'You' : currentUser.name.trim(),
      score: currentUserTotals?[category] ?? 0,
      isCurrentUser: true,
    );

    return LeaderboardSnapshot(
      category: category,
      topEntries: entries.take(10).toList(),
      currentUserEntry: currentEntry,
    );
  }

  @override
  Future<PersonalRankingsSummary> getPersonalSummary() async {
    final results = await Future.wait<LeaderboardSnapshot>(
      RankingCategory.values.map(getLeaderboard),
    );

    return PersonalRankingsSummary(
      rankings: {
        for (final snapshot in results) snapshot.category: snapshot.currentUserEntry,
      },
    );
  }

  List<dynamic> _extractEntriesList(dynamic decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map<String, dynamic>) {
      if (decoded['entries'] is List) return decoded['entries'] as List<dynamic>;
      if (decoded['leaderboard'] is List) {
        return decoded['leaderboard'] as List<dynamic>;
      }
      if (decoded['data'] is List) return decoded['data'] as List<dynamic>;
    }

    return const [];
  }
}

class _CategoryTabs extends StatelessWidget {
  final RankingCategory selectedCategory;
  final ValueChanged<RankingCategory> onCategorySelected;

  const _CategoryTabs({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: RankingCategory.values.map((category) {
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onCategorySelected(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF06B6D4).withOpacity(0.15)
                      : const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF06B6D4)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Text(
                  category.label,
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final LeaderboardSnapshot snapshot;
  final bool isRefreshing;

  const _LeaderboardCard({
    required this.snapshot,
    required this.isRefreshing,
  });

  Color _podiumColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFACC15);
      case 2:
        return const Color(0xFFE5E7EB);
      case 3:
        return const Color(0xFFFB923C);
      default:
        return const Color(0xFF06B6D4);
    }
  }

  IconData _categoryIcon(RankingCategory category) {
    switch (category) {
      case RankingCategory.pushUps:
        return Icons.fitness_center_rounded;
      case RankingCategory.squats:
        return Icons.accessibility_new_rounded;
      case RankingCategory.jumpingJacks:
        return Icons.directions_run_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final needed = snapshot.scoreNeededToReachPrevious;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                snapshot.category.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (isRefreshing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF06B6D4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...snapshot.topEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LeaderboardRow(
                entry: entry,
                categoryIcon: _categoryIcon(snapshot.category),
                podiumColor: _podiumColor,
              ),
            ),
          ),
          if (!snapshot.isCurrentUserInTopTen) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Color(0xFF334155)),
            ),
            _LeaderboardRow(
              entry: snapshot.currentUserEntry,
              categoryIcon: _categoryIcon(snapshot.category),
              podiumColor: _podiumColor,
            ),
            if (needed != null) ...[
              const SizedBox(height: 10),
              Text(
                '$needed more to reach #${snapshot.currentUserEntry.rank - 1}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final IconData categoryIcon;
  final Color Function(int rank) podiumColor;

  const _LeaderboardRow({
    required this.entry,
    required this.categoryIcon,
    required this.podiumColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        entry.isCurrentUser ? Colors.white : const Color(0xFFE5E7EB);
    final backgroundColor = entry.isCurrentUser
        ? const Color(0xFF06B6D4).withOpacity(0.12)
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: _RankBadge(rank: entry.rank),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.isCurrentUser
                  ? '${entry.playerName} (You)'
                  : entry.playerName,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight:
                    entry.isCurrentUser ? FontWeight.w800 : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Icon(
                categoryIcon,
                size: 18,
                color: entry.rank <= 3
                    ? podiumColor(entry.rank)
                    : const Color(0xFF06B6D4),
              ),
              const SizedBox(width: 8),
              Text(
                _formatNumber(entry.score),
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      final medal = switch (rank) {
        1 => '🥇',
        2 => '🥈',
        _ => '🥉',
      };

      return Text(
        medal,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24),
      );
    }

    return Text(
      '$rank.',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}

class _YourRankingsCard extends StatelessWidget {
  final PersonalRankingsSummary summary;

  const _YourRankingsCard({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Rankings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ...RankingCategory.values.map((category) {
            final entry = summary.rankings[category];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.label,
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    entry != null ? '#${entry.rank}' : '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF06B6D4),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function({bool showRefreshState}) onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7F1D1D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => onRetry(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}