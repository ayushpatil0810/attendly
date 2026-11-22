import 'package:flutter/material.dart';

/// Centralized semantic design tokens packaged as a Flutter [ThemeExtension].
/// Every theme (Light and Dark) defines an instance of this class.
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.brandPrimary,
    required this.accentGreen,
    required this.accentRed,
    required this.accentOrange,
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

  // Primary Brand Hue
  final Color brandPrimary;
  Color get brandPrimarySoft =>
      brandPrimary.withValues(alpha: isDark ? 0.16 : 0.12);

  // Semantic Status Hues: Attendance & Health
  final Color accentGreen;
  Color get present => accentGreen;
  Color get onPresent => isDark ? accentGreen : const Color(0xFF248A3D);

  final Color accentRed;
  Color get absent => accentRed;
  Color get onAbsent => isDark ? accentRed : const Color(0xFFD70015);
  Color get warning => accentRed;

  final Color accentOrange;
  Color get accentOrangeSoft =>
      accentOrange.withValues(alpha: isDark ? 0.16 : 0.12);
  Color get onProvisional => isDark ? accentOrange : const Color(0xFFC97000);

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
  Color get neutral => textSecondary;
  Color get primaryAction => isDark ? brandPrimary : const Color(0xFF0056B3);
  Color get cardBackground => surface;
  Color get dockBackground => surface.withValues(alpha: isDark ? 0.95 : 0.97);

  @override
  AppThemeColors copyWith({
    Color? brandPrimary,
    Color? accentGreen,
    Color? accentRed,
    Color? accentOrange,
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
      accentGreen: accentGreen ?? this.accentGreen,
      accentRed: accentRed ?? this.accentRed,
      accentOrange: accentOrange ?? this.accentOrange,
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
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      accentRed: Color.lerp(accentRed, other.accentRed, t)!,
      accentOrange: Color.lerp(accentOrange, other.accentOrange, t)!,
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
