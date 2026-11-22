import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palettes.dart';
import 'app_radius.dart';
import 'app_theme_colors.dart';
import 'app_typography.dart';

/// App ThemeData configuration for Attendly's unified Light and Dark themes.
abstract final class AppTheme {
  /// Currently active theme tokens for global/static access.
  /// Kept in sync by AttendlyApp on build.
  static AppThemeColors currentColors = AppPalettes.light;

  static void setCurrentColors(AppThemeColors colors) {
    currentColors = colors;
  }

  // ─────────────────────────────────────────────
  // Theme Builder for Brightness
  // ─────────────────────────────────────────────

  static ThemeData buildTheme(dynamic first, [Brightness? second]) {
    final Brightness brightness = (first is Brightness)
        ? first
        : (second ?? Brightness.light);
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppPalettes.dark : AppPalettes.light;

    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.brandPrimary,
      onPrimary: Colors.white,
      primaryContainer: colors.brandPrimarySoft,
      onPrimaryContainer: colors.brandPrimary,
      secondary: colors.accentGreen,
      onSecondary: Colors.white,
      secondaryContainer: colors.surfaceSubtle,
      onSecondaryContainer: colors.textPrimary,
      tertiary: colors.accentOrange,
      onTertiary: Colors.white,
      error: colors.accentRed,
      onError: Colors.white,
      errorContainer: colors.surfaceSubtle,
      onErrorContainer: colors.accentRed,
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
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: colors.surfaceSubtle.withValues(
        alpha: isDark ? 0.30 : 0.45,
      ),
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.surface,
      cardColor: colors.surface,
      dialogBackgroundColor: colors.surface,
      colorScheme: colorScheme,
      extensions: [colors],
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.brandPrimary;
          }
          return isDark ? const Color(0xFF39393D) : const Color(0xFFE9E9EA);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.brandPrimary,
        inactiveTrackColor: colors.track,
        thumbColor: colors.brandPrimary,
        overlayColor: colors.brandPrimary.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
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
          borderSide: BorderSide(color: colors.brandPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colors.accentRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colors.accentRed, width: 1.5),
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor:
              isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B),
          foregroundColor:
              isDark ? const Color(0xFF09090B) : Colors.white,
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B),
          foregroundColor:
              isDark ? const Color(0xFF09090B) : Colors.white,
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border, width: 1.2),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.textPrimary,
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
    );
  }

  // Convenience getters for default theme
  static ThemeData get lightTheme => buildTheme(Brightness.light);

  static ThemeData get darkTheme => buildTheme(Brightness.dark);
}
