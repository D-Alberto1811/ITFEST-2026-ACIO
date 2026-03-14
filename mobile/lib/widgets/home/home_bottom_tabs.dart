import 'package:flutter/material.dart';

/// Bară bottom: Quests / Path.
class HomeBottomTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const HomeBottomTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HomeBottomTabButton(
              label: 'Quests',
              icon: Icons.flag_rounded,
              isSelected: selectedIndex == 0,
              onTap: () => onTabSelected(0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _HomeBottomTabButton(
              label: 'Path',
              icon: Icons.alt_route_rounded,
              isSelected: selectedIndex == 1,
              onTap: () => onTabSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBottomTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _HomeBottomTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF06B6D4) : const Color(0xFF334155),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF06B6D4)
                  : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
