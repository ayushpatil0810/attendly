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

  Widget createWidgetUnderTest({DateTime? initialDate, int? initialSubjectId}) {
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
        expect(find.text('Quick Attendance Log'), findsOneWidget);
        expect(find.text('Done Logging'), findsOneWidget);

        // Both subjects are visible simultaneously in vertical list
        expect(find.text('Computer Networks'), findsOneWidget);
        expect(find.text('History of Computing'), findsOneWidget);

        // Computer Networks has both Theory Lecture and Practical Lab
        expect(find.text('Theory Lecture'), findsWidgets);
        expect(find.text('Practical Lab'), findsOneWidget);

        // Quick action buttons visible
        expect(find.text('+ Present'), findsWidgets);
        expect(find.text('+ Absent'), findsWidgets);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'immediately records attendance upon tapping + Present without closing modal',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testDate = DateTime(2026, 3, 10);
        await tester.pumpWidget(createWidgetUnderTest(initialDate: testDate));
        await tester.pumpAndSettle();

        // Tap the first "+ Present" button (for Computer Networks - Lecture)
        await tester.tap(find.text('+ Present').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Modal is STILL open
        expect(find.text('Quick Attendance Log'), findsOneWidget);

        // Chip is now visible on the card
        expect(find.text('Lec 1: Present'), findsOneWidget);

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
      'allows adding multiple lectures on the spot for a specific subject',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testDate = DateTime(2026, 3, 10);
        await tester.pumpWidget(createWidgetUnderTest(initialDate: testDate));
        await tester.pumpAndSettle();

        // Add 1st lecture for Computer Networks (Present)
        await tester.tap(find.text('+ Present').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('Lec 1: Present'), findsOneWidget);

        // Add 2nd lecture on the spot for the same subject (Present)
        await tester.tap(find.text('+ Present').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Both chips are visible
        expect(find.text('Lec 1: Present'), findsOneWidget);
        expect(find.text('Lec 2: Present'), findsOneWidget);

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

        // Mark Computer Networks Lecture as Present (1st + Present button)
        await tester.tap(find.text('+ Present').at(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Mark Computer Networks Lab as Absent (2nd + Absent button)
        await tester.tap(find.text('+ Absent').at(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Mark History of Computing as Present (3rd + Present button)
        await tester.tap(find.text('+ Present').at(2));
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
        expect(find.text('Quick Attendance Log'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'deletes session when remove button on chip is tapped',
      (tester) async {
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

        expect(find.text('Lec 1: Present'), findsOneWidget);

        // Tap the semantics action for removing the chip
        final removeButton = find.bySemanticsLabel('Remove Lec 1 Present');
        expect(removeButton, findsOneWidget);
        await tester.tap(removeButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Chip is removed
        expect(find.text('Lec 1: Present'), findsNothing);

        final sessions = await repo.getSessionsForDate(
          semesterId,
          '2026-03-10',
        );
        expect(sessions, isEmpty);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'tapping Done button pops the modal sheet',
      (tester) async {
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

        // Tap Done Logging
        await tester.tap(find.text('Done Logging'));
        await tester.pumpAndSettle();

        // Sheet is dismissed
        expect(find.byType(QuickLogSheet), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });
}
