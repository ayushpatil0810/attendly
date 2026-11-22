import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_theme.dart';
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
        home: const SubjectsScreen(),
      ),
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
      expect(find.text('Target 75%'), findsNothing);
      expect(find.text('3 of 4 sessions attended'), findsOneWidget);

      // Tap card to expand inline details and actions (no separate drawer needed)
      await tester.tap(find.text('Operating Systems'));
      await tester.pumpAndSettle();

      // Expanded card hides redundant subtitle to eliminate duplicate stats
      expect(find.text('3 of 4 sessions attended'), findsNothing);
      expect(find.text('Target 75%'), findsNothing);
      expect(find.text('Can Miss'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('Conducted'), findsOneWidget);
      expect(find.text('Log Attendance'), findsOneWidget);
      expect(find.byTooltip('Edit Subject'), findsOneWidget);
      expect(find.byTooltip('Delete Subject'), findsOneWidget);

      // Tap Log Attendance: opens drawer for ONLY Operating Systems
      await tester.tap(find.text('Log Attendance'));
      await tester.pumpAndSettle();

      // Drawer is open for Operating Systems
      expect(find.text('Done'), findsOneWidget);
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

      // Tap Done to close
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );

  testWidgets(
    'Top-right action displays labeled Add Subject pill button and opens Add Subject sheet',
    (tester) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(name: 'Spring 2026');
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subjRepo = SubjectRepositoryImpl(db);
      await subjRepo.createSubject(
        semesterId: semId,
        name: 'Operating Systems',
        lectureEnabled: true,
        labEnabled: true,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify the top-right header button clearly shows "+ Add Subject"
      final addSubjectPill = find.text('Add Subject');
      expect(addSubjectPill, findsOneWidget);

      // Tap the pill button
      await tester.tap(addSubjectPill);
      await tester.pumpAndSettle();

      // Verify that Add Subject bottom sheet opens
      expect(find.text('Add Subject'), findsWidgets);
      expect(find.text('Subject Name'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );

  testWidgets(
    'Expanded card with below-target attendance displays Need actionable metric without duplicate stats',
    (tester) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Spring 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subjRepo = SubjectRepositoryImpl(db);
      final subjectId = await subjRepo.createSubject(
        semesterId: semId,
        name: 'Data Structures',
        lectureEnabled: true,
        labEnabled: true,
      );

      // Record 1 Present, 3 Absent (25% < 75% target)
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
        status: AttendanceStatus.absent,
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
        status: AttendanceStatus.absent,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Collapsed: shows concise attended text without redundant target label
      expect(find.text('Data Structures'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Target 75%'), findsNothing);
      expect(find.text('1 of 4 sessions attended'), findsOneWidget);

      // Expand card
      await tester.tap(find.text('Data Structures'));
      await tester.pumpAndSettle();

      // Expanded: hides "1 of 4 sessions attended"
      expect(find.text('1 of 4 sessions attended'), findsNothing);
      expect(find.text('Target 75%'), findsNothing);
      expect(find.text('Need'), findsOneWidget);
      // To reach 75% from 1/4: (1+x)/(4+x) >= 0.75 => 1+x >= 3+0.75x => 0.25x >= 2 => x = 8
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('Conducted'), findsOneWidget);

      // Collapse card again
      await tester.tap(find.text('Data Structures'));
      await tester.pumpAndSettle();

      // Collapsed text returns
      expect(find.text('1 of 4 sessions attended'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );

  testWidgets(
    'SubjectsScreen ListView has safe bottom padding for dock clearance',
    (tester) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(name: 'Spring 2026');
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subjRepo = SubjectRepositoryImpl(db);
      await subjRepo.createSubject(
        semesterId: semId,
        name: 'Algorithms',
        lectureEnabled: true,
        labEnabled: false,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      final listView = tester.widget<ListView>(listViewFinder);
      final padding = listView.padding as EdgeInsets;
      expect(padding.bottom, AppSpacing.safeDockClearance);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );

  testWidgets('SubjectsScreen renders in dark theme without overflow', (
    tester,
  ) async {
    final semRepo = SemesterRepositoryImpl(db);
    final semId = await semRepo.createSemester(
      name: 'Spring 2026',
      attendanceThreshold: 0.75,
    );
    prefs.setInt('selected_active_semester_id_v1', semId);

    final subjRepo = SubjectRepositoryImpl(db);
    await subjRepo.createSubject(
      semesterId: semId,
      name: 'Operating Systems',
      lectureEnabled: true,
      labEnabled: true,
    );

    await tester.pumpWidget(createWidgetUnderTest(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Subjects'), findsOneWidget);
    expect(find.text('Add Subject'), findsOneWidget);
    expect(find.text('Operating Systems'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets(
    'Expanded card renders clean inset component rows for Lecture and Lab with tabular ratios and semibold status',
    (tester) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Spring 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subjRepo = SubjectRepositoryImpl(db);
      final subjectId = await subjRepo.createSubject(
        semesterId: semId,
        name: 'Machine Learning',
        lectureEnabled: true,
        labEnabled: true,
      );

      final attRepo = AttendanceRepositoryImpl(db);
      // Lecture: 4 present, 1 absent (80% >= 75%) -> On target
      for (int i = 0; i < 4; i++) {
        await attRepo.createSession(
          subjectId: subjectId,
          sessionDate: '2026-03-0${i + 1}',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
      }
      await attRepo.createSession(
        subjectId: subjectId,
        sessionDate: '2026-03-05',
        component: SessionComponent.lecture,
        status: AttendanceStatus.absent,
      );

      // Lab: 1 present, 3 absent (25% < 75%) -> Need 8
      await attRepo.createSession(
        subjectId: subjectId,
        sessionDate: '2026-03-06',
        component: SessionComponent.lab,
        status: AttendanceStatus.present,
      );
      for (int i = 0; i < 3; i++) {
        await attRepo.createSession(
          subjectId: subjectId,
          sessionDate: '2026-03-0${i + 7}',
          component: SessionComponent.lab,
          status: AttendanceStatus.absent,
        );
      }

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Expand Machine Learning card
      await tester.tap(find.text('Machine Learning'));
      await tester.pumpAndSettle();

      // Verify Lecture row: 4/5 · 80% with 'On target'
      expect(find.text('4/5 · 80%'), findsOneWidget);
      expect(find.text('On target'), findsOneWidget);

      // Verify Lab row: 1/4 · 25% with 'Need 8'
      expect(find.text('1/4 · 25%'), findsOneWidget);
      expect(find.text('Need 8'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );
}
