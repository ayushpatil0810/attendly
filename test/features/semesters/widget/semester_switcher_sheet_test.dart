import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_theme.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_switcher_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  late SemesterRepositoryImpl semRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    semRepo = SemesterRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidgetUnderTest({ThemeMode themeMode = ThemeMode.light}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: const Scaffold(
          body: SemesterSwitcherSheet(),
        ),
      ),
    );
  }

  group('SemesterSwitcherSheet Widget Tests', () {
    testWidgets('renders uncluttered card with QR Share and overflow menu', (
      tester,
    ) async {
      final semId = await semRepo.createSemester(
        name: 'Sem 5',
        attendanceThreshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify semester name and calculation method label
      expect(find.text('Sem 5'), findsOneWidget);
      expect(find.text('Threshold: 75% • 50/50 Lecture & Lab'), findsOneWidget);

      // Verify QR Share and More options tooltip
      expect(find.byTooltip('Share QR'), findsOneWidget);
      expect(find.byTooltip('More options'), findsOneWidget);

      // Verify that inline Edit, Archive, and Delete are NOT rendered on the card
      expect(find.byTooltip('Edit'), findsNothing);
      expect(find.byTooltip('Archive'), findsNothing);
      expect(find.byTooltip('Delete'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('tapping overflow menu opens options including destructive Delete', (
      tester,
    ) async {
      final semId = await semRepo.createSemester(
        name: 'Sem 5',
        attendanceThreshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the overflow menu button
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();

      // Verify menu items
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.byType(PopupMenuDivider), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'tapping Delete in overflow menu shows confirmation dialog with safe cancel',
      (tester) async {
        final semId = await semRepo.createSemester(
          name: 'Sem 5',
          attendanceThreshold: 0.75,
          calculationMethod: AttendanceCalculationMethod.rawCombined,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Open overflow menu
        await tester.tap(find.byTooltip('More options'));
        await tester.pumpAndSettle();

        // Tap Delete in menu
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Verify confirmation dialog title and content
        expect(find.text('Delete Sem 5?'), findsOneWidget);
        expect(
          find.text(
            'This will permanently remove all subjects and attendance logs for this semester.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify semester still exists in DB
        final sem = await semRepo.getSemesterById(semId);
        expect(sem, isNotNull);
        expect(sem!.name, 'Sem 5');

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'confirming Delete removes semester and updates UI',
      (tester) async {
        final semId = await semRepo.createSemester(
          name: 'Sem 5',
          attendanceThreshold: 0.75,
          calculationMethod: AttendanceCalculationMethod.rawCombined,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Open overflow menu
        await tester.tap(find.byTooltip('More options'));
        await tester.pumpAndSettle();

        // Tap Delete in menu
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Tap Delete in dialog (the AppButton with destructive variant)
        final deleteButton = find.widgetWithText(AppButton, 'Delete');
        expect(deleteButton, findsOneWidget);
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // Verify semester was removed from DB
        final sem = await semRepo.getSemesterById(semId);
        expect(sem, isNull);
        expect(find.text('No active semesters.'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'archive toggle and dialog functions as expected',
      (tester) async {
        final semId = await semRepo.createSemester(
          name: 'Sem 6',
          attendanceThreshold: 0.80,
          calculationMethod: AttendanceCalculationMethod.componentAverage,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Open overflow menu
        await tester.tap(find.byTooltip('More options'));
        await tester.pumpAndSettle();

        // Tap Archive
        await tester.tap(find.text('Archive'));
        await tester.pumpAndSettle();

        expect(find.text('Archive Sem 6?'), findsOneWidget);
        final archiveBtn = find.widgetWithText(AppButton, 'Archive');
        await tester.tap(archiveBtn);
        await tester.pumpAndSettle();

        // In active view, list should now be empty
        expect(find.text('No active semesters.'), findsOneWidget);

        // Toggle to show archived
        await tester.tap(find.text('Show Archived'));
        await tester.pumpAndSettle();

        expect(find.text('Sem 6'), findsOneWidget);
        expect(find.text('Archived'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets('renders cleanly in dark mode', (tester) async {
      final semId = await semRepo.createSemester(
        name: 'Sem 5',
        attendanceThreshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      await tester.pumpWidget(createWidgetUnderTest(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sem 5'), findsOneWidget);
      expect(find.text('Threshold: 75% • 50/50 Lecture & Lab'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('active semester displays blue checkmark while unselected does not', (
      tester,
    ) async {
      final semId1 = await semRepo.createSemester(name: 'Sem 5');
      await semRepo.createSemester(name: 'Sem 6');
      prefs.setInt('selected_active_semester_id_v1', semId1);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Sem 5 is active -> checkmark is rendered
      expect(find.text('Sem 5'), findsOneWidget);
      expect(find.text('Sem 6'), findsOneWidget);
      expect(find.byIcon(AppIcons.check), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}
