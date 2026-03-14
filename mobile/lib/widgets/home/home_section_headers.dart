import 'package:flutter/material.dart';

/// Header pentru tab-ul Daily Quests.
class HomeDailySectionHeader extends StatelessWidget {
  const HomeDailySectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Daily Quests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Complete your daily fitness missions',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// Header pentru tab-ul Quest Path.
class HomePathSectionHeader extends StatelessWidget {
  const HomePathSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quest Path',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tap the unlocked circles to start the next mission.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
