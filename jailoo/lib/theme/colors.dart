import 'package:flutter/material.dart';

class JailooColors {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color textPrimary;
  final Color textMuted;
  final Color border;
  final Color accent;

  const JailooColors._({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
    required this.accent,
  });

  static const light = JailooColors._(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF4F4F5),
    surface2: Color(0xFFE4E4E7),
    textPrimary: Color(0xFF09090B),
    textMuted: Color(0xFF71717A),
    border: Color(0xFFE4E4E7),
    accent: Color(0xFF16A34A),
  );

  static const dark = JailooColors._(
    bg: Color(0xFF09090B),
    surface: Color(0xFF18181B),
    surface2: Color(0xFF27272A),
    textPrimary: Color(0xFFFAFAFA),
    textMuted: Color(0xFFA1A1AA),
    border: Color(0xFF27272A),
    accent: Color(0xFF22C55E),
  );

  static const healthy    = Color(0xFF22C55E);
  static const recovering = Color(0xFFFACC15);
  static const banned     = Color(0xFFEF4444);

  static Color statusColor(String status) {
    switch (status) {
      case 'healthy':    return healthy;
      case 'recovering': return recovering;
      case 'banned':     return banned;
      default:           return const Color(0xFF71717A);
    }
  }

  // Hex strings for MapLibre GL layer properties
  static String statusColorHex(String status) {
    switch (status) {
      case 'healthy':    return '#22C55E';
      case 'recovering': return '#F59E0B';
      case 'banned':     return '#EF4444';
      default:           return '#71717A';
    }
  }

  static JailooColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
