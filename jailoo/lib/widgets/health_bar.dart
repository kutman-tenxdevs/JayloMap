import 'package:flutter/material.dart';
import '../theme/colors.dart';

class HealthBar extends StatelessWidget {
  final int score;
  const HealthBar({super.key, required this.score});

  Color get _color {
    if (score >= 65) return JailooColors.healthy;
    if (score >= 35) return JailooColors.recovering;
    return JailooColors.banned;
  }

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            backgroundColor: c.surface2,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score%',
          style: TextStyle(
            fontSize: 11,
            color: _color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
