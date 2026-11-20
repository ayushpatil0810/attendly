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
import 'package:attendly/features/subjects/presentation/screens/subjects_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: SubjectsScreen()),
    );
  }

  testWidgets(
    'SubjectsScreen renders empty state and then subject card after creation',
    (tester) async {
      // Create an active semester
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(name: 'Fall 2026');
      prefs.setInt('selected_active_semester_id_v1', semId);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Enrolled Courses and Attendance'), findsOneWidget);
      expect(find.text('No Subjects Added'), findsOneWidget);

      // Create a subject
      final subjRepo = SubjectRepositoryImpl(db);
      await subjRepo.createSubject(
        semesterId: semId,
        name: 'Computer Networks',
        lectureEnabled: true,
        labEnabled: true,
      );

      // Re-pump
      await tester.pumpAndSettle();

      expect(find.text('Computer Networks'), findsOneWidget);
      expect(find.text('Lecture'), findsOneWidget);
      expect(find.text('Lab'), findsOneWidget);
      expect(find.text('No sessions recorded yet'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );

  testWidgets(
    'SubjectsScreen renders live attendance percentage and opens SubjectDetailSheet on tap',
    (tester) async {
      // Create an active semester
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Spring 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      // Create subjects
      final subjRepo = SubjectRepositoryImpl(db);
      final subjectId = await subjRepo.createSubject(
        semesterId: semId,
        name: 'Operating Systems',
        lectureEnabled: true,
        labEnabled: true,
      );
      await subjRepo.createSubject(
        semesterId: semId,
        name: 'Compiler Design',
        lectureEnabled: true,
        labEnabled: false,
      );

      // Record sessions: 3 Present, 1 Absent (75% meeting target)
      final attRepo = AttendanceRepositoryImpl(db);
      await attRepo.createSession(
        subjectId: subjectId,
        sessionDate: '2026-03-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );
      await attRepo.createSession(
        subjectId: subjectId,
        sessionDate: '2026-03-02',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );
      await attRepo.createSession(
        subjectId: subjectId,
        sessionDate: '2026-03-03',
        component: SessionComponent.lecture,
        status: AttendanceStatus.absent,
      );
      await attRepo.createSession(
        subjectId: subjectId,
        sessionDate: '2026-03-04',
        component: SessionComponent.lab,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Subject card renders with live attendance without redundant badges
      expect(find.text('Operating Systems'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('3 of 4 sessions attended'), findsOneWidget);

      // Tap card to expand inline details and actions (no separate drawer needed)
      await tester.tap(find.text('Operating Systems'));
      await tester.pumpAndSettle();

      // Expanded card reveals subject metrics and actions directly
      expect(find.text('Target'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Log Attendance'), findsOneWidget);
      expect(find.byTooltip('Edit Subject'), findsOneWidget);
      expect(find.byTooltip('Delete Subject'), findsOneWidget);

      // Tap Log Attendance: opens drawer for ONLY Operating Systems
      await tester.tap(find.text('Log Attendance'));
      await tester.pumpAndSettle();

      // Drawer is open for Operating Systems
      expect(find.text('Done Logging'), findsOneWidget);
      // Inside the open drawer, Operating Systems is shown; Compiler Design is excluded
      expect(
        find.descendant(
          of: find.byType(QuickLogSheet),
          matching: find.text('Operating Systems'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(QuickLogSheet),
          matching: find.text('Compiler Design'),
        ),
        findsNothing,
      );

      // Tap Done Logging to close
      await tester.tap(find.text('Done Logging'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );
}
