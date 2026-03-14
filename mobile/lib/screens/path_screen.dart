import 'package:flutter/material.dart';

import '../models/quest.dart';

class PathScreen extends StatefulWidget {
  final List<Quest> quests;
  final Set<int> completedQuestIds;
  final ValueChanged<Quest> onQuestTap;

  const PathScreen({
    super.key,
    required this.quests,
    required this.completedQuestIds,
    required this.onQuestTap,
  });

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  Quest? _selectedQuest;

  @override
  void initState() {
    super.initState();
    if (widget.quests.isNotEmpty) {
      _selectedQuest = widget.quests.first;
    }
  }

  @override
  void didUpdateWidget(covariant PathScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_selectedQuest == null && widget.quests.isNotEmpty) {
      _selectedQuest = widget.quests.first;
      return;
    }

    if (_selectedQuest != null) {
      final stillExists =
          widget.quests.any((quest) => quest.id == _selectedQuest!.id);
      if (!stillExists && widget.quests.isNotEmpty) {
        _selectedQuest = widget.quests.first;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupQuestsByDifficulty(widget.quests);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: grouped.entries.map((entry) {
                final difficulty = entry.key;
                final quests = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _DifficultySection(
                    title: difficulty.label,
                    subtitle: difficulty.subtitle,
                    color: difficulty.color,
                    quests: quests,
                    allQuests: widget.quests,
                    completedQuestIds: widget.completedQuestIds,
                    selectedQuestId: _selectedQuest?.id,
                    onSelectQuest: (quest) {
                      setState(() {
                        _selectedQuest = quest;
                      });
                    },
                    isQuestUnlocked: _isQuestUnlocked,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        _buildSelectedQuestPanel(),
      ],
    );
  }

  bool _isQuestUnlocked(Quest quest) {
    if (widget.quests.isEmpty) return false;

    final index = widget.quests.indexWhere((q) => q.id == quest.id);
    if (index == -1) return false;

    if (index == 0) return true;

    final previousQuest = widget.quests[index - 1];
    return widget.completedQuestIds.contains(previousQuest.id);
  }

  Widget _buildSelectedQuestPanel() {
    final quest = _selectedQuest;

    if (quest == null) {
      return const SizedBox.shrink();
    }

    final isCompleted = widget.completedQuestIds.contains(quest.id);
    final isUnlocked = _isQuestUnlocked(quest);
    final accent = _exerciseColor(quest.type);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF334155),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withOpacity(0.45)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  quest.icon,
                  style: const TextStyle(fontSize: 30),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    quest.desc,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                        icon: Icons.bolt_rounded,
                        text: '+${quest.rewardXp} XP',
                        color: const Color(0xFF06B6D4),
                      ),
                      _InfoPill(
                        icon: Icons.diamond_rounded,
                        text: '+${quest.rewardGems}',
                        color: const Color(0xFFA78BFA),
                      ),
                      _InfoPill(
                        icon: isCompleted
                            ? Icons.check_circle_rounded
                            : isUnlocked
                                ? Icons.lock_open_rounded
                                : Icons.lock_rounded,
                        text: isCompleted
                            ? 'Completed'
                            : isUnlocked
                                ? 'Unlocked'
                                : 'Locked',
                        color: isCompleted
                            ? const Color(0xFF22C55E)
                            : isUnlocked
                                ? accent
                                : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (!isUnlocked || isCompleted)
                    ? null
                    : () => widget.onQuestTap(quest),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF334155),
                  disabledForegroundColor: Colors.white54,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isCompleted
                      ? 'Done'
                      : isUnlocked
                          ? 'Start'
                          : 'Locked',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<_DifficultyData, List<Quest>> _groupQuestsByDifficulty(List<Quest> quests) {
    final beginner = <Quest>[];
    final intermediate = <Quest>[];
    final medium = <Quest>[];
    final hard = <Quest>[];
    final extreme = <Quest>[];

    for (final quest in quests) {
      final title = quest.title.toLowerCase();

      if (title.startsWith('beginner')) {
        beginner.add(quest);
      } else if (title.startsWith('intermediate')) {
        intermediate.add(quest);
      } else if (title.startsWith('medium')) {
        medium.add(quest);
      } else if (title.startsWith('hard')) {
        hard.add(quest);
      } else {
        extreme.add(quest);
      }
    }

    return {
      const _DifficultyData(
        label: 'Beginner',
        subtitle: 'Start easy and build consistency',
        color: Color(0xFF22C55E),
      ): beginner,
      const _DifficultyData(
        label: 'Intermediate',
        subtitle: 'More reps, better control',
        color: Color(0xFF06B6D4),
      ): intermediate,
      const _DifficultyData(
        label: 'Medium',
        subtitle: 'Balanced challenge and volume',
        color: Color(0xFFF59E0B),
      ): medium,
      const _DifficultyData(
        label: 'Hard',
        subtitle: 'Push endurance and focus',
        color: Color(0xFFA855F7),
      ): hard,
      const _DifficultyData(
        label: 'Extreme',
        subtitle: 'High intensity missions',
        color: Color(0xFFEF4444),
      ): extreme,
    };
  }

  Color _exerciseColor(String type) {
    switch (type) {
      case 'pushup':
        return const Color(0xFF06B6D4);
      case 'squat':
        return const Color(0xFFF59E0B);
      case 'jumping_jack':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF06B6D4);
    }
  }
}

