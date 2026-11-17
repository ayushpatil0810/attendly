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

  // Brand Palette
  static Color get brandViolet => AppTheme.currentColors.brandPrimary;
  static Color get brandMint => AppTheme.currentColors.accentMint;
  static Color get brandCoral => AppTheme.currentColors.accentCoral;
  static Color get brandPeach => AppTheme.currentColors.accentPeach;
  static Color get lavender => AppTheme.currentColors.brandSecondary;

  /// Readable text and small icons. Same hues as the pastels, darkened so
  /// body copy clears 4.5:1 on white and on the soft tinted surfaces.
  static Color get inkViolet => AppTheme.currentColors.brandPrimaryInk;
  static Color get inkMint => AppTheme.currentColors.accentMintInk;
  static Color get inkCoral => AppTheme.currentColors.accentCoralInk;
  static Color get inkPeach => AppTheme.currentColors.accentPeachInk;

  // Surfaces & Backgrounds
  static Color get warmWhite => AppTheme.currentColors.background;
  static Color get pureWhite => AppTheme.currentColors.surface;
  static Color get softLavender => AppTheme.currentColors.brandPrimarySoft;
  static Color get softMint => AppTheme.currentColors.accentMintSoft;
  static Color get softCoral => AppTheme.currentColors.accentCoralSoft;
  static Color get softPeach => AppTheme.currentColors.accentPeachSoft;
  static Color get surfaceTint => AppTheme.currentColors.surfaceSubtle;

  // Text & Ink
  static Color get ink => AppTheme.currentColors.textPrimary;
  static Color get mutedInk => AppTheme.currentColors.textSecondary;
  static Color get subtleInk => AppTheme.currentColors.textTertiary;

  // Structural & Dividers
  static Color get divider => AppTheme.currentColors.divider;
  static Color get track => AppTheme.currentColors.track;
  static Color get border => AppTheme.currentColors.border;

  // Semantic mappings
  static Color get present => AppTheme.currentColors.present;
  static Color get absent => AppTheme.currentColors.absent;
  static Color get onPresent => AppTheme.currentColors.onPresent;
  static Color get onAbsent => AppTheme.currentColors.onAbsent;
  static Color get onProvisional => AppTheme.currentColors.onProvisional;
  static Color get primaryAction => AppTheme.currentColors.primaryAction;
  static Color get warning => AppTheme.currentColors.warning;
  static Color get neutral => AppTheme.currentColors.neutral;

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
