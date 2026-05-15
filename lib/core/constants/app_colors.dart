import 'package:flutter/material.dart';

/// Brand palette — used by [AppTheme] and [BrandThemeExtension].
abstract final class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);

  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentViolet = Color(0xFF8B5CF6);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceVariant = Color(0xFF1F2937);

  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Legacy alias used in some widgets.
  static const Color secondary = accentCyan;
  static const Color surfaceTint = Color(0xFFE0E7FF);
}
