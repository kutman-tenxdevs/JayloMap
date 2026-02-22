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
    surface: Color(0xFFF5F7F5),
    surface2: Color(0xFFE8EDEA),
    textPrimary: Color(0xFF111827),
    textMuted: Color(0xFF6B7280),
    border: Color(0xFFEBEFF0),
    accent: Color(0xFF00C795),
  );

  static const dark = JailooColors._(
    bg: Color(0xFF0F1A14),
    surface: Color(0xFF182420),
    surface2: Color(0xFF243028),
    textPrimary: Color(0xFFF3F8F5),
    textMuted: Color(0xFF8BA898),
    border: Color(0xFF243028),
    accent: Color(0xFF00E5AD),
  );

  static const healthy    = Color(0xFF00C795);
  static const recovering = Color(0xFFF5A623);
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
      case 'healthy':    return '#00C795';
      case 'recovering': return '#F5A623';
      case 'banned':     return '#EF4444';
      default:           return '#6B7280';
    }
  }

  static JailooColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
