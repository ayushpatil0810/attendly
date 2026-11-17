import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palettes.dart';
import 'app_radius.dart';
import 'app_theme_colors.dart';
import 'app_theme_id.dart';
import 'app_typography.dart';

/// App ThemeData configuration for all 8 pastel themes across light and dark appearances.
abstract final class AppTheme {
  /// Currently active theme tokens for global/static access.
  /// Kept in sync by AttendlyApp on build.
  static AppThemeColors currentColors = AppPalettes.lavenderDreamLight;

  static void setCurrentColors(AppThemeColors colors) {
    currentColors = colors;
  }

  // ─────────────────────────────────────────────
  // Theme Builder for Any Theme & Brightness
  // ─────────────────────────────────────────────

  static ThemeData buildTheme(AppThemeId themeId, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = themeId.colorsFor(brightness);

    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.brandPrimaryInk,
      onPrimary: isDark ? colors.background : Colors.white,
      primaryContainer: colors.brandPrimarySoft,
      onPrimaryContainer: colors.brandPrimaryInk,
      secondary: colors.accentMint,
      onSecondary: isDark ? colors.background : colors.textPrimary,
      secondaryContainer: colors.accentMintSoft,
      onSecondaryContainer: colors.accentMintInk,
      tertiary: colors.accentPeach,
      onTertiary: isDark ? colors.background : colors.textPrimary,
      error: colors.accentCoralInk,
      onError: Colors.white,
      errorContainer: colors.accentCoralSoft,
      onErrorContainer: colors.accentCoralInk,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainer: colors.surface,
      surfaceContainerLow: colors.surface,
      surfaceContainerLowest: colors.background,
      surfaceContainerHighest: colors.surfaceSubtle,
      surfaceDim: colors.background,
      surfaceBright: colors.surfaceElevated,
      outline: colors.border,
      outlineVariant: colors.divider,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.surface,
      cardColor: colors.surface,
      dialogBackgroundColor: colors.surface,
      colorScheme: colorScheme,
      extensions: [colors],
      textTheme: (isDark
          ? const TextTheme(
              headlineLarge: AppTypography.heroNumber,
              headlineMedium: AppTypography.metricLarge,
              headlineSmall: AppTypography.screenTitle,
              titleLarge: AppTypography.sectionTitle,
              titleMedium: AppTypography.itemTitle,
              titleSmall: AppTypography.labelLarge,
              bodyLarge: AppTypography.bodyLarge,
              bodyMedium: AppTypography.bodyMedium,
              bodySmall: AppTypography.bodyMuted,
              labelLarge: AppTypography.labelLarge,
              labelMedium: AppTypography.labelMedium,
              labelSmall: AppTypography.labelSmall,
            ).apply(
              bodyColor: colors.textPrimary,
              displayColor: colors.textPrimary,
            )
          : const TextTheme(
              headlineLarge: AppTypography.heroNumber,
              headlineMedium: AppTypography.metricLarge,
              headlineSmall: AppTypography.screenTitle,
              titleLarge: AppTypography.sectionTitle,
              titleMedium: AppTypography.itemTitle,
              titleSmall: AppTypography.labelLarge,
              bodyLarge: AppTypography.bodyLarge,
              bodyMedium: AppTypography.bodyMedium,
              bodySmall: AppTypography.bodyMuted,
              labelLarge: AppTypography.labelLarge,
              labelMedium: AppTypography.labelMedium,
              labelSmall: AppTypography.labelSmall,
            ).apply(
              bodyColor: colors.textPrimary,
              displayColor: colors.textPrimary,
            )),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        titleTextStyle: AppTypography.screenTitle.copyWith(
          color: colors.textPrimary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: BorderSide(color: colors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: colors.textTertiary,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: colors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colors.brandPrimaryInk, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colors.accentCoralInk),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colors.accentCoralInk, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        showDragHandle: false,
        dragHandleColor: colors.divider,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        textStyle: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.dockBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.brandPrimarySoft,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: colors.textPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Convenience getters for default theme
  static ThemeData get lightTheme =>
      buildTheme(AppThemeId.lavenderDream, Brightness.light);

  static ThemeData get darkTheme =>
      buildTheme(AppThemeId.lavenderDream, Brightness.dark);
}
