import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';

import 'package:attendly/app/app.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/services/home_widget_service.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_theme.dart';
import 'package:attendly/core/theme/app_theme_id.dart';
import 'package:attendly/core/theme/theme_provider.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

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
  }) async => true;

  @override
  Future<Uri?> initiallyLaunchedFromHomeWidget() async => null;

  @override
  Stream<Uri?> get widgetClicked => const Stream.empty();
}

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late _MockHomeWidgetWrapper mockWidgetWrapper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding_v1': true,
      'active_semester_id_v1': 1,
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockWidgetWrapper = _MockHomeWidgetWrapper();

    final semRepo = SemesterRepositoryImpl(db);
    final subjRepo = SubjectRepositoryImpl(db);
    await semRepo.createSemester(
      name: 'Spring 2026',
      attendanceThreshold: 0.75,
      calculationMethod: AttendanceCalculationMethod.rawCombined,
    );
    await subjRepo.createSubject(
      semesterId: 1,
      name: 'Mobile Development',
      lectureEnabled: true,
      labEnabled: true,
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'All 8 palettes work reactively in both Light and Dark mode across screens',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          homeWidgetWrapperProvider.overrideWithValue(mockWidgetWrapper),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AttendlyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial home screen is loaded
      expect(find.text('Spring 2026'), findsWidgets);

      for (final theme in AppThemeId.values) {
        // 1. Test Light mode for this theme
        await container.read(activeThemeIdProvider.notifier).setThemeId(theme);
        await container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.light);
        await tester.pumpAndSettle();

        expect(AppTheme.currentColors.background, theme.lightColors.background);
        expect(AppColors.warmWhite, theme.lightColors.background);
        expect(
          AppTheme.currentColors.brandPrimary,
          theme.lightColors.brandPrimary,
        );
        expect(AppColors.brandViolet, theme.lightColors.brandPrimary);

        // Verify Scaffolds on screen match the theme's light background
        final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
        for (final s in scaffolds) {
          final effectiveBg = s.backgroundColor ?? theme.lightColors.background;
          expect(effectiveBg, equals(theme.lightColors.background));
        }

        // 2. Test Dark mode for this theme
        await container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        await tester.pumpAndSettle();

        expect(AppTheme.currentColors.background, theme.darkColors.background);
        expect(AppColors.warmWhite, theme.darkColors.background);
        expect(
          AppTheme.currentColors.brandPrimary,
          theme.darkColors.brandPrimary,
        );
        expect(AppColors.brandViolet, theme.darkColors.brandPrimary);

        // Verify Scaffolds on screen match the theme's dark background
        final darkScaffolds = tester.widgetList<Scaffold>(
          find.byType(Scaffold),
        );
        for (final s in darkScaffolds) {
          final effectiveBg = s.backgroundColor ?? theme.darkColors.background;
          expect(effectiveBg, equals(theme.darkColors.background));
        }
      }

      // 3. Navigate to Insights screen
      final insightsDockFinder = find.byTooltip('Insights');
      if (insightsDockFinder.evaluate().isNotEmpty) {
        await tester.tap(insightsDockFinder);
      } else {
        await tester.tap(find.text('Insights'));
      }
      await tester.pumpAndSettle();

      // Verify Insights screen is rendered
      expect(find.text('Attendance analytics & patterns'), findsOneWidget);

      // Verify Insights screen responds reactively to theme switches in both Light and Dark modes
      for (final theme in [
        AppThemeId.oceanBreeze,
        AppThemeId.midnightBlue,
        AppThemeId.lavenderDream,
      ]) {
        await container.read(activeThemeIdProvider.notifier).setThemeId(theme);
        await container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.light);
        await tester.pumpAndSettle();

        expect(
          AppTheme.currentColors.background,
          equals(theme.lightColors.background),
        );
        final insightsScaffolds = tester.widgetList<Scaffold>(
          find.byType(Scaffold),
        );
        for (final s in insightsScaffolds) {
          final effectiveBg = s.backgroundColor ?? theme.lightColors.background;
          expect(effectiveBg, equals(theme.lightColors.background));
        }

        await container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        await tester.pumpAndSettle();

        expect(
          AppTheme.currentColors.background,
          equals(theme.darkColors.background),
        );
        final darkInsightsScaffolds = tester.widgetList<Scaffold>(
          find.byType(Scaffold),
        );
        for (final s in darkInsightsScaffolds) {
          final effectiveBg = s.backgroundColor ?? theme.darkColors.background;
          expect(effectiveBg, equals(theme.darkColors.background));
        }
      }
    },
  );
}
