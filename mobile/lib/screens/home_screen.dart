import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int level = 1;
  int xp = 0;
  int xpForNext = 100;
  int gems = 0;
  int streakDays = 0;

  final List<Quest> quests = [
    Quest(id: 1, title: 'Rookie Push-ups', type: 'pushup', target: 5, rewardXp: 40, rewardGems: 2, icon: '💪', desc: 'Do 5 Push-ups'),
    Quest(id: 2, title: 'Leg Day Basics', type: 'squat', target: 10, rewardXp: 50, rewardGems: 3, icon: '🦵', desc: 'Do 10 Squats'),
    Quest(id: 3, title: 'Jumping Jacks Intro', type: 'jumping_jack', target: 10, rewardXp: 45, rewardGems: 2, icon: '🦘', desc: 'Do 10 Jumping Jacks'),
    Quest(id: 4, title: "Warrior's Test", type: 'pushup', target: 15, rewardXp: 80, rewardGems: 5, icon: '⚔️', desc: 'Do 15 Push-ups'),
  ];

  void _onQuestComplete(int rewardXp, int rewardGems) {
    setState(() {
      xp += rewardXp;
      gems += rewardGems;
      while (xp >= xpForNext) {
        xp -= xpForNext;
        level++;
        xpForNext = (xpForNext * 1.5).toInt();
      }
      streakDays = streakDays + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FITLINGO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        Row(
                          children: [
                            _buildStatChip('🔥', streakDays.toString()),
                            const SizedBox(width: 8),
                            _buildStatChip('💎', gems.toString()),
                            const SizedBox(width: 8),
                            _buildStatChip('LVL', level.toString()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Barnaby + XP Bar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF422006),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(color: const Color(0xFFD97706)),
                            ),
                            child: const Center(child: Text('🐻', style: TextStyle(fontSize: 40))),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ready for training?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$xp / $xpForNext XP',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (xp / xpForNext).clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFF0F172A),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "📜 Today's Quests",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final q = quests[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuestCard(
                        quest: q,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutScreen(
                              quest: q,
                              onComplete: () => _onQuestComplete(q.rewardXp, q.rewardGems),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: quests.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onTap;

  const _QuestCard({required this.quest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF475569)),
        ),
        child: Row(
          children: [
            Text(quest.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    quest.desc,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+${quest.rewardXp} XP', style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold)),
                if (quest.rewardGems > 0) Text('+${quest.rewardGems} 💎', style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12)),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF64748B), size: 16),
          ],
        ),
      ),
    );
  }
}
