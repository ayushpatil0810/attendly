import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/home_widget_service.dart';
import '../providers/shared_preferences_provider.dart';
import 'app_palettes.dart';
import 'app_theme.dart';
import 'app_theme_id.dart';

/// SharedPreferences keys for persistent theme settings.
const String prefThemeModeKey = 'pref_theme_mode_v1';

/// Manages the application's [ThemeMode] (system, light, dark).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(prefThemeModeKey);
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(prefThemeModeKey, value);
    state = mode;
    _syncWidget();
  }

  void _syncWidget() {
    try {
      final isDark = switch (state) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark,
      };
      final colors = isDark ? AppPalettes.dark : AppPalettes.light;
      ref
          .read(homeWidgetServiceProvider)
          .updateThemeColors(
            themeId: 'attendly',
            isDark: isDark,
            primaryColor: colors.brandPrimary.toARGB32(),
            backgroundColor: colors.background.toARGB32(),
          );
    } catch (_) {}
  }
}

/// Compatibility notifier providing the single unified professional theme ID.
class ActiveThemeIdNotifier extends Notifier<AppThemeId> {
  @override
  AppThemeId build() {
    return AppThemeId.attendly;
  }

  Future<void> setThemeId(AppThemeId themeId) async {
    state = AppThemeId.attendly;
  }
}

/// State object combining appearance mode and active color theme.
class AppThemeState {
  const AppThemeState({
    required this.themeMode,
    this.themeId = AppThemeId.attendly,
  });

  final ThemeMode themeMode;
  final AppThemeId themeId;

  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final activeThemeIdProvider =
    NotifierProvider<ActiveThemeIdNotifier, AppThemeId>(
      ActiveThemeIdNotifier.new,
    );

/// Combined provider exposing appearance mode and theme state.
final themePreferencesProvider = Provider<AppThemeState>((ref) {
  final mode = ref.watch(themeModeProvider);
  return AppThemeState(themeMode: mode, themeId: AppThemeId.attendly);
});
