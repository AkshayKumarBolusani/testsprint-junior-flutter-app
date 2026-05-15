import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Extra tokens beyond [ColorScheme] — gradients, glows, card depth.
@immutable
class BrandThemeExtension extends ThemeExtension<BrandThemeExtension> {
  const BrandThemeExtension({
    required this.accentCyan,
    required this.accentViolet,
    required this.success,
    required this.warning,
    required this.error,
    required this.primaryGradient,
    required this.cardShadow,
    required this.subtleBorder,
    required this.glassFill,
  });

  final Color accentCyan;
  final Color accentViolet;
  final Color success;
  final Color warning;
  final Color error;
  final LinearGradient primaryGradient;
  final List<BoxShadow> cardShadow;
  final Color subtleBorder;
  final Color glassFill;

  static BrandThemeExtension light(ColorScheme scheme) {
    return BrandThemeExtension(
      accentCyan: AppColors.accentCyan,
      accentViolet: AppColors.accentViolet,
      success: AppColors.success,
      warning: AppColors.warning,
      error: AppColors.error,
      primaryGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryDark],
      ),
      cardShadow: [
        BoxShadow(
          color: AppColors.darkBg.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.darkBg.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      subtleBorder: AppColors.darkBg.withValues(alpha: 0.06),
      glassFill: Colors.white.withValues(alpha: 0.72),
    );
  }

  static BrandThemeExtension dark(ColorScheme scheme) {
    return BrandThemeExtension(
      accentCyan: AppColors.accentCyan,
      accentViolet: AppColors.accentViolet,
      success: AppColors.success,
      warning: AppColors.warning,
      error: AppColors.error,
      primaryGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3B82F6), AppColors.primaryDark],
      ),
      cardShadow: [
        BoxShadow(
          color: AppColors.accentCyan.withValues(alpha: 0.12),
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
      subtleBorder: Colors.white.withValues(alpha: 0.08),
      glassFill: Colors.white.withValues(alpha: 0.06),
    );
  }

  @override
  BrandThemeExtension copyWith({
    Color? accentCyan,
    Color? accentViolet,
    Color? success,
    Color? warning,
    Color? error,
    LinearGradient? primaryGradient,
    List<BoxShadow>? cardShadow,
    Color? subtleBorder,
    Color? glassFill,
  }) {
    return BrandThemeExtension(
      accentCyan: accentCyan ?? this.accentCyan,
      accentViolet: accentViolet ?? this.accentViolet,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      cardShadow: cardShadow ?? this.cardShadow,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      glassFill: glassFill ?? this.glassFill,
    );
  }

  @override
  BrandThemeExtension lerp(ThemeExtension<BrandThemeExtension>? other, double t) {
    if (other is! BrandThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension BrandThemeContext on BuildContext {
  BrandThemeExtension get brand => Theme.of(this).extension<BrandThemeExtension>()!;
}
