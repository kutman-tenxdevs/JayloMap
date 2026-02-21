import 'package:flutter/material.dart';
import '../theme/colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  String get _label {
    switch (status) {
      case 'healthy':    return 'Safe';
      case 'recovering': return 'Recovering';
      case 'banned':     return 'Banned';
      default:           return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = JailooColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
