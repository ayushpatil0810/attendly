import 'package:flutter/material.dart';

import 'app_theme_colors.dart';

/// Concrete palette definitions translating Apple's Human Interface Guidelines (HIG)
/// to Attendly:
/// - Light: Apple Grouped Background (#F2F2F7), pure-white cards (#FFFFFF), hairline dividers (#C6C6C8).
/// - Dark: Apple True OLED Black (#000000), System Gray 6 cards (#1C1C1E), System Gray 5 containers (#2C2C2E).
/// - Semantic Status: Canonical Apple System Green (#34C759), Orange (#FF9500), and Red (#FF3B30).
abstract final class AppPalettes {
  // ─────────────────────────────────────────────────────────────────────────
  // Apple HIG Light Theme (Grouped Canvas & Inset Cards)
  // ─────────────────────────────────────────────────────────────────────────
  static const AppThemeColors light = AppThemeColors(
    brandPrimary: Color(0xFF1C1C1E),
    brandPrimaryInk: Color(0xFF000000),
    brandPrimarySoft: Color(0xFFE5E5EA),
    brandSecondary: Color(0xFF2C2C2E),
    brandSecondaryInk: Color(0xFF1C1C1E),
    brandSecondarySoft: Color(0xFFE5E5EA),
    accentMint: Color(0xFF34C759),
    accentMintInk: Color(0xFF248A3D),
    accentMintSoft: Color(0xFFE8F9ED),
    accentCoral: Color(0xFFFF3B30),
    accentCoralInk: Color(0xFFD70015),
    accentCoralSoft: Color(0xFFFFEBEA),
    accentPeach: Color(0xFFFF9500),
    accentPeachInk: Color(0xFFC97000),
    accentPeachSoft: Color(0xFFFFF4E5),
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFE5E5EA),
    surfaceElevated: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF6C6C70),
    textTertiary: Color(0xFFAEAEB2),
    border: Color(0xFFE5E5EA),
    divider: Color(0xFFC6C6C8),
    track: Color(0xFFE5E5EA),
    isDark: false,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Apple HIG Dark Theme (True OLED Black Canvas & System Gray 6 Cards)
  // ─────────────────────────────────────────────────────────────────────────
  static const AppThemeColors dark = AppThemeColors(
    brandPrimary: Color(0xFFFFFFFF),
    brandPrimaryInk: Color(0xFFFFFFFF),
    brandPrimarySoft: Color(0xFF2C2C2E),
    brandSecondary: Color(0xFFE5E5EA),
    brandSecondaryInk: Color(0xFFFFFFFF),
    brandSecondarySoft: Color(0xFF1C1C1E),
    accentMint: Color(0xFF30D158),
    accentMintInk: Color(0xFFD1FAD7),
    accentMintSoft: Color(0xFF0B3814),
    accentCoral: Color(0xFFFF453A),
    accentCoralInk: Color(0xFFFFD2D0),
    accentCoralSoft: Color(0xFF4D0C08),
    accentPeach: Color(0xFFFF9F0A),
    accentPeachInk: Color(0xFFFFE2B8),
    accentPeachSoft: Color(0xFF4D2C02),
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceSubtle: Color(0xFF2C2C2E),
    surfaceElevated: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF98989D),
    textTertiary: Color(0xFF636366),
    border: Color(0xFF2C2C2E),
    divider: Color(0xFF38383A),
    track: Color(0xFF2C2C2E),
    isDark: true,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Legacy aliases for backward compatibility across existing tests & callers
  // ─────────────────────────────────────────────────────────────────────────
  static const AppThemeColors lavenderDreamLight = light;
  static const AppThemeColors lavenderDreamDark = dark;
  static const AppThemeColors oceanBreezeLight = light;
  static const AppThemeColors oceanBreezeDark = dark;
  static const AppThemeColors peachBlossomLight = light;
  static const AppThemeColors peachBlossomDark = dark;
  static const AppThemeColors sageGardenLight = light;
  static const AppThemeColors sageGardenDark = dark;
  static const AppThemeColors midnightBlueLight = light;
  static const AppThemeColors midnightBlueDark = dark;
  static const AppThemeColors buttercreamLight = light;
  static const AppThemeColors buttercreamDark = dark;
  static const AppThemeColors roseQuartzLight = light;
  static const AppThemeColors roseQuartzDark = dark;
  static const AppThemeColors graphiteMintLight = light;
  static const AppThemeColors graphiteMintDark = dark;
}
