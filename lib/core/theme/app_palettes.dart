import 'package:flutter/material.dart';

import 'app_theme_colors.dart';

/// Concrete palette definitions translating Apple's Human Interface Guidelines (HIG)
/// to Attendly:
/// - Light: Apple Grouped Background (#F2F2F7), pure-white cards (#FFFFFF), hairline dividers (#C6C6C8).
/// - Dark: Apple True OLED Black (#000000), System Gray 6 cards (#1C1C1E), System Gray 5 containers (#2C2C2E).
/// - Semantic Status: Canonical Apple System Green (#34C759 / #30D158), Red (#FF3B30 / #FF453A), and Orange (#FF9500 / #FF9F0A).
abstract final class AppPalettes {
  // ─────────────────────────────────────────────────────────────────────────
  // Apple HIG Light Theme (Grouped Canvas & Inset Cards)
  // ─────────────────────────────────────────────────────────────────────────
  static const AppThemeColors light = AppThemeColors(
    brandPrimary: Color(0xFF007AFF),
    accentGreen: Color(0xFF34C759),
    accentRed: Color(0xFFFF3B30),
    accentOrange: Color(0xFFFF9500),
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
    brandPrimary: Color(0xFF0A84FF),
    accentGreen: Color(0xFF30D158),
    accentRed: Color(0xFFFF453A),
    accentOrange: Color(0xFFFF9F0A),
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
}
