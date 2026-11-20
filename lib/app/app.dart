import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/theme/app_palettes.dart';
import 'package:attendly/core/theme/app_theme.dart';
import 'package:attendly/core/theme/theme_provider.dart';

import 'router/app_router.dart';

class AttendlyApp extends ConsumerWidget {
  const AttendlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themePreferencesProvider);

    final platformBrightness =
        MediaQuery.maybePlatformBrightnessOf(context) ??
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final effectiveBrightness = switch (themeState.themeMode) {
      ThemeMode.system => platformBrightness,
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
    };
    final activeColors = effectiveBrightness == Brightness.dark
        ? AppPalettes.dark
        : AppPalettes.light;
    AppTheme.setCurrentColors(activeColors);

    final isDark = effectiveBrightness == Brightness.dark;

    return MaterialApp.router(
      key: ValueKey(
        'attendly_app_${themeState.themeMode.name}_$effectiveBrightness',
      ),
      title: 'attendly',
      debugShowCheckedModeBanner: false,
      theme: themeState.lightTheme,
      darkTheme: themeState.darkTheme,
      themeMode: themeState.themeMode,
      routerConfig: router,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
