import 'package:flutter/material.dart';

import '../../models/quest.dart';

/// Tab-ul de Daily Quests: listă de carduri.
class HomeDailyQuestsTab extends StatelessWidget {
  final List<Quest> quests;
  final Set<int> completedQuestIds;
  final ValueChanged<Quest> onQuestTap;

  const HomeDailyQuestsTab({
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HomeDailyQuestCard(
            quest: quest,
            isCompleted: isCompleted,
            onTap: isCompleted ? null : () => onQuestTap(quest),
          ),
        );
      },
    );
  }
}

/// Un card pentru un quest zilnic.
class HomeDailyQuestCard extends StatelessWidget {
  final Quest quest;
  final bool isCompleted;
  final VoidCallback? onTap;

  const HomeDailyQuestCard({
    super.key,
    required this.quest,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isCompleted ? 0.70 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF334155),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted ? 'Completed' : quest.desc,
                      style: TextStyle(
                        color: isCompleted
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        HomeRewardTag(
                          icon: Icons.bolt_rounded,
                          text: '+${quest.rewardXp} XP',
                          color: const Color(0xFF06B6D4),
                        ),
                        const SizedBox(width: 8),
                        if (quest.rewardGems > 0)
                          HomeRewardTag(
                            icon: Icons.diamond_rounded,
                            text: '+${quest.rewardGems}',
                            color: const Color(0xFFA78BFA),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
                color: isCompleted
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF64748B),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tag XP / gems pe carduri.
class HomeRewardTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const HomeRewardTag({
    super.key,
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
