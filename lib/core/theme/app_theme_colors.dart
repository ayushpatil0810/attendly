import 'package:flutter/material.dart';

/// Centralized semantic design tokens packaged as a Flutter [ThemeExtension].
/// Every theme (Light and Dark) defines an instance of this class.
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.brandPrimary,
    required this.brandPrimaryInk,
    required this.brandPrimarySoft,
    required this.brandSecondary,
    required this.brandSecondaryInk,
    required this.brandSecondarySoft,
    required this.accentMint,
    required this.accentMintInk,
    required this.accentMintSoft,
    required this.accentCoral,
    required this.accentCoralInk,
    required this.accentCoralSoft,
    required this.accentPeach,
    required this.accentPeachInk,
    required this.accentPeachSoft,
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.track,
    required this.isDark,
  });

  // Primary Brand Hues
  final Color brandPrimary;
  final Color brandPrimaryInk;
  final Color brandPrimarySoft;

  // Secondary Brand Hues
  final Color brandSecondary;
  final Color brandSecondaryInk;
  final Color brandSecondarySoft;

  // Semantic Status Hues: Attendance & Health
  final Color accentMint;
  final Color accentMintInk;
  final Color accentMintSoft;

  final Color accentCoral;
  final Color accentCoralInk;
  final Color accentCoralSoft;

  final Color accentPeach;
  final Color accentPeachInk;
  final Color accentPeachSoft;

  // Surfaces & Canvas
  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color surfaceElevated;

  // Typography & Content
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Structural & Dividers
  final Color border;
  final Color divider;
  final Color track;

  // Appearance Mode
  final bool isDark;

  // Semantic Aliases
  Color get present => accentMint;
  Color get onPresent => accentMintInk;
  Color get absent => accentCoral;
  Color get onAbsent => accentCoralInk;
  Color get warning => accentCoralInk;
  Color get onProvisional => accentPeachInk;
  Color get neutral => textSecondary;
  Color get primaryAction => brandPrimaryInk;
  Color get cardBackground => surface;
  Color get dockBackground => surface.withValues(alpha: isDark ? 0.95 : 0.97);

  @override
  AppThemeColors copyWith({
    Color? brandPrimary,
    Color? brandPrimaryInk,
    Color? brandPrimarySoft,
    Color? brandSecondary,
    Color? brandSecondaryInk,
    Color? brandSecondarySoft,
    Color? accentMint,
    Color? accentMintInk,
    Color? accentMintSoft,
    Color? accentCoral,
    Color? accentCoralInk,
    Color? accentCoralSoft,
    Color? accentPeach,
    Color? accentPeachInk,
    Color? accentPeachSoft,
    Color? background,
    Color? surface,
    Color? surfaceSubtle,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? divider,
    Color? track,
    bool? isDark,
  }) {
    return AppThemeColors(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandPrimaryInk: brandPrimaryInk ?? this.brandPrimaryInk,
      brandPrimarySoft: brandPrimarySoft ?? this.brandPrimarySoft,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      brandSecondaryInk: brandSecondaryInk ?? this.brandSecondaryInk,
      brandSecondarySoft: brandSecondarySoft ?? this.brandSecondarySoft,
      accentMint: accentMint ?? this.accentMint,
      accentMintInk: accentMintInk ?? this.accentMintInk,
      accentMintSoft: accentMintSoft ?? this.accentMintSoft,
      accentCoral: accentCoral ?? this.accentCoral,
      accentCoralInk: accentCoralInk ?? this.accentCoralInk,
      accentCoralSoft: accentCoralSoft ?? this.accentCoralSoft,
      accentPeach: accentPeach ?? this.accentPeach,
      accentPeachInk: accentPeachInk ?? this.accentPeachInk,
      accentPeachSoft: accentPeachSoft ?? this.accentPeachSoft,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      track: track ?? this.track,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;

    return AppThemeColors(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandPrimaryInk: Color.lerp(brandPrimaryInk, other.brandPrimaryInk, t)!,
      brandPrimarySoft: Color.lerp(
        brandPrimarySoft,
        other.brandPrimarySoft,
        t,
      )!,
      brandSecondary: Color.lerp(brandSecondary, other.brandSecondary, t)!,
      brandSecondaryInk: Color.lerp(
        brandSecondaryInk,
        other.brandSecondaryInk,
        t,
      )!,
      brandSecondarySoft: Color.lerp(
        brandSecondarySoft,
        other.brandSecondarySoft,
        t,
      )!,
      accentMint: Color.lerp(accentMint, other.accentMint, t)!,
      accentMintInk: Color.lerp(accentMintInk, other.accentMintInk, t)!,
      accentMintSoft: Color.lerp(accentMintSoft, other.accentMintSoft, t)!,
      accentCoral: Color.lerp(accentCoral, other.accentCoral, t)!,
      accentCoralInk: Color.lerp(accentCoralInk, other.accentCoralInk, t)!,
      accentCoralSoft: Color.lerp(accentCoralSoft, other.accentCoralSoft, t)!,
      accentPeach: Color.lerp(accentPeach, other.accentPeach, t)!,
      accentPeachInk: Color.lerp(accentPeachInk, other.accentPeachInk, t)!,
      accentPeachSoft: Color.lerp(accentPeachSoft, other.accentPeachSoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      track: Color.lerp(track, other.track, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
