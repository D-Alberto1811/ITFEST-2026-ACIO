import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/storage_config.dart';
import '../models/app_user.dart';
import '../models/player_progress.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

/// Worldwide rankings screen inspired by the attached mockup:
/// - title + subtitle
/// - 3 tabs: Push-Ups / Squats / Jumping Jacks
/// - top 10 visible immediately
/// - current user shown under the leaderboard when outside top 10
/// - secondary card: user's ranking across all exercises
///
/// Current behavior:
/// - In SQLite mode, the screen reads real data from local SQLite.
/// - In server mode, the screen expects a backend leaderboard endpoint.
///
/// Expected server response shapes supported:
/// 1) { "entries": [ { "rank": 1, "name": "...", "score": 1000, "is_current_user": false } ] }
/// 2) { "leaderboard": [ ... ] }
/// 3) [ { "rank": 1, "name": "...", "score": 1000 } ]
class WorldwideRankingsScreen extends StatefulWidget {
  final AppUser user;

  /// Optional fallback values for the current user.
  final Map<RankingCategory, int>? currentUserExerciseTotals;

  const WorldwideRankingsScreen({
    super.key,
    required this.user,
    required this.currentUserExerciseTotals,
  });

  @override
  State<WorldwideRankingsScreen> createState() =>
      _WorldwideRankingsScreenState();
}

class _WorldwideRankingsScreenState extends State<WorldwideRankingsScreen> {
  static const Color _bg = Color(0xFF0F172A);
  static const Color _panel = Color(0xFF111827);
  static const Color _card = Color(0xFF1E293B);
  static const Color _border = Color(0xFF334155);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _text = Colors.white;
  static const Color _accent = Color(0xFF06B6D4);
  static const Color _gold = Color(0xFFFACC15);
  static const Color _silver = Color(0xFFE5E7EB);
  static const Color _bronze = Color(0xFFFB923C);

  RankingCategory _selectedCategory = RankingCategory.pushUps;

  late final Map<RankingCategory, List<_RankingEntry>> _cachedRankings;
  late final Map<RankingCategory, _RankingEntry> _currentUserEntries;

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
    }

    try {
      final results = await Future.wait([
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

  void _buildRankingsOnce() {
    _cachedRankings = {};
    _currentUserEntries = {};

    for (final category in RankingCategory.values) {
      final rankings = _generateRankingsForCategory(category);
      _cachedRankings[category] = rankings;
      _currentUserEntries[category] =
          rankings.firstWhere((entry) => entry.isCurrentUser);
    }
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
      final fallbackScore = currentUserTotals?[category] ?? 0;
      entries.add(
        LeaderboardEntry(
          rank: 0,
          playerName: _displayName(currentUser),
          score: fallbackScore,
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

  @override
  Future<PersonalRankingsSummary> getPersonalSummary() async {
    final results = await Future.wait(
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
      final score = (item['score'] ??
                  item['value'] ??
                  item['total'] ??
                  item['count'] ??
                  item['reps'] ??
                  0)
              as num? ??
          0;
      final userId = (item['user_id'] as num?)?.toInt();
      final isCurrent = item['is_current_user'] == true ||
          item['isCurrentUser'] == true ||
          (userId != null && currentUser.id != null && userId == currentUser.id) ||
          name.trim() == currentUser.name.trim();

      entries.add(
        LeaderboardEntry(
          rank: rank,
          playerName: name.trim().isEmpty ? 'Unknown Athlete' : name.trim(),
          score: score.toInt(),
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
      playerName: currentUser.name.trim().isEmpty ? 'You' : currentUser.name.trim(),
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
    final results = await Future.wait(
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
      final entries = decoded['entries'];
      if (entries is List) return entries;

      final leaderboard = decoded['leaderboard'];
      if (leaderboard is List) return leaderboard;

      final data = decoded['data'];
      if (data is List) return data;
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 20),
                  _buildCurrentUserCard(currentUserEntry),
                  const SizedBox(height: 18),
                  _buildCategorySelector(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: IndexedStack(
                index: RankingCategory.values.indexOf(_selectedCategory),
                children: RankingCategory.values.map((category) {
                  return _buildRankingList(
                    category,
                    _cachedRankings[category]!,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard(_RankingEntry userEntry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _card,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: Center(
              child: Text(
                '#${userEntry.rank}',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your position',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEntry.name,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${userEntry.score} ${_categoryTitle(_selectedCategory).toLowerCase()}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _categoryIcon(_selectedCategory),
            color: _accent,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final textColor = entry.isCurrentUser ? Colors.white : const Color(0xFFE5E7EB);
    final backgroundColor = entry.isCurrentUser
        ? const Color(0xFF06B6D4).withOpacity(0.12)
        : Colors.transparent;

  Widget _buildCategorySelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: RankingCategory.values.map((category) {
          final isSelected = _selectedCategory == category;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: category != RankingCategory.values.last ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  if (_selectedCategory == category) return;
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _card : _bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _accent : _border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _categoryIcon(category),
                        color: isSelected ? _accent : _muted,
                        size: 20,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _categoryTitle(category),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? _text : _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankingList(
    RankingCategory category,
    List<_RankingEntry> entries,
  ) {
    return ListView.builder(
      key: PageStorageKey('rankings_${category.name}'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRankingTile(entry),
        );
      },
    );
  }

  Widget _buildRankingTile(_RankingEntry entry) {
    final highlight = entry.isCurrentUser;
    final isTopThree = entry.rank <= 3;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? _card : _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? _accent
              : isTopThree
                  ? _podiumColor(entry.rank).withOpacity(0.55)
                  : _border,
          width: highlight ? 1.4 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: _accent.withOpacity(0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isTopThree ? _podiumColor(entry.rank) : _border,
              ),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  color: isTopThree ? _podiumColor(entry.rank) : _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight:
                        highlight ? FontWeight.w900 : FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  highlight ? 'You' : 'Worldwide athlete',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                _categoryIcon(_selectedCategory),
                color: isTopThree ? _podiumColor(entry.rank) : _accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.score}',
                style: const TextStyle(
                  color: _text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankingEntry {
  final int rank;
  final String name;
  final int score;
  final bool isCurrentUser;

  const _RankingEntry({
    this.rank = 0,
    required this.name,
    required this.score,
    required this.isCurrentUser,
  });

  _RankingEntry copyWith({
    int? rank,
    String? name,
    int? score,
    bool? isCurrentUser,
  }) {
    return _RankingEntry(
      rank: rank ?? this.rank,
      name: name ?? this.name,
      score: score ?? this.score,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
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