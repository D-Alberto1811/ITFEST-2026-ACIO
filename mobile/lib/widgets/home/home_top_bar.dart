import 'package:flutter/material.dart';

/// Bară superioară pe Home: logo, streak, gems, buton profil.
class HomeTopBar extends StatelessWidget {
  final int streakDays;
  final int gems;
  final VoidCallback onProfileTap;

  const HomeTopBar({
    super.key,
    required this.streakDays,
    required this.gems,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 92,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const Spacer(),
        _HomeTopChip(
          icon: Icons.local_fire_department_rounded,
          value: streakDays.toString(),
          iconColor: const Color(0xFFF97316),
        ),
        const SizedBox(width: 8),
        _HomeTopChip(
          icon: Icons.diamond_rounded,
          value: gems.toString(),
          iconColor: const Color(0xFFA78BFA),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTopChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color iconColor;

  const _HomeTopChip({
    required this.icon,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
