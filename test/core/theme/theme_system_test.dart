import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:attendly/core/services/home_widget_service.dart';
import 'package:attendly/core/theme/app_palettes.dart';
import 'package:attendly/core/theme/app_theme.dart';
import 'package:attendly/core/theme/app_theme_colors.dart';
import 'package:attendly/core/theme/theme_provider.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/settings/presentation/widgets/appearance_section.dart';

class _MockHomeWidgetWrapper implements HomeWidgetWrapper {
  final Map<String, dynamic> savedData = {};

  @override
  Future<bool?> saveWidgetData<T>(String id, T? data) async {
    savedData[id] = data;
    return true;
  }

  @override
  Future<bool?> updateWidget({
    String? name,
    String? androidName,
    String? iOSName,
    String? qualifiedAndroidName,
  }) async {
    return true;
  }

  @override
  Future<Uri?> initiallyLaunchedFromHomeWidget() async => null;

  @override
  Stream<Uri?> get widgetClicked => const Stream.empty();
}

void main() {
  group('Professional Theme System - Definitions & Palettes', () {
    test('Light and Dark palettes are defined with high contrast', () {
      final light = AppPalettes.light;
      final dark = AppPalettes.dark;

      expect(light.isDark, isFalse);
      expect(dark.isDark, isTrue);

      // Dark background is darker than light background
      expect(
        dark.background.computeLuminance(),
        lessThan(light.background.computeLuminance()),
      );

      // High contrast text in light mode
      expect(
        light.textPrimary.computeLuminance(),
        lessThan(light.background.computeLuminance()),
      );

      // High contrast text in dark mode
      expect(
        dark.textPrimary.computeLuminance(),
        greaterThan(dark.background.computeLuminance()),
      );
    });

    test('Semantic attendance colors are distinct and accessible', () {
      for (final colors in [AppPalettes.light, AppPalettes.dark]) {
        // Present (green) vs Absent (coral/red)
        expect(colors.present, isNotNull);
        expect(colors.onPresent, isNotNull);
        expect(colors.absent, isNotNull);
        expect(colors.onAbsent, isNotNull);
        expect(colors.warning, isNotNull);
        expect(colors.neutral, isNotNull);

        expect(colors.present, isNot(equals(colors.absent)));
      }
    });

    test('AppThemeColors copyWith and lerp operate properly', () {
      final base = AppPalettes.light;
      final copied = base.copyWith(isDark: true);
      expect(copied.isDark, isTrue);
      expect(copied.brandPrimary, base.brandPrimary);

      final lerped = base.lerp(AppPalettes.dark, 0.5);
      expect(lerped, isA<AppThemeColors>());
    });

    test('AppTheme.buildTheme generates complete ThemeData with extensions', () {
      final lightTheme = AppTheme.buildTheme(Brightness.light);
      final darkTheme = AppTheme.buildTheme(Brightness.dark);

      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);

      expect(lightTheme.extension<AppThemeColors>(), isNotNull);
      expect(darkTheme.extension<AppThemeColors>(), isNotNull);

      expect(lightTheme.extension<AppThemeColors>()!.isDark, isFalse);
      expect(darkTheme.extension<AppThemeColors>()!.isDark, isTrue);
    });
  });

  group('Theme State Management & Persistence', () {
    late SharedPreferences prefs;
    late _MockHomeWidgetWrapper mockWrapper;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockWrapper = _MockHomeWidgetWrapper();
    });

    test('Default state is ThemeMode.system', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          homeWidgetWrapperProvider.overrideWithValue(mockWrapper),
        ],
      );
      addTearDown(container.dispose);

      final themeState = container.read(themePreferencesProvider);
      expect(themeState.themeMode, ThemeMode.system);
    });

    test(
      'Changing theme mode updates state and persists to SharedPreferences',
      () async {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            homeWidgetWrapperProvider.overrideWithValue(mockWrapper),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        expect(container.read(themeModeProvider), ThemeMode.dark);
        expect(prefs.getString(prefThemeModeKey), 'dark');

        await container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.light);
        expect(container.read(themeModeProvider), ThemeMode.light);
        expect(prefs.getString(prefThemeModeKey), 'light');
      },
    );

    test('Restores saved preferences from SharedPreferences on app startup', () async {
      SharedPreferences.setMockInitialValues({
        prefThemeModeKey: 'dark',
      });
      final restoredPrefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(restoredPrefs),
          homeWidgetWrapperProvider.overrideWithValue(mockWrapper),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('Appearance Section Widget', () {
    late SharedPreferences prefs;
    late _MockHomeWidgetWrapper mockWrapper;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockWrapper = _MockHomeWidgetWrapper();
    });

    testWidgets('Renders appearance header and mode segmented control', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          homeWidgetWrapperProvider.overrideWithValue(mockWrapper),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: AppearanceSection()),
            ),
          ),
        ),
      );

      // Header exists
      expect(find.text('Appearance'), findsOneWidget);

      // Mode items exist
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('Tapping dark mode selects it and persists immediately', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          homeWidgetWrapperProvider.overrideWithValue(mockWrapper),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: AppearanceSection()),
            ),
          ),
        ),
      );

      // Tap Dark
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString(prefThemeModeKey), 'dark');
    });

    testWidgets('Tapping light mode selects it and persists immediately', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          homeWidgetWrapperProvider.overrideWithValue(mockWrapper),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: AppearanceSection()),
            ),
          ),
        ),
      );

      // Tap Light
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString(prefThemeModeKey), 'light');
    });
  });
}
