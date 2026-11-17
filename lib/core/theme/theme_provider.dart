import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/home_widget_service.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import 'app_theme.dart';
import 'app_theme_id.dart';

/// SharedPreferences keys for persistent theme settings.
const String prefThemeModeKey = 'pref_theme_mode_v1';
const String prefThemeIdKey = 'pref_color_theme_id_v1';

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
      final themeId = ref.read(activeThemeIdProvider);
      final isDark = state == ThemeMode.dark;
      final colors = themeId.colorsFor(
        isDark ? Brightness.dark : Brightness.light,
      );
      ref
          .read(homeWidgetServiceProvider)
          .updateThemeColors(
            themeId: themeId.id,
            isDark: isDark,
            primaryColor: colors.brandPrimary.toARGB32(),
            backgroundColor: colors.background.toARGB32(),
          );
    } catch (_) {}
  }
}

/// Manages the active pastel [AppThemeId] (Lavender Dream, Ocean Breeze, etc.).
class ActiveThemeIdNotifier extends Notifier<AppThemeId> {
  @override
  AppThemeId build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(prefThemeIdKey);
    return AppThemeId.fromId(stored);
  }

  Future<void> setThemeId(AppThemeId themeId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(prefThemeIdKey, themeId.id);
    state = themeId;
    _syncWidget();
  }

  void _syncWidget() {
    try {
      final mode = ref.read(themeModeProvider);
      final isDark = mode == ThemeMode.dark;
      final colors = state.colorsFor(
        isDark ? Brightness.dark : Brightness.light,
      );
      ref
          .read(homeWidgetServiceProvider)
          .updateThemeColors(
            themeId: state.id,
            isDark: isDark,
            primaryColor: colors.brandPrimary.toARGB32(),
            backgroundColor: colors.background.toARGB32(),
          );
    } catch (_) {}
  }
}

/// State object combining appearance mode and active color theme.
class AppThemeState {
  const AppThemeState({required this.themeMode, required this.themeId});

  final ThemeMode themeMode;
  final AppThemeId themeId;

  ThemeData get lightTheme => AppTheme.buildTheme(themeId, Brightness.light);
  ThemeData get darkTheme => AppTheme.buildTheme(themeId, Brightness.dark);
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final activeThemeIdProvider =
    NotifierProvider<ActiveThemeIdNotifier, AppThemeId>(
      ActiveThemeIdNotifier.new,
    );

/// Combined provider exposing both mode and active color theme.
final themePreferencesProvider = Provider<AppThemeState>((ref) {
  final mode = ref.watch(themeModeProvider);
  final themeId = ref.watch(activeThemeIdProvider);
  return AppThemeState(themeMode: mode, themeId: themeId);
});
