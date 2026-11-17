import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:attendly/core/services/home_widget_service.dart';
import 'package:attendly/core/theme/app_palettes.dart';
import 'package:attendly/core/theme/app_theme.dart';
import 'package:attendly/core/theme/app_theme_colors.dart';
import 'package:attendly/core/theme/app_theme_id.dart';
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
  group('Theme System - Definitions & Palettes', () {
    test('All 8 themes are defined with unique ids and names', () {
      expect(AppThemeId.values.length, 8);
      final ids = AppThemeId.values.map((t) => t.id).toSet();
      expect(ids.length, 8);

      expect(AppThemeId.lavenderDream.name, 'Lavender Dream');
      expect(AppThemeId.oceanBreeze.name, 'Ocean Breeze');
      expect(AppThemeId.peachBlossom.name, 'Peach Blossom');
      expect(AppThemeId.sageGarden.name, 'Sage Garden');
      expect(AppThemeId.midnightBlue.name, 'Midnight Blue');
      expect(AppThemeId.buttercream.name, 'Buttercream');
      expect(AppThemeId.roseQuartz.name, 'Rose Quartz');
      expect(AppThemeId.graphiteMint.name, 'Graphite Mint');
    });

    test('Each theme has 4 distinct preview swatches', () {
      for (final theme in AppThemeId.values) {
        expect(
          theme.previewColors.length,
          4,
          reason: '${theme.name} must have 4 preview colors',
        );
      }
    });

    test('Each theme provides distinct Light and Dark palettes', () {
      for (final theme in AppThemeId.values) {
        final light = theme.lightColors;
        final dark = theme.darkColors;

        expect(
          light.isDark,
          isFalse,
          reason: '${theme.name} lightColors.isDark must be false',
        );
        expect(
          dark.isDark,
          isTrue,
          reason: '${theme.name} darkColors.isDark must be true',
        );

        // Dark backgrounds must be comfortable dark tones
        expect(
          dark.background.computeLuminance(),
          lessThan(light.background.computeLuminance()),
          reason: '${theme.name} dark background must be darker than light',
        );

        // Text must have high contrast in both
        expect(
          light.textPrimary.computeLuminance(),
          lessThan(light.background.computeLuminance()),
          reason: '${theme.name} light text must be darker than background',
        );
        expect(
          dark.textPrimary.computeLuminance(),
          greaterThan(dark.background.computeLuminance()),
          reason: '${theme.name} dark text must be lighter than background',
        );
      }
    });

    test(
      'Semantic attendance colors remain consistent across all 8 themes',
      () {
        for (final theme in AppThemeId.values) {
          for (final brightness in [Brightness.light, Brightness.dark]) {
            final colors = theme.colorsFor(brightness);

            // Present is always green/mint
            expect(colors.present, isNotNull);
            expect(colors.onPresent, isNotNull);

            // Absent is always red/coral
            expect(colors.absent, isNotNull);
            expect(colors.onAbsent, isNotNull);

            // Warning and neutral
            expect(colors.warning, isNotNull);
            expect(colors.neutral, isNotNull);

            // Present and Absent must be clearly distinct hues
            expect(colors.present, isNot(equals(colors.absent)));
          }
        }
      },
    );

    test('AppThemeId.fromId correctly resolves valid and invalid IDs', () {
      expect(AppThemeId.fromId('lavender_dream'), AppThemeId.lavenderDream);
      expect(AppThemeId.fromId('ocean_breeze'), AppThemeId.oceanBreeze);
      expect(AppThemeId.fromId('peach_blossom'), AppThemeId.peachBlossom);
      expect(AppThemeId.fromId('sage_garden'), AppThemeId.sageGarden);
      expect(AppThemeId.fromId('midnight_blue'), AppThemeId.midnightBlue);
      expect(AppThemeId.fromId('buttercream'), AppThemeId.buttercream);
      expect(AppThemeId.fromId('rose_quartz'), AppThemeId.roseQuartz);
      expect(AppThemeId.fromId('graphite_mint'), AppThemeId.graphiteMint);

      // Fallbacks
      expect(AppThemeId.fromId(null), AppThemeId.lavenderDream);
      expect(AppThemeId.fromId('non_existent'), AppThemeId.lavenderDream);
    });

    test('AppThemeColors copyWith and lerp operate properly', () {
      final base = AppPalettes.lavenderDreamLight;
      final copied = base.copyWith(isDark: true);
      expect(copied.isDark, isTrue);
      expect(copied.brandPrimary, base.brandPrimary);

      final lerped = base.lerp(AppPalettes.lavenderDreamDark, 0.5);
      expect(lerped, isA<AppThemeColors>());
    });

    test(
      'AppTheme.buildTheme generates complete ThemeData with extensions',
      () {
        for (final theme in AppThemeId.values) {
          final lightTheme = AppTheme.buildTheme(theme, Brightness.light);
          final darkTheme = AppTheme.buildTheme(theme, Brightness.dark);

          expect(lightTheme.brightness, Brightness.light);
          expect(darkTheme.brightness, Brightness.dark);

          expect(lightTheme.extension<AppThemeColors>(), isNotNull);
          expect(darkTheme.extension<AppThemeColors>(), isNotNull);

          expect(lightTheme.extension<AppThemeColors>()!.isDark, isFalse);
          expect(darkTheme.extension<AppThemeColors>()!.isDark, isTrue);
        }
      },
    );
  });

  group('Theme State Management & Persistence', () {
    late SharedPreferences prefs;
    late _MockHomeWidgetWrapper mockWrapper;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockWrapper = _MockHomeWidgetWrapper();
    });

    test('Default state is ThemeMode.system and AppThemeId.lavenderDream', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          homeWidgetWrapperProvider.overrideWithValue(mockWrapper),
        ],
      );
      addTearDown(container.dispose);

      final themeState = container.read(themePreferencesProvider);
      expect(themeState.themeMode, ThemeMode.system);
      expect(themeState.themeId, AppThemeId.lavenderDream);
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

    test('Changing active theme ID updates state and persists to SharedPreferences', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          homeWidgetWrapperProvider.overrideWithValue(mockWrapper),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(activeThemeIdProvider.notifier)
          .setThemeId(AppThemeId.oceanBreeze);
      expect(container.read(activeThemeIdProvider), AppThemeId.oceanBreeze);
      expect(prefs.getString(prefThemeIdKey), 'ocean_breeze');

      await container
          .read(activeThemeIdProvider.notifier)
          .setThemeId(AppThemeId.peachBlossom);
      expect(container.read(activeThemeIdProvider), AppThemeId.peachBlossom);
      expect(prefs.getString(prefThemeIdKey), 'peach_blossom');
    });

    test(
      'Restores saved preferences from SharedPreferences on app startup',
      () async {
        SharedPreferences.setMockInitialValues({
          prefThemeModeKey: 'dark',
          prefThemeIdKey: 'sage_garden',
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
        expect(container.read(activeThemeIdProvider), AppThemeId.sageGarden);
      },
    );
  });

  group('Appearance Section Widget', () {
    late SharedPreferences prefs;
    late _MockHomeWidgetWrapper mockWrapper;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockWrapper = _MockHomeWidgetWrapper();
    });

    testWidgets('Renders all 8 theme choices and mode segmented control', (
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

      // Mode items exist
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // All 8 theme names exist
      expect(find.text('Lavender Dream'), findsOneWidget);
      expect(find.text('Ocean Breeze'), findsOneWidget);
      expect(find.text('Peach Blossom'), findsOneWidget);
      expect(find.text('Sage Garden'), findsOneWidget);
      expect(find.text('Midnight Blue'), findsOneWidget);
      expect(find.text('Buttercream'), findsOneWidget);
      expect(find.text('Rose Quartz'), findsOneWidget);
      expect(find.text('Graphite Mint'), findsOneWidget);
    });

    testWidgets('Tapping a theme selects it and persists immediately', (
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

      // Tap Ocean Breeze
      await tester.tap(find.text('Ocean Breeze'));
      await tester.pumpAndSettle();

      expect(container.read(activeThemeIdProvider), AppThemeId.oceanBreeze);
      expect(prefs.getString(prefThemeIdKey), 'ocean_breeze');
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
  });
}
