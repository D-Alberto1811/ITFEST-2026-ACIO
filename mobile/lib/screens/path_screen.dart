import 'package:flutter/material.dart';

import '../models/quest.dart';

class PathScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        final isCompleted = completedQuestIds.contains(quest.id);
        final isUnlocked = index == 0 ||
            completedQuestIds.contains(quests[index - 1].id) ||
            isCompleted;

        final showHeader = index % 10 == 0;
        final difficulty = _difficultyForIndex(index);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              const SizedBox(height: 8),
              _SectionHeader(
                title: difficulty.label,
                subtitle: difficulty.subtitle,
                color: difficulty.color,
              ),
              const SizedBox(height: 12),
            ],
            _PathNode(
              quest: quest,
              index: index,
              isCompleted: isCompleted,
              isUnlocked: isUnlocked,
              color: difficulty.color,
              onTap: isUnlocked ? () => onQuestTap(quest) : null,
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  _DifficultyData _difficultyForIndex(int index) {
    if (index < 10) {
      return const _DifficultyData(
        label: 'Beginner',
        subtitle: 'Start easy and build consistency',
        color: Color(0xFF22C55E),
      );
    }
    if (index < 20) {
      return const _DifficultyData(
        label: 'Intermediate',
        subtitle: 'A bit more volume and control',
        color: Color(0xFF06B6D4),
      );
    }
    if (index < 30) {
      return const _DifficultyData(
        label: 'Medium',
        subtitle: 'Balanced challenge for daily growth',
        color: Color(0xFFF59E0B),
      );
    }
    if (index < 40) {
      return const _DifficultyData(
        label: 'Hard',
        subtitle: 'Push your endurance and focus',
        color: Color(0xFFA855F7),
      );
    }
    return const _DifficultyData(
      label: 'Extreme',
      subtitle: 'High intensity path missions',
      color: Color(0xFFEF4444),
    );
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
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
                    fontSize: 18,
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
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  final Quest quest;
  final int index;
  final bool isCompleted;
  final bool isUnlocked;
  final Color color;
  final VoidCallback? onTap;

  const _PathNode({
    required this.quest,
    required this.index,
    required this.isCompleted,
    required this.isUnlocked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = index.isEven;

    final card = Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: isUnlocked ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF334155),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniReward(
                      icon: Icons.bolt_rounded,
                      text: '+${quest.rewardXp} XP',
                      color: const Color(0xFF06B6D4),
                    ),
                    const SizedBox(width: 8),
                    _MiniReward(
                      icon: Icons.diamond_rounded,
                      text: '+${quest.rewardGems}',
                      color: const Color(0xFFA78BFA),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isLeft) card else const Spacer(),
        const SizedBox(width: 12),
        _PathCircle(
          index: index + 1,
          isCompleted: isCompleted,
          isUnlocked: isUnlocked,
          color: color,
          onTap: onTap,
        ),
        const SizedBox(width: 12),
        if (!isLeft) card else const Spacer(),
      ],
    );
  }
}

class _PathCircle extends StatelessWidget {
  final int index;
  final bool isCompleted;
  final bool isUnlocked;
  final Color color;
  final VoidCallback? onTap;

  const _PathCircle({
    required this.index,
    required this.isCompleted,
    required this.isUnlocked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCompleted
        ? const Color(0xFF22C55E)
        : isUnlocked
            ? color
            : const Color(0xFF334155);

    return Column(
      children: [
        Container(
          width: 3,
          height: 18,
          color: const Color(0xFF334155),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: bgColor.withOpacity(0.22),
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
                      size: 26,
                    )
                  : Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
        Container(
          width: 3,
          height: 18,
          color: const Color(0xFF334155),
        ),
      ],
    );
  }
}

class _MiniReward extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MiniReward({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}