class _DifficultyData {
  final String label;
  final String subtitle;
  final Color color;

  const _DifficultyData({
    required this.label,
    required this.subtitle,
    required this.color,
  });
}

class _DifficultySection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<Quest> quests;
  final List<Quest> allQuests;
  final Set<int> completedQuestIds;
  final int? selectedQuestId;
  final ValueChanged<Quest> onSelectQuest;
  final bool Function(Quest quest) isQuestUnlocked;

  const _DifficultySection({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.quests,
    required this.allQuests,
    required this.completedQuestIds,
    required this.selectedQuestId,
    required this.onSelectQuest,
    required this.isQuestUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF172033),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${quests.where((q) => completedQuestIds.contains(q.id)).length}/${quests.length}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(quests.length, (index) {
                final quest = quests[index];
                final isCompleted = completedQuestIds.contains(quest.id);
                final isUnlocked = isQuestUnlocked(quest);
                final isSelected = selectedQuestId == quest.id;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == quests.length - 1 ? 0 : 10,
                  ),
                  child: Row(
                    children: [
                      _PathNode(
                        number: allQuests.indexWhere((q) => q.id == quest.id) + 1,
                        quest: quest,
                        color: color,
                        isCompleted: isCompleted,
                        isUnlocked: isUnlocked,
                        isSelected: isSelected,
                        onTap: () => onSelectQuest(quest),
                      ),
                      if (index != quests.length - 1)
                        _Connector(
                          isActive: isCompleted,
                          nextUnlocked: isQuestUnlocked(quests[index + 1]),
                          color: color,
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  final int number;
  final Quest quest;
  final Color color;
  final bool isCompleted;
  final bool isUnlocked;
  final bool isSelected;
  final VoidCallback onTap;

  const _PathNode({
    required this.number,
    required this.quest,
    required this.color,
    required this.isCompleted,
    required this.isUnlocked,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nodeColor = isCompleted
        ? const Color(0xFF22C55E)
        : isUnlocked
            ? color
            : const Color(0xFF334155);

    final borderColor = isSelected
        ? Colors.white
        : isCompleted
            ? const Color(0xFF22C55E)
            : isUnlocked
                ? color
                : const Color(0xFF475569);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? borderColor.withOpacity(0.18)
                  : Colors.black.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCompleted
                            ? const [
                                Color(0xFF22C55E),
                                Color(0xFF16A34A),
                              ]
                            : [
                                color.withOpacity(0.95),
                                color.withOpacity(0.75),
                              ],
                      )
                    : null,
                color: isUnlocked ? null : const Color(0xFF334155),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: nodeColor.withOpacity(0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 24,
                      )
                    : isUnlocked
                        ? Text(
                            '$number',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : const Icon(
                            Icons.lock_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              quest.icon,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              quest.title
                  .replaceAll('Beginner ', '')
                  .replaceAll('Intermediate ', '')
                  .replaceAll('Medium ', '')
                  .replaceAll('Hard ', '')
                  .replaceAll('Extreme ', ''),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnlocked ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final bool isActive;
  final bool nextUnlocked;
  final Color color;

  const _Connector({
    required this.isActive,
    required this.nextUnlocked,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final connectorColor = isActive
        ? color.withOpacity(0.75)
        : nextUnlocked
            ? color.withOpacity(0.40)
            : const Color(0xFF334155);

    return Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            connectorColor,
            connectorColor.withOpacity(0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoPill({
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