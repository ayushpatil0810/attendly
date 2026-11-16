import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// App ThemeData configuration for light and dark themes.
abstract final class AppTheme {
  // ─────────────────────────────────────────────
  // Light Theme
  // ─────────────────────────────────────────────

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.warmWhite,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.inkViolet,
        onPrimary: AppColors.pureWhite,
        primaryContainer: AppColors.softLavender,
        onPrimaryContainer: AppColors.ink,
        secondary: AppColors.brandMint,
        onSecondary: AppColors.ink,
        secondaryContainer: AppColors.softMint,
        onSecondaryContainer: AppColors.ink,
        tertiary: AppColors.brandPeach,
        onTertiary: AppColors.ink,
        error: AppColors.inkCoral,
        onError: AppColors.pureWhite,
        errorContainer: AppColors.softCoral,
        onErrorContainer: AppColors.ink,
        surface: AppColors.pureWhite,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.surfaceTint,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
      ),
      textTheme: const TextTheme(
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
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.warmWhite,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: AppTypography.screenTitle,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pureWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.subtleInk,
        ),
        labelStyle: AppTypography.labelMedium,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: AppColors.inkViolet, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: AppColors.inkCoral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: AppColors.inkCoral, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.pureWhite,
        modalBackgroundColor: AppColors.pureWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        showDragHandle: false,
        dragHandleColor: AppColors.divider,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.pureWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.pureWhite,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Dark Theme
  // ─────────────────────────────────────────────

  static ThemeData get darkTheme {
    const background = Color(0xFF12111A);
    const surface = Color(0xFF1C1A26);
    const surfaceElevated = Color(0xFF262332);
    const border = Color(0xFF383446);
    const divider = Color(0xFF302D3C);

    const primary = Color(0xFFB9A5FF);
    const primaryContainer = Color(0xFF39304F);

    const mint = Color(0xFF8EDCC5);
    const mintContainer = Color(0xFF263E39);

    const peach = Color(0xFFFFB995);
    const coral = Color(0xFFFF8F91);

    const ink = Color(0xFFF3EFFB);
    const mutedInk = Color(0xFFAAA4B8);
    const subtleInk = Color(0xFF858093);

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: Color(0xFF211936),
        primaryContainer: primaryContainer,
        onPrimaryContainer: Color(0xFFE8DEFF),
        secondary: mint,
        onSecondary: Color(0xFF19332C),
        secondaryContainer: mintContainer,
        onSecondaryContainer: Color(0xFFC2F4E3),
        tertiary: peach,
        onTertiary: Color(0xFF382013),
        error: coral,
        onError: Color(0xFF3B1119),
        errorContainer: Color(0xFF51252D),
        onErrorContainer: Color(0xFFFFDADB),
        surface: surface,
        onSurface: ink,
        surfaceContainerHighest: surfaceElevated,
        outline: border,
        outlineVariant: divider,
      ),
      textTheme: const TextTheme(
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
      ).apply(bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.screenTitle,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: subtleInk),
        labelStyle: AppTypography.labelMedium.copyWith(color: mutedInk),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: coral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: coral, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        showDragHandle: false,
        dragHandleColor: divider,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: ink),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
