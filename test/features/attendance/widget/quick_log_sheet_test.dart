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
  late int lectureOnlySubId;

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

    lectureOnlySubId = await subjRepo.createSubject(
      semesterId: semesterId,
      name: 'History of Computing',
      lectureEnabled: true,
      labEnabled: false,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidgetUnderTest({DateTime? initialDate}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(body: QuickLogSheet(initialDate: initialDate)),
      ),
    );
  }

  group('QuickLogSheet Widget Tests', () {
    testWidgets(
      'shows subjects and allows component selection for multi-component subject',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Subject chips visible
        expect(find.text('Computer Networks'), findsOneWidget);
        expect(find.text('History of Computing'), findsOneWidget);

        // Computer Networks is selected by default -> has both components -> shows Lecture & Lab segmented control
        expect(find.text('Lecture'), findsOneWidget);
        expect(find.text('Lab'), findsOneWidget);

        // Present and Absent immediate action buttons visible
        expect(find.text('Present'), findsOneWidget);
        expect(find.text('Absent'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'automatically selects the only enabled component for single-component subject',
      (tester) async {
        expect(lectureOnlySubId, greaterThan(0));
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Tap on History of Computing (lecture only)
        await tester.tap(find.text('History of Computing'));
        await tester.pumpAndSettle();

        // Component is automatically set to Lecture without segmented control
        expect(find.text('Component: '), findsOneWidget);
        expect(find.text('Lecture'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'immediately saves attendance upon tapping Present without extra save button',
      (tester) async {
        final testDate = DateTime(2026, 3, 10);
        await tester.pumpWidget(createWidgetUnderTest(initialDate: testDate));
        await tester.pumpAndSettle();

        // Select Computer Networks -> Lecture -> tap Present
        await tester.tap(find.text('Present'));
        await tester.pumpAndSettle();

        // Verify persisted in DB
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

    testWidgets('immediately saves attendance upon tapping Absent', (
      tester,
    ) async {
      final testDate = DateTime(2026, 3, 11);
      await tester.pumpWidget(createWidgetUnderTest(initialDate: testDate));
      await tester.pumpAndSettle();

      // Tap Lab component
      await tester.tap(find.text('Lab'));
      await tester.pumpAndSettle();

      // Tap Absent
      await tester.tap(find.text('Absent'));
      await tester.pumpAndSettle();

      // Verify persisted in DB
      final repo = AttendanceRepositoryImpl(db);
      final sessions = await repo.getSessionsForDate(semesterId, '2026-03-11');
      expect(sessions.length, equals(1));
      expect(sessions.first.component, equals(SessionComponent.lab));
      expect(sessions.first.status, equals(AttendanceStatus.absent));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'shows duplicate feedback and view/edit action when session already exists',
      (tester) async {
        final testDate = DateTime(2026, 3, 10);
        final dateStr = '2026-03-10';

        // Pre-seed an existing session
        final repo = AttendanceRepositoryImpl(db);
        await repo.createSession(
          subjectId: bothComponentsSubId,
          sessionDate: dateStr,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        await tester.pumpWidget(createWidgetUnderTest(initialDate: testDate));
        await tester.pumpAndSettle();

        // Computer Networks + Lecture selected -> duplicate detected!
        expect(find.text('Record already exists'), findsOneWidget);
        expect(
          find.text('This session is currently recorded as Present.'),
          findsOneWidget,
        );
        expect(find.text('View / Edit Existing Record'), findsOneWidget);

        // Present / Absent action buttons should be hidden to prevent duplicate submit
        expect(find.text('Mark Attendance (saves immediately)'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });
}
