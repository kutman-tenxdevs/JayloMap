import 'package:flutter/material.dart';
import '../theme/colors.dart';

class DataCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const DataCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: c.textMuted),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
