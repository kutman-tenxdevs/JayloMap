import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../theme/colors.dart';

class ZoneMarker extends StatelessWidget {
  final Zone zone;
  const ZoneMarker({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final color = JailooColors.statusColor(zone.status);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
