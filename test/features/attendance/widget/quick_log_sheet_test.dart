import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/presentation/widgets/quick_log_sheet.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  late int semesterId;
  late int bothComponentsSubId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final semRepo = SemesterRepositoryImpl(db);
    semesterId = await semRepo.createSemester(name: 'Fall 2026');
    prefs.setInt('selected_active_semester_id_v1', semesterId);

    final subjRepo = SubjectRepositoryImpl(db);
    bothComponentsSubId = await subjRepo.createSubject(
      semesterId: semesterId,
      name: 'Computer Networks',
      lectureEnabled: true,
      labEnabled: true,
    );

    await subjRepo.createSubject(
      semesterId: semesterId,
      name: 'History of Computing',
      lectureEnabled: true,
      labEnabled: false,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidgetUnderTest({
    DateTime? initialDate,
    int? initialSubjectId,
    int? onlySubjectId,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: QuickLogSheet(
            initialDate: initialDate,
            initialSubjectId: initialSubjectId,
            onlySubjectId: onlySubjectId,
          ),
        ),
      ),
    );
  }

  void setTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
  }

  group('Redesigned QuickLogSheet Tests', () {
    testWidgets(
      'lists all subjects vertically with dedicated component sub-rows',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Header and date visible
        expect(find.text('Log Attendance'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);

        // Both subjects are visible simultaneously in vertical list
        expect(find.text('Computer Networks'), findsOneWidget);
        expect(find.text('History of Computing'), findsOneWidget);

        // Computer Networks has both Lecture and Lab
        expect(find.text('Lecture'), findsWidgets);
        expect(find.text('Lab'), findsOneWidget);

        // Quick action buttons visible without redundant "+"
        expect(find.text('Present'), findsWidgets);
        expect(find.text('Absent'), findsWidgets);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'immediately records attendance upon tapping Present without closing modal and updates live counter badge',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testDate = DateTime(2026, 3, 10);
        await tester.pumpWidget(createWidgetUnderTest(initialDate: testDate));
        await tester.pumpAndSettle();

        // Tap the first "Present" button (for Computer Networks - Lecture)
        await tester.tap(find.text('Present').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Modal is STILL open
        expect(find.text('Log Attendance'), findsOneWidget);

        // Button live counter is now visible
        expect(find.text('Present · 1'), findsOneWidget);

        // Verify persisted in SQLite
        final repo = AttendanceRepositoryImpl(db);
        final sessions = await repo.getSessionsForDate(
          semesterId,
          '2026-03-10',
        );
        expect(sessions.length, equals(1));
        expect(sessions.first.subjectId, equals(bothComponentsSubId));
        expect(sessions.first.component, equals(SessionComponent.lecture));
        expect(sessions.first.status, equals(AttendanceStatus.present));

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'allows adding multiple lectures on the spot for a specific subject with incrementing live counter',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testDate = DateTime(2026, 3, 10);
        await tester.pumpWidget(createWidgetUnderTest(initialDate: testDate));
        await tester.pumpAndSettle();

        // Add 1st lecture for Computer Networks (Present)
        await tester.tap(find.text('Present').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('Present · 1'), findsOneWidget);

        // Add 2nd lecture on the spot for the same subject (Present)
        await tester.tap(find.text('Present · 1'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Button counter updates to 2
        expect(find.text('Present · 2'), findsOneWidget);

        // Verify 2 sessions exist in DB
        final repo = AttendanceRepositoryImpl(db);
        final sessions = await repo.getSessionsForDate(
          semesterId,
          '2026-03-10',
        );
        expect(sessions.length, equals(2));
        expect(sessions[0].status, equals(AttendanceStatus.present));
        expect(sessions[1].status, equals(AttendanceStatus.present));

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'allows logging attendance for different subjects in single session',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testDate = DateTime(2026, 3, 10);
        await tester.pumpWidget(createWidgetUnderTest(initialDate: testDate));
        await tester.pumpAndSettle();

        // Mark Computer Networks Lecture as Present (1st Present button)
        await tester.tap(find.text('Present').at(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Mark Computer Networks Lab as Absent (2nd Absent button)
        await tester.tap(find.text('Absent').at(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Mark History of Computing as Present (2nd Present button)
        await tester.tap(find.text('Present').at(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        final repo = AttendanceRepositoryImpl(db);
        final sessions = await repo.getSessionsForDate(
          semesterId,
          '2026-03-10',
        );
        expect(sessions.length, equals(3));

        // Sheet is still open
        expect(find.text('Log Attendance'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets('deletes session when decrement stepper button is tapped', (
      tester,
    ) async {
      setTestViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testDate = DateTime(2026, 3, 10);
      final repo = AttendanceRepositoryImpl(db);
      await repo.createSession(
        subjectId: bothComponentsSubId,
        sessionDate: '2026-03-10',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(createWidgetUnderTest(initialDate: testDate));
      await tester.pumpAndSettle();

      expect(find.text('Present · 1'), findsOneWidget);

      // Tap the decrement stepper button for removing 1 Present
      final decrementButton = find.byTooltip('Remove 1 Present');
      expect(decrementButton, findsOneWidget);
      await tester.tap(decrementButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Button returns to unlogged state
      expect(find.text('Present · 1'), findsNothing);
      expect(find.text('Present'), findsWidgets);

      final sessions = await repo.getSessionsForDate(semesterId, '2026-03-10');
      expect(sessions, isEmpty);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('tapping Done button pops the modal sheet', (tester) async {
      setTestViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showQuickLogSheet(context: context),
                  child: const Text('Open Quick Log'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Quick Log'));
      await tester.pumpAndSettle();

      expect(find.byType(QuickLogSheet), findsOneWidget);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Sheet is dismissed
      expect(find.byType(QuickLogSheet), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'renders only specific subject when onlySubjectId is provided',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // bothComponentsSubId is Computer Networks, other subject in DB is History of Computing
        await tester.pumpWidget(
          createWidgetUnderTest(onlySubjectId: bothComponentsSubId),
        );
        await tester.pumpAndSettle();

        // Title and Done button visible
        expect(find.text('Log Attendance'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);

        // Only Computer Networks is rendered; History of Computing is excluded
        expect(find.text('Computer Networks'), findsOneWidget);
        expect(find.text('History of Computing'), findsNothing);

        // Allows recording attendance specifically for Computer Networks
        expect(find.text('Present'), findsWidgets);
        await tester.tap(find.text('Present').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('Present · 1'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'clamps future initialDate to today in QuickLogSheet',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final futureDate = DateTime(2099, 1, 1);
        await tester.pumpWidget(
          createWidgetUnderTest(initialDate: futureDate),
        );
        await tester.pumpAndSettle();

        // The date pill should display Today, not the future date
        expect(find.textContaining('Today'), findsOneWidget);
        expect(find.textContaining('2099'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });
}
