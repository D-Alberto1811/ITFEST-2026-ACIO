import 'dart:math';

import 'package:flutter/material.dart';

import '../models/app_user.dart';

enum RankingCategory {
  pushUps,
  squats,
  jumpingJacks,
}

class WorldwideRankingsScreen extends StatefulWidget {
  final AppUser user;
  final Map<RankingCategory, int> currentUserExerciseTotals;

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
    _buildRankingsOnce();
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

  List<_RankingEntry> _generateRankingsForCategory(RankingCategory category) {
    final random = Random(category.index + 37);

    final names = <String>[
      'Alex',
      'Maya',
      'Chris',
      'Jordan',
      'Taylor',
      'Sam',
      'Emma',
      'Noah',
      'Olivia',
      'Liam',
      'Ava',
      'Ethan',
      'Sophia',
      'James',
      'Lucas',
      'Mila',
      'Amelia',
      'Daniel',
      'Ella',
      'Mason',
      'David',
      'Sofia',
      'Henry',
      'Chloe',
      'Grace',
      'Leo',
      'Aria',
      'Sebastian',
      'Zoe',
      'Benjamin',
    ];

    final userName = widget.user.name.trim().isEmpty
        ? 'You'
        : widget.user.name.trim();

    final userScore = widget.currentUserExerciseTotals[category] ?? 0;

    final baseMin = switch (category) {
      RankingCategory.pushUps => 1200,
      RankingCategory.squats => 1800,
      RankingCategory.jumpingJacks => 1500,
    };

    final baseMax = switch (category) {
      RankingCategory.pushUps => 6200,
      RankingCategory.squats => 8600,
      RankingCategory.jumpingJacks => 7600,
    };

    final entries = <_RankingEntry>[];

    for (var i = 0; i < names.length; i++) {
      final value = baseMin + random.nextInt(baseMax - baseMin + 1);
      entries.add(
        _RankingEntry(
          name: '${names[i]} ${String.fromCharCode(65 + (i % 8))}.',
          score: value,
          isCurrentUser: false,
        ),
      );
    }

    entries.add(
      _RankingEntry(
        name: userName,
        score: userScore,
        isCurrentUser: true,
      ),
    );

    entries.sort((a, b) => b.score.compareTo(a.score));

    return List<_RankingEntry>.generate(entries.length, (index) {
      final entry = entries[index];
      return entry.copyWith(rank: index + 1);
    });
  }

  String _categoryTitle(RankingCategory category) {
    switch (category) {
      case RankingCategory.pushUps:
        return 'Push-ups';
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

  @override
  Widget build(BuildContext context) {
    final currentEntries = _cachedRankings[_selectedCategory]!;
    final currentUserEntry = _currentUserEntries[_selectedCategory]!;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
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