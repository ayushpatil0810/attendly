import 'package:flutter/material.dart';

import 'app_palettes.dart';
import 'app_theme_colors.dart';

/// Supported themes in Attendly.
///
/// Attendly now features a single unified, professional design system with
/// dedicated Light and Dark modes. The legacy identifiers are retained as
/// backward-compatible aliases.
enum AppThemeId {
  attendly(
    id: 'attendly',
    name: 'Attendly',
    subtitle: 'Professional Cobalt & Midnight Slate',
    lightColors: AppPalettes.light,
    darkColors: AppPalettes.dark,
    previewColors: [
      Color(0xFF4361EE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  ),
  lavenderDream(
    id: 'lavender_dream',
    name: 'Lavender Dream',
    subtitle: 'Classic',
    lightColors: AppPalettes.light,
    darkColors: AppPalettes.dark,
    previewColors: [
      Color(0xFF4361EE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  ),
  oceanBreeze(
    id: 'ocean_breeze',
    name: 'Ocean Breeze',
    subtitle: 'Classic',
    lightColors: AppPalettes.light,
    darkColors: AppPalettes.dark,
    previewColors: [
      Color(0xFF4361EE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  ),
  peachBlossom(
    id: 'peach_blossom',
    name: 'Peach Blossom',
    subtitle: 'Classic',
    lightColors: AppPalettes.light,
    darkColors: AppPalettes.dark,
    previewColors: [
      Color(0xFF4361EE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  ),
  sageGarden(
    id: 'sage_garden',
    name: 'Sage Garden',
    subtitle: 'Classic',
    lightColors: AppPalettes.light,
    darkColors: AppPalettes.dark,
    previewColors: [
      Color(0xFF4361EE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  ),
  midnightBlue(
    id: 'midnight_blue',
    name: 'Midnight Blue',
    subtitle: 'Classic',
    lightColors: AppPalettes.light,
    darkColors: AppPalettes.dark,
    previewColors: [
      Color(0xFF4361EE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  ),
  buttercream(
    id: 'buttercream',
    name: 'Buttercream',
    subtitle: 'Classic',
    lightColors: AppPalettes.light,
    darkColors: AppPalettes.dark,
    previewColors: [
      Color(0xFF4361EE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  ),
  roseQuartz(
    id: 'rose_quartz',
    name: 'Rose Quartz',
    subtitle: 'Classic',
    lightColors: AppPalettes.light,
    darkColors: AppPalettes.dark,
    previewColors: [
      Color(0xFF4361EE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  ),
  graphiteMint(
    id: 'graphite_mint',
    name: 'Graphite Mint',
    subtitle: 'Classic',
    lightColors: AppPalettes.light,
    darkColors: AppPalettes.dark,
    previewColors: [
      Color(0xFF4361EE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  );

  const AppThemeId({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.lightColors,
    required this.darkColors,
    required this.previewColors,
  });

  final String id;
  final String name;
  final String subtitle;
  final AppThemeColors lightColors;
  final AppThemeColors darkColors;
  final List<Color> previewColors;

  AppThemeColors colorsFor(Brightness brightness) {
    return brightness == Brightness.dark ? darkColors : lightColors;
  }

  static AppThemeId fromId(String? id) {
    if (id == null) return AppThemeId.attendly;
    return AppThemeId.values.firstWhere(
      (theme) => theme.id == id,
      orElse: () => AppThemeId.attendly,
    );
  }
}
