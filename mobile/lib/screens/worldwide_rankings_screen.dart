import 'package:flutter/material.dart';

import '../config/storage_config.dart';
import '../models/app_user.dart';
import '../models/player_progress.dart';
import '../services/database_service.dart';

enum RankingCategory {
  pushUps,
  squats,
  jumpingJacks,
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

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  List<_RankingEntry> _allEntries = [];
  _RankingEntry? _currentUserEntry;
  Map<RankingCategory, int> _myRanks = {};

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  String _categoryTitle(RankingCategory category) {
    switch (category) {
      case RankingCategory.pushUps:
        return 'Push-Ups';
      case RankingCategory.squats:
        return 'Squats';
      case RankingCategory.jumpingJacks:
        return 'Jumping Jacks';
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

  Color _podiumColor(int rank) {
    switch (rank) {
      case 1:
        return _gold;
      case 2:
        return _silver;
      case 3:
        return _bronze;
      default:
        return _accent;
    }
  }

  Future<void> _loadLeaderboard({bool refresh = false}) async {
    if (refresh) {
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
      final rankings = await _getRankingsForCategory(_selectedCategory);
      final myRanks = await _getUserRanksForAllCategories();

      if (!mounted) return;

      setState(() {
        _allEntries = rankings;
        _currentUserEntry = rankings.cast<_RankingEntry?>().firstWhere(
              (entry) => entry?.isCurrentUser == true,
              orElse: () => null,
            );
        _myRanks = myRanks;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<List<_RankingEntry>> _getRankingsForCategory(
    RankingCategory category,
  ) async {
    if (isServerMode) {
      throw Exception(
        'Leaderboard from server is not implemented on backend yet.',
      );
    }

    final users = await DatabaseService.instance.getAllUsers();
    final entries = <_RankingEntry>[];

    for (final user in users) {
      if (user.id == null) continue;

      final progress = await DatabaseService.instance.getPlayerProgress(user.id!) ??
          PlayerProgress.initial(user.id!);

      final score = _scoreFromProgress(progress, category);

      entries.add(
        _RankingEntry(
          rank: 0,
          name: user.name.trim().isEmpty ? 'Unknown Athlete' : user.name.trim(),
          score: score,
          isCurrentUser: user.id == widget.user.id,
        ),
      );
    }

    final hasCurrentUser = entries.any((entry) => entry.isCurrentUser);

    if (!hasCurrentUser) {
      entries.add(
        _RankingEntry(
          rank: 0,
          name: widget.user.name.trim().isEmpty ? 'You' : widget.user.name.trim(),
          score: widget.currentUserExerciseTotals?[category] ?? 0,
          isCurrentUser: true,
        ),
      );
    }

    entries.sort((a, b) => b.score.compareTo(a.score));

    return List<_RankingEntry>.generate(entries.length, (index) {
      final entry = entries[index];
      return entry.copyWith(rank: index + 1);
    });
  }

  Future<Map<RankingCategory, int>> _getUserRanksForAllCategories() async {
    final result = <RankingCategory, int>{};

    for (final category in RankingCategory.values) {
      final entries = await _getRankingsForCategory(category);
      final myEntry = entries.cast<_RankingEntry?>().firstWhere(
            (entry) => entry?.isCurrentUser == true,
            orElse: () => null,
          );
      result[category] = myEntry?.rank ?? 0;
    }

    return result;
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

  Future<void> _onCategoryChanged(RankingCategory category) async {
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
    });

    await _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final topEntries = _allEntries.take(10).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadLeaderboard(refresh: true),
          color: _accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            children: [
              Row(
                children: [
                  _TopCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  const Text(
                    'Leaderboard',
                    style: TextStyle(
                      color: _text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 46),
                ],
              ),
              const SizedBox(height: 18),
              _buildCurrentUserCard(_currentUserEntry),
              const SizedBox(height: 18),
              _buildCategorySelector(),
              const SizedBox(height: 18),
              if (_isLoading)
                const _LoadingCard()
              else if (_error != null)
                _ErrorCard(
                  message: _error!,
                  onRetry: _loadLeaderboard,
                )
              else ...[
                _buildLeaderboardCard(topEntries),
                const SizedBox(height: 18),
                _buildYourRankingsCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard(_RankingEntry? userEntry) {
    final safeEntry = userEntry ??
        _RankingEntry(
          rank: 0,
          name: widget.user.name.trim().isEmpty ? 'You' : widget.user.name.trim(),
          score: widget.currentUserExerciseTotals?[_selectedCategory] ?? 0,
          isCurrentUser: true,
        );

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
                safeEntry.rank > 0 ? '#${safeEntry.rank}' : '-',
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
                  safeEntry.name,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${safeEntry.score} ${_categoryTitle(_selectedCategory).toLowerCase()}',
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
                onTap: () => _onCategoryChanged(category),
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

  Widget _buildLeaderboardCard(List<_RankingEntry> topEntries) {
    return Container(
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
              Text(
                _categoryTitle(_selectedCategory),
                style: const TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_isRefreshing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...topEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LeaderboardRow(
                entry: entry,
                icon: _categoryIcon(_selectedCategory),
                podiumColor: _podiumColor,
              ),
            ),
          ),
          if (_currentUserEntry != null &&
              !_allEntries.take(10).any((e) => e.isCurrentUser)) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: _border),
            ),
            _LeaderboardRow(
              entry: _currentUserEntry!,
              icon: _categoryIcon(_selectedCategory),
              podiumColor: _podiumColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYourRankingsCard() {
    return Container(
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
            'Your Rankings',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ...RankingCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _categoryTitle(category),
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _myRanks[category] != null && _myRanks[category]! > 0
                        ? '#${_myRanks[category]}'
                        : '-',
                    style: const TextStyle(
                      color: _text,
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

class _LeaderboardRow extends StatelessWidget {
  final _RankingEntry entry;
  final IconData icon;
  final Color Function(int rank) podiumColor;

  const _LeaderboardRow({
    required this.entry,
    required this.icon,
    required this.podiumColor,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isCurrentUser;
    final isTopThree = entry.rank <= 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF1E293B) : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? const Color(0xFF06B6D4)
              : isTopThree
                  ? podiumColor(entry.rank).withOpacity(0.55)
                  : const Color(0xFF334155),
          width: highlight ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              border: Border.all(
                color: isTopThree
                    ? podiumColor(entry.rank)
                    : const Color(0xFF334155),
              ),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  color:
                      isTopThree ? podiumColor(entry.rank) : Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.isCurrentUser ? 'You' : 'Worldwide athlete',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
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
                icon,
                color: isTopThree
                    ? podiumColor(entry.rank)
                    : const Color(0xFF06B6D4),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.score}',
                style: const TextStyle(
                  color: Colors.white,
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
  final Future<void> Function({bool refresh}) onRetry;

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