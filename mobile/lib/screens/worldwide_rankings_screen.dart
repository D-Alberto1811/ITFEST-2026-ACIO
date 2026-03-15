import 'package:flutter/material.dart';

import '../config/storage_config.dart';
import '../models/app_user.dart';

/// Worldwide rankings screen inspired by the attached mockup:
/// - title + subtitle
/// - 3 tabs: Push-Ups / Squats / Jumping Jacks
/// - top 10 visible immediately
/// - current user shown under the leaderboard when outside top 10
/// - secondary card: user's ranking across all exercises
///
/// This file is intentionally self-contained so it can be dropped into
/// `mobile/lib/screens/worldwide_rankings_screen.dart`.
///
/// Current behavior:
/// - In SQLite mode, the screen uses a local seeded repository.
/// - In server mode, the repository is already abstracted and can be swapped
///   with real API calls without changing the UI.
class WorldwideRankingsScreen extends StatefulWidget {
  final AppUser user;

  /// Optional local stats for the current user.
  ///
  /// If not provided, the screen falls back to demo values that match the
  /// mocked leaderboard behavior.
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
  late final RankingsRepository _repository;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  RankingCategory _selectedCategory = RankingCategory.pushUps;
  LeaderboardSnapshot? _snapshot;
  PersonalRankingsSummary? _personalSummary;

