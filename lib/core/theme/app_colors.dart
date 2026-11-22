import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'app_theme_colors.dart';

/// Centralized color tokens.
///
/// Tokens dynamically resolve to the active theme's colors ([AppTheme.currentColors]),
/// allowing existing code to automatically respond to theme and brightness changes.
///
/// For explicit context-bound access, use [AppColors.of(context)] or [context.colors].
abstract final class AppColors {
  /// Obtain the active [AppThemeColors] from the nearest [Theme] in the widget tree,
  /// falling back to [AppTheme.currentColors].
  static AppThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.currentColors;
  }

  // Brand Palette (Apple HIG Blue)
  static Color get brandPrimary => AppTheme.currentColors.brandPrimary;
  static Color get brandPrimarySoft => AppTheme.currentColors.brandPrimarySoft;

  // Semantic Status Hues: Attendance & Health (Apple Green, Red, Orange)
  static Color get accentGreen => AppTheme.currentColors.accentGreen;
  static Color get accentRed => AppTheme.currentColors.accentRed;
  static Color get accentOrange => AppTheme.currentColors.accentOrange;

  // Semantic mappings
  static Color get present => AppTheme.currentColors.present;
  static Color get absent => AppTheme.currentColors.absent;
  static Color get onPresent => AppTheme.currentColors.onPresent;
  static Color get onAbsent => AppTheme.currentColors.onAbsent;
  static Color get onProvisional => AppTheme.currentColors.onProvisional;
  static Color get primaryAction => AppTheme.currentColors.primaryAction;
  static Color get warning => AppTheme.currentColors.warning;
  static Color get neutral => AppTheme.currentColors.neutral;

  // Surfaces & Backgrounds
  static Color get background => AppTheme.currentColors.background;
  static Color get surface => AppTheme.currentColors.surface;
  static Color get surfaceSubtle => AppTheme.currentColors.surfaceSubtle;
  static Color get surfaceElevated => AppTheme.currentColors.surfaceElevated;

  // Text & Ink
  static Color get textPrimary => AppTheme.currentColors.textPrimary;
  static Color get textSecondary => AppTheme.currentColors.textSecondary;
  static Color get textTertiary => AppTheme.currentColors.textTertiary;
  static Color get ink => AppTheme.currentColors.textPrimary;
  static Color get mutedInk => AppTheme.currentColors.textSecondary;
  static Color get subtleInk => AppTheme.currentColors.textTertiary;

  // Structural & Dividers
  static Color get divider => AppTheme.currentColors.divider;
  static Color get track => AppTheme.currentColors.track;
  static Color get border => AppTheme.currentColors.border;

  // Dock & Overlays
  static Color get dockBackground => AppTheme.currentColors.dockBackground;
  static Color get overlayScrim =>
      AppTheme.currentColors.textPrimary.withValues(alpha: 0.25);
}

/// Syntactic sugar extension on [BuildContext] for ergonomic color access.
extension BuildContextThemeX on BuildContext {
  AppThemeColors get colors => AppColors.of(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
