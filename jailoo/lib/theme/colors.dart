import 'package:flutter/material.dart';

class JailooColors {
  static const healthy    = Color(0xFF22C55E);
  static const recovering = Color(0xFFFACC15);
  static const banned     = Color(0xFFEF4444);

  static const bg         = Color(0xFF09090B);
  static const surface    = Color(0xFF18181B);
  static const surface2   = Color(0xFF27272A);

  static const textPrimary = Color(0xFFFAFAFA);
  static const textMuted   = Color(0xFFA1A1AA);

  static const border      = Color(0xFF27272A);
  static const borderLight = Color(0xFF3F3F46);

  static const accent      = Color(0xFF22C55E);

  static Color statusColor(String status) {
    switch (status) {
      case 'healthy':    return healthy;
      case 'recovering': return recovering;
      case 'banned':     return banned;
      default:           return textMuted;
    }
  }
}
