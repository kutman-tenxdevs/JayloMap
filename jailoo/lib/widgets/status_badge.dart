import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  String get _label {
    switch (status) {
      case 'healthy':    return '● БЕЗОПАСНО';
      case 'recovering': return '● ВОССТАНОВЛЕНИЕ';
      case 'banned':     return '● ЗАПРЕТ';
      default:           return status;
    }
  }

  Color get _color {
    switch (status) {
      case 'healthy':    return const Color(0xFF2ECC71);
      case 'recovering': return const Color(0xFFF4D03F);
      case 'banned':     return const Color(0xFFE74C3C);
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: 'DMMono',
          fontSize: 10,
          color: _color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
