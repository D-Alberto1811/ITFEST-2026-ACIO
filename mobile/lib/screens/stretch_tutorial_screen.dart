import 'package:flutter/material.dart';

import 'stretching_screen.dart';

class StretchTutorialScreen extends StatelessWidget {
  final StretchExercise exercise;

  const StretchTutorialScreen({
    super.key,
    required this.exercise,
  });

  static const Color _bg = Color(0xFF0F172A);
  static const Color _panel = Color(0xFF111827);
  static const Color _card = Color(0xFF1E293B);
  static const Color _border = Color(0xFF334155);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _text = Colors.white;
  static const Color _accent = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          exercise.title,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Text(
                    exercise.emoji,
                    style: const TextStyle(fontSize: 54),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    exercise.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${exercise.durationSeconds}s \u2022 ${exercise.bodyArea}',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    exercise.shortDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('HOW TO DO IT'),
            const SizedBox(height: 12),
            ...exercise.steps.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StepCard(
                  index: entry.key + 1,
                  text: entry.value,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionTitle('TIPS'),
            const SizedBox(height: 12),
            ...exercise.tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TipCard(text: tip),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: const Text(
                'Always stretch gently and stop if you feel sharp pain.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _muted,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final String text;

  const _StepCard({
    required this.index,
    required this.text,
  });

  static const Color _card = Color(0xFF1E293B);
  static const Color _border = Color(0xFF334155);
  static const Color _text = Colors.white;
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _accent = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withOpacity(0.45)),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _text,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;

  const _TipCard({
    required this.text,
  });

  static const Color _card = Color(0xFF1E293B);
  static const Color _border = Color(0xFF334155);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _accent = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}