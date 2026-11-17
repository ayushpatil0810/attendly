import 'package:flutter/material.dart';

import 'app_palettes.dart';
import 'app_theme_colors.dart';

/// Supported themes in Attendly.
enum AppThemeId {
  lavenderDream(
    id: 'lavender_dream',
    name: 'Lavender Dream',
    subtitle: 'Soft violet & mint',
    lightColors: AppPalettes.lavenderDreamLight,
    darkColors: AppPalettes.lavenderDreamDark,
    previewColors: [
      Color(0xFF9278F2),
      Color(0xFF8BE4D0),
      Color(0xFFFF929B),
      Color(0xFFFFB49F),
    ],
  ),
  oceanBreeze(
    id: 'ocean_breeze',
    name: 'Ocean Breeze',
    subtitle: 'Coastal sky blue & seafoam',
    lightColors: AppPalettes.oceanBreezeLight,
    darkColors: AppPalettes.oceanBreezeDark,
    previewColors: [
      Color(0xFF4EA8DE),
      Color(0xFF64DFDF),
      Color(0xFFFF8E9A),
      Color(0xFFF8AD9D),
    ],
  ),
  peachBlossom(
    id: 'peach_blossom',
    name: 'Peach Blossom',
    subtitle: 'Warm apricot & sunny cream',
    lightColors: AppPalettes.peachBlossomLight,
    darkColors: AppPalettes.peachBlossomDark,
    previewColors: [
      Color(0xFFFF8E72),
      Color(0xFF76D7C4),
      Color(0xFFFF758F),
      Color(0xFFFFB5A7),
    ],
  ),
  sageGarden(
    id: 'sage_garden',
    name: 'Sage Garden',
    subtitle: 'Calm eucalyptus & earthy terracotta',
    lightColors: AppPalettes.sageGardenLight,
    darkColors: AppPalettes.sageGardenDark,
    previewColors: [
      Color(0xFF6B9E78),
      Color(0xFF52B788),
      Color(0xFFE07A5F),
      Color(0xFFF4A261),
    ],
  ),
  midnightBlue(
    id: 'midnight_blue',
    name: 'Midnight Blue',
    subtitle: 'Twilight navy & cornflower pastel',
    lightColors: AppPalettes.midnightBlueLight,
    darkColors: AppPalettes.midnightBlueDark,
    previewColors: [
      Color(0xFF4F6DCD),
      Color(0xFF5CC8BD),
      Color(0xFFF26A7A),
      Color(0xFFF8B195),
    ],
  ),
  buttercream(
    id: 'buttercream',
    name: 'Buttercream',
    subtitle: 'Warm golden vanilla & honey amber',
    lightColors: AppPalettes.buttercreamLight,
    darkColors: AppPalettes.buttercreamDark,
    previewColors: [
      Color(0xFFE49B38),
      Color(0xFF72C598),
      Color(0xFFE86A61),
      Color(0xFFF3A66B),
    ],
  ),
  roseQuartz(
    id: 'rose_quartz',
    name: 'Rose Quartz',
    subtitle: 'Powdery dusty rose & cranberry',
    lightColors: AppPalettes.roseQuartzLight,
    darkColors: AppPalettes.roseQuartzDark,
    previewColors: [
      Color(0xFFD96B8A),
      Color(0xFF6BC4B0),
      Color(0xFFE86576),
      Color(0xFFF2A7A4),
    ],
  ),
  graphiteMint(
    id: 'graphite_mint',
    name: 'Graphite Mint',
    subtitle: 'Cool slate & vibrant spearmint',
    lightColors: AppPalettes.graphiteMintLight,
    darkColors: AppPalettes.graphiteMintDark,
    previewColors: [
      Color(0xFF2A9D8F),
      Color(0xFF48CAE4),
      Color(0xFFE76F51),
      Color(0xFFF4A261),
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
    if (id == null) return AppThemeId.lavenderDream;
    return AppThemeId.values.firstWhere(
      (theme) => theme.id == id,
      orElse: () => AppThemeId.lavenderDream,
    );
  }
}
