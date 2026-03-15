import 'package:flutter/material.dart';

class AchievementIcon extends StatelessWidget {
  final String iconPath;
  final bool isUnlocked;
  final double size;

  const AchievementIcon({
    super.key,
    required this.iconPath,
    required this.isUnlocked,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      iconPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Icon(
          Icons.emoji_events_rounded,
          size: size * 0.8,
          color: isUnlocked ? const Color(0xFFFFB800) : Colors.grey,
        );
      },
    );

    if (isUnlocked) {
      return image;
    }

    return Opacity(
      opacity: 0.45,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: image,
      ),
    );
  }
}