  @override
  void initState() {
    super.initState();
    _repository = isServerMode
        ? _ServerRankingsRepository()
        : _LocalSeededRankingsRepository(
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
        _error = 'Could not load worldwide rankings right now.';
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
}

enum RankingCategory {
  pushUps('Push-Ups', 'pushups'),
  squats('Squats', 'squats'),
  jumpingJacks('Jumping Jacks', 'jumping_jacks');

  final String label;
  final String apiKey;

  const RankingCategory(this.label, this.apiKey);
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
    this.isCurrentUser = false,
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

  bool get isCurrentUserInTopTen =>
      topEntries.any((entry) => entry.isCurrentUser || entry.rank == currentUserEntry.rank);

  LeaderboardEntry? get previousEntry {
    if (currentUserEntry.rank <= 1) return null;

    final List<LeaderboardEntry> pool = <LeaderboardEntry>[
      ...topEntries,
      currentUserEntry,
    ]..sort((a, b) => a.rank.compareTo(b.rank));

    for (final entry in pool) {
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

class _LocalSeededRankingsRepository implements RankingsRepository {
  final AppUser currentUser;
  final Map<RankingCategory, int>? currentUserTotals;

  _LocalSeededRankingsRepository({
    required this.currentUser,
    this.currentUserTotals,
  });

  static const Map<RankingCategory, List<_SeedLeaderboardRow>> _seedRows = {
    RankingCategory.pushUps: [
      _SeedLeaderboardRow('Alex', 12540),
      _SeedLeaderboardRow('Maria', 11980),
      _SeedLeaderboardRow('Daniel', 11410),
      _SeedLeaderboardRow('Sophie', 10920),
      _SeedLeaderboardRow('David', 10500),
      _SeedLeaderboardRow('Emma', 10210),
      _SeedLeaderboardRow('Leo', 9980),
      _SeedLeaderboardRow('Mia', 9730),
      _SeedLeaderboardRow('Noah', 9410),
      _SeedLeaderboardRow('Sara', 9180),
      _SeedLeaderboardRow('Iris', 9000),
      _SeedLeaderboardRow('Luca', 8830),
      _SeedLeaderboardRow('Anya', 8610),
      _SeedLeaderboardRow('Mateo', 8420),
      _SeedLeaderboardRow('Ava', 8280),
      _SeedLeaderboardRow('Victor', 8050),
      _SeedLeaderboardRow('Ethan', 7810),
      _SeedLeaderboardRow('Nina', 7600),
      _SeedLeaderboardRow('Julia', 7380),
      _SeedLeaderboardRow('Mark', 7210),
      _SeedLeaderboardRow('Elena', 7070),
      _SeedLeaderboardRow('Sebastian', 6940),
      _SeedLeaderboardRow('Daria', 6810),
      _SeedLeaderboardRow('Paul', 6680),
      _SeedLeaderboardRow('Olivia', 6520),
      _SeedLeaderboardRow('Radu', 6380),
      _SeedLeaderboardRow('Eva', 6240),
      _SeedLeaderboardRow('Teo', 6090),
      _SeedLeaderboardRow('Amelia', 5930),
      _SeedLeaderboardRow('Tudor', 5780),
      _SeedLeaderboardRow('Bianca', 5600),
      _SeedLeaderboardRow('Cora', 5450),
      _SeedLeaderboardRow('Andrei', 5230),
      _SeedLeaderboardRow('Diana', 5010),
      _SeedLeaderboardRow('Kian', 4870),
      _SeedLeaderboardRow('Lara', 4720),
      _SeedLeaderboardRow('Maya', 4560),
      _SeedLeaderboardRow('Nora', 4420),
      _SeedLeaderboardRow('Oscar', 4270),
      _SeedLeaderboardRow('Petra', 4160),
      _SeedLeaderboardRow('Quinn', 4030),
      _SeedLeaderboardRow('Roxana', 3920),
      _SeedLeaderboardRow('Stefan', 3810),
      _SeedLeaderboardRow('Tania', 3690),
      _SeedLeaderboardRow('Ugo', 3550),
      _SeedLeaderboardRow('Vera', 3400),
      _SeedLeaderboardRow('Wade', 3280),
      _SeedLeaderboardRow('Xenia', 3170),
      _SeedLeaderboardRow('Yara', 3050),
      _SeedLeaderboardRow('Zane', 2920),
      _SeedLeaderboardRow('Ada', 2800),
      _SeedLeaderboardRow('Ben', 2690),
      _SeedLeaderboardRow('Clara', 2580),
      _SeedLeaderboardRow('Denis', 2470),
      _SeedLeaderboardRow('Erin', 2360),
      _SeedLeaderboardRow('Fabian', 2240),
    ],
    RankingCategory.squats: [
      _SeedLeaderboardRow('Mara', 14220),
      _SeedLeaderboardRow('Chris', 13890),
      _SeedLeaderboardRow('Eva', 13210),
      _SeedLeaderboardRow('Luca', 12650),
      _SeedLeaderboardRow('Nadia', 12140),
      _SeedLeaderboardRow('Owen', 11780),
      _SeedLeaderboardRow('Petra', 11300),
      _SeedLeaderboardRow('Ryan', 10890),
      _SeedLeaderboardRow('Sonia', 10320),
      _SeedLeaderboardRow('Toby', 9940),
      _SeedLeaderboardRow('Uma', 9620),
      _SeedLeaderboardRow('Vlad', 9310),
      _SeedLeaderboardRow('Willa', 9020),
      _SeedLeaderboardRow('Xander', 8740),
      _SeedLeaderboardRow('Yuna', 8460),
      _SeedLeaderboardRow('Zara', 8210),
      _SeedLeaderboardRow('Alex', 7980),
      _SeedLeaderboardRow('Bianca', 7700),
      _SeedLeaderboardRow('Cezar', 7420),
      _SeedLeaderboardRow('Dora', 7180),
      _SeedLeaderboardRow('Eli', 6920),
      _SeedLeaderboardRow('Faye', 6710),
      _SeedLeaderboardRow('Gabi', 6510),
      _SeedLeaderboardRow('Hugo', 6300),
      _SeedLeaderboardRow('Ilinca', 6110),
      _SeedLeaderboardRow('Jon', 5900),
      _SeedLeaderboardRow('Kira', 5750),
      _SeedLeaderboardRow('Lia', 5590),
      _SeedLeaderboardRow('Mihai', 5430),
      _SeedLeaderboardRow('Nora', 5280),
      _SeedLeaderboardRow('Oana', 5140),
      _SeedLeaderboardRow('Pavel', 4990),
      _SeedLeaderboardRow('Ria', 4840),
    ],
    RankingCategory.jumpingJacks: [
      _SeedLeaderboardRow('Kai', 16320),
      _SeedLeaderboardRow('Lena', 15840),
      _SeedLeaderboardRow('Milo', 15110),
      _SeedLeaderboardRow('Nina', 14590),
      _SeedLeaderboardRow('Omar', 14020),
      _SeedLeaderboardRow('Pia', 13440),
      _SeedLeaderboardRow('Quentin', 12810),
      _SeedLeaderboardRow('Rina', 12170),
      _SeedLeaderboardRow('Sven', 11720),
      _SeedLeaderboardRow('Tara', 11230),
      _SeedLeaderboardRow('Urs', 10910),
      _SeedLeaderboardRow('Vio', 10580),
      _SeedLeaderboardRow('Will', 10230),
      _SeedLeaderboardRow('Ximena', 9930),
      _SeedLeaderboardRow('Yosef', 9650),
      _SeedLeaderboardRow('Zoe', 9410),
      _SeedLeaderboardRow('Amir', 9180),
      _SeedLeaderboardRow('Bella', 8960),
      _SeedLeaderboardRow('Cian', 8740),
      _SeedLeaderboardRow('Delia', 8530),
      _SeedLeaderboardRow('Enzo', 8320),
      _SeedLeaderboardRow('Flavia', 8100),
      _SeedLeaderboardRow('Gus', 7900),
      _SeedLeaderboardRow('Helga', 7720),
      _SeedLeaderboardRow('Ivan', 7540),
      _SeedLeaderboardRow('Jade', 7360),
      _SeedLeaderboardRow('Kara', 7180),
      _SeedLeaderboardRow('Lior', 6990),
      _SeedLeaderboardRow('Mina', 6810),
      _SeedLeaderboardRow('Nico', 6640),
      _SeedLeaderboardRow('Orla', 6480),
      _SeedLeaderboardRow('Pelin', 6320),
      _SeedLeaderboardRow('Rafi', 6160),
      _SeedLeaderboardRow('Sia', 6000),
      _SeedLeaderboardRow('Toni', 5840),
      _SeedLeaderboardRow('Una', 5690),
      _SeedLeaderboardRow('Vik', 5530),
      _SeedLeaderboardRow('Wren', 5370),
      _SeedLeaderboardRow('Xavi', 5210),
      _SeedLeaderboardRow('Yelena', 5050),
      _SeedLeaderboardRow('Zed', 4890),
      _SeedLeaderboardRow('Ana', 4740),
      _SeedLeaderboardRow('Bogdan', 4580),
      _SeedLeaderboardRow('Cami', 4420),
      _SeedLeaderboardRow('Dinu', 4280),
      _SeedLeaderboardRow('Ema', 4140),
      _SeedLeaderboardRow('Filip', 4010),
      _SeedLeaderboardRow('Geo', 3890),
      _SeedLeaderboardRow('Hana', 3770),
      _SeedLeaderboardRow('Ioan', 3650),
      _SeedLeaderboardRow('Jana', 3540),
      _SeedLeaderboardRow('Kris', 3430),
      _SeedLeaderboardRow('Lory', 3320),
      _SeedLeaderboardRow('Marius', 3210),
      _SeedLeaderboardRow('Nela', 3100),
      _SeedLeaderboardRow('Ovidiu', 2990),
      _SeedLeaderboardRow('Paula', 2880),
      _SeedLeaderboardRow('Rares', 2770),
      _SeedLeaderboardRow('Simi', 2660),
      _SeedLeaderboardRow('Teodora', 2550),
      _SeedLeaderboardRow('Ula', 2440),
      _SeedLeaderboardRow('Vasi', 2330),
      _SeedLeaderboardRow('Wanda', 2220),
      _SeedLeaderboardRow('Xenia', 2110),
      _SeedLeaderboardRow('Yvo', 2000),
      _SeedLeaderboardRow('Zina', 1890),
      _SeedLeaderboardRow('Adel', 1780),
      _SeedLeaderboardRow('Bruno', 1680),
      _SeedLeaderboardRow('Cleo', 1580),
      _SeedLeaderboardRow('Dora', 1480),
      _SeedLeaderboardRow('Edi', 1380),
      _SeedLeaderboardRow('Fani', 1280),
      _SeedLeaderboardRow('Gina', 1180),
      _SeedLeaderboardRow('Horia', 1080),
      _SeedLeaderboardRow('Ilona', 980),
      _SeedLeaderboardRow('Jeni', 880),
      _SeedLeaderboardRow('Koko', 780),
      _SeedLeaderboardRow('Luca', 680),
    ],
  };

  static const Map<RankingCategory, int> _defaultCurrentUserTotals = {
    RankingCategory.pushUps: 2140,
    RankingCategory.squats: 4910,
    RankingCategory.jumpingJacks: 1650,
  };

  @override
  Future<LeaderboardSnapshot> getLeaderboard(RankingCategory category) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final currentUserScore =
        currentUserTotals?[category] ?? _defaultCurrentUserTotals[category] ?? 0;

    final generated = <_SeedLeaderboardRow>[
      ...?_seedRows[category],
      _SeedLeaderboardRow(_displayName, currentUserScore, isCurrentUser: true),
    ]
      ..sort((a, b) => b.score.compareTo(a.score));

    final entries = <LeaderboardEntry>[];
    for (var i = 0; i < generated.length; i++) {
      final row = generated[i];
      entries.add(
        LeaderboardEntry(
          rank: i + 1,
          playerName: row.playerName,
          score: row.score,
          isCurrentUser: row.isCurrentUser,
        ),
      );
    }

    final currentUserEntry =
        entries.firstWhere((entry) => entry.isCurrentUser, orElse: () => entries.first);

    return LeaderboardSnapshot(
      category: category,
      topEntries: entries.take(10).toList(),
      currentUserEntry: currentUserEntry,
    );
  }

  @override
  Future<PersonalRankingsSummary> getPersonalSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final rankings = <RankingCategory, LeaderboardEntry>{};
    for (final category in RankingCategory.values) {
      final leaderboard = await getLeaderboard(category);
      rankings[category] = leaderboard.currentUserEntry;
    }

    return PersonalRankingsSummary(rankings: rankings);
  }

  String get _displayName {
    final trimmed = currentUser.name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'You';
  }
}

class _ServerRankingsRepository implements RankingsRepository {
  @override
  Future<LeaderboardSnapshot> getLeaderboard(RankingCategory category) async {
    throw UnimplementedError(
      'Backend integration pending. Plug your API call here for ${category.apiKey}.',
    );
  }

  @override
  Future<PersonalRankingsSummary> getPersonalSummary() async {
    throw UnimplementedError(
      'Backend integration pending. Return the current user ranks for all exercises.',
    );
  }
}

class _SeedLeaderboardRow {
  final String playerName;
  final int score;
  final bool isCurrentUser;

  const _SeedLeaderboardRow(
    this.playerName,
    this.score, {
    this.isCurrentUser = false,
  });
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
                      ? const Color(0xFF06B6D4).withValues(alpha: 0.15)
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

  @override
  Widget build(BuildContext context) {
    final currentUser = snapshot.currentUserEntry;
    final needed = snapshot.scoreNeededToReachPrevious;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F2937)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
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
              child: _LeaderboardRow(entry: entry),
            ),
          ),
          if (!snapshot.isCurrentUserInTopTen) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Color(0xFF334155)),
            ),
            _LeaderboardRow(entry: currentUser),
            if (needed != null) ...[
              const SizedBox(height: 10),
              Text(
                '$needed more to reach #${currentUser.rank - 1}',
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

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final textColor = entry.isCurrentUser ? Colors.white : const Color(0xFFE5E7EB);
    final backgroundColor = entry.isCurrentUser
        ? const Color(0xFF06B6D4).withValues(alpha: 0.12)
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
              entry.isCurrentUser ? '${entry.playerName} (You)' : entry.playerName,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: entry.isCurrentUser ? FontWeight.w800 : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
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

  const _YourRankingsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F2937)),
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
