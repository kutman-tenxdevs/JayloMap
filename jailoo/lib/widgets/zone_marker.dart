import 'package:flutter/material.dart';
import '../models/zone.dart';

class ZoneMarker extends StatelessWidget {
  final Zone zone;
  const ZoneMarker({super.key, required this.zone});

  Color get _color {
    switch (zone.status) {
      case 'healthy':    return const Color(0xFF2ECC71);
      case 'recovering': return const Color(0xFFF4D03F);
      case 'banned':     return const Color(0xFFE74C3C);
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color.withValues(alpha: 0.15),
            border: Border.all(color: _color.withValues(alpha: 0.4), width: 1),
          ),
        ),
        // Core dot
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color,
            boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)],
          ),
        ),
      ],
    );
  }
}
