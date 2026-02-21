import 'package:flutter/material.dart';

class HealthBar extends StatelessWidget {
  final int score; // 0–100
  const HealthBar({super.key, required this.score});

  Color get _color {
    if (score >= 65) return const Color(0xFF2ECC71);
    if (score >= 35) return const Color(0xFFF4D03F);
    return const Color(0xFFE74C3C);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: score / 100,
        minHeight: 8,
        backgroundColor: const Color(0xFF1a2a1a),
        valueColor: AlwaysStoppedAnimation<Color>(_color),
      ),
    );
  }
}
