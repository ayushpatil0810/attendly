import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// App ThemeData configuration for light theme only according to DESIGN.md
abstract final class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.warmWhite,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.brandViolet,
        onPrimary: AppColors.pureWhite,
        primaryContainer: AppColors.softLavender,
        onPrimaryContainer: AppColors.ink,
        secondary: AppColors.brandMint,
        onSecondary: AppColors.ink,
        secondaryContainer: AppColors.softMint,
        onSecondaryContainer: AppColors.ink,
        tertiary: AppColors.brandPeach,
        onTertiary: AppColors.ink,
        error: AppColors.brandCoral,
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
          borderSide: const BorderSide(
            color: AppColors.brandViolet,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: AppColors.brandCoral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: AppColors.brandCoral, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.pureWhite,
        modalBackgroundColor: AppColors.pureWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        showDragHandle: true,
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
}
