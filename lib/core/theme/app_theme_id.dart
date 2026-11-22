import 'package:flutter/material.dart';

import 'app_palettes.dart';
import 'app_theme_colors.dart';

/// Single unified design system theme identifier for Attendly.
enum AppThemeId {
  attendly(
    id: 'attendly',
    name: 'Attendly',
    subtitle: 'Apple HIG Design System',
    lightColors: AppPalettes.light,
    darkColors: AppPalettes.dark,
    previewColors: [
      Color(0xFF007AFF),
      Color(0xFF34C759),
      Color(0xFFFF9500),
      Color(0xFFFF3B30),
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

  static AppThemeId fromId(String? id) => AppThemeId.attendly;
}
