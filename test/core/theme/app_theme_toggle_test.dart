import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';

import 'package:attendly/app/app.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/services/home_widget_service.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_palettes.dart';
import 'package:attendly/core/theme/app_theme.dart';
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
      'selected_active_semester_id_v1': 1,
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
    'App switches reactively between Professional Light and Dark mode across screens',
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
      // Advance past splash screen minimum display duration
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // Verify initial home screen is loaded
      expect(find.text('Spring 2026'), findsWidgets);

      // 1. Test Light mode
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(AppTheme.currentColors.background, AppPalettes.light.background);
      expect(AppColors.warmWhite, AppPalettes.light.background);
      expect(
        AppTheme.currentColors.brandPrimary,
        AppPalettes.light.brandPrimary,
      );
      expect(AppColors.brandViolet, AppPalettes.light.brandPrimary);

      // Verify Scaffolds on screen match the light background
      final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
      for (final s in scaffolds) {
        final effectiveBg = s.backgroundColor ?? AppPalettes.light.background;
        expect(effectiveBg, equals(AppPalettes.light.background));
      }

      // 2. Test Dark mode
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(AppTheme.currentColors.background, AppPalettes.dark.background);
      expect(AppColors.warmWhite, AppPalettes.dark.background);
      expect(
        AppTheme.currentColors.brandPrimary,
        AppPalettes.dark.brandPrimary,
      );
      expect(AppColors.brandViolet, AppPalettes.dark.brandPrimary);

      // Verify Scaffolds on screen match the dark background
      final darkScaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
      for (final s in darkScaffolds) {
        final effectiveBg = s.backgroundColor ?? AppPalettes.dark.background;
        expect(effectiveBg, equals(AppPalettes.dark.background));
      }

      // 3. Navigate to History tab and verify reactive dark/light transition
      await tester.tap(find.byKey(const Key('dock_tab_history')));
      await tester.pumpAndSettle();

      expect(find.text('Calendar & Attendance Timeline'), findsOneWidget);

      // Switch back to Light mode on Insights
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(AppTheme.currentColors.background, AppPalettes.light.background);
      expect(AppColors.warmWhite, AppPalettes.light.background);

      // Switch back to Dark mode on Insights
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(AppTheme.currentColors.background, AppPalettes.dark.background);
      expect(AppColors.warmWhite, AppPalettes.dark.background);
    },
  );
}
