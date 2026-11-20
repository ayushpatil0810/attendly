import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_trend_card.dart';
import 'package:attendly/features/dashboard/presentation/widgets/overall_attendance_hero.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/shell/presentation/screens/home_screen.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

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

  Widget createWidgetUnderTest({VoidCallback? onNavigateToSubjects}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: HomeScreen(onNavigateToSubjects: onNavigateToSubjects ?? () {}),
      ),
    );
  }

  group('Dashboard Widget Tests', () {
    testWidgets('renders empty semester dashboard without fake numbers or 0%', (
      tester,
    ) async {
      // 1. Create semester and subject
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Fall 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      await subRepo.createSubject(
        semesterId: semId,
        name: 'Database Systems',
        lectureEnabled: true,
        labEnabled: true,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header shows semester name
      expect(find.text('Fall 2026'), findsOneWidget);

      // Hero shows target threshold
      expect(find.text('Target: 75%'), findsOneWidget);

      // Hero percentage must be '—', NOT '0%'
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0%'), findsNothing);

      // Shows welcoming empty state
      expect(find.text('No Classes Recorded Yet'), findsOneWidget);
      expect(find.text('Quick Log Session'), findsOneWidget);

      // Subject preview shows "Not available" and "No sessions yet"
      expect(find.text('Database Systems'), findsOneWidget);
      expect(find.text('No sessions yet'), findsOneWidget);

      // No fake safe absence or recovery numbers are shown
      expect(find.textContaining('Safe Absence'), findsNothing);
      expect(find.textContaining('Consecutive Present'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('renders valid attendance above threshold with safe absences', (
      tester,
    ) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Spring 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      final subId = await subRepo.createSubject(
        semesterId: semId,
        name: 'Data Structures',
        lectureEnabled: true,
        labEnabled: false,
      );

      final attRepo = AttendanceRepositoryImpl(db);
      // 8 Present, 2 Absent = 80% (threshold 75% -> 0 safe absences because 8/11 = 72.7%)
      for (var i = 1; i <= 8; i++) {
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-02-0$i',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
      }
      for (var i = 9; i <= 10; i++) {
        final d = i < 10 ? '0$i' : '$i';
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-02-$d',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );
      }

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Displays 80% in OverallAttendanceHero
      expect(
        find.descendant(
          of: find.byType(OverallAttendanceHero),
          matching: find.text('80%'),
        ),
        findsOneWidget,
      );
      expect(find.text('+5.0%'), findsOneWidget);

      // Compact counts
      expect(find.text('Conducted'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Absent'), findsNothing);

      expect(find.text('At Target Threshold'), findsOneWidget);
      expect(
        find.text(
          'Any additional absence will drop your attendance below 75%.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('renders attendance with 6 safe absences when 80/100', (
      tester,
    ) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Spring 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      final subId = await subRepo.createSubject(
        semesterId: semId,
        name: 'Algorithms',
        lectureEnabled: true,
        labEnabled: true,
      );

      final attRepo = AttendanceRepositoryImpl(db);
      // 40 days of (1 Lecture Present + 1 Lab Present) = 80 Present
      for (var i = 1; i <= 20; i++) {
        final d = i.toString().padLeft(2, '0');
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-01-$d',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-01-$d',
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
        );
      }
      for (var i = 1; i <= 20; i++) {
        final d = i.toString().padLeft(2, '0');
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-02-$d',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-02-$d',
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
        );
      }
      // 10 days of (1 Lecture Absent + 1 Lab Absent) = 20 Absent
      for (var i = 1; i <= 10; i++) {
        final d = i.toString().padLeft(2, '0');
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-03-$d',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-03-$d',
          component: SessionComponent.lab,
          status: AttendanceStatus.absent,
        );
      }

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(OverallAttendanceHero),
          matching: find.text('80%'),
        ),
        findsOneWidget,
      );
      expect(find.text('6 Safe Absences'), findsOneWidget);
      expect(
        find.text(
          'You can miss up to 6 classes while maintaining your 75% target.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('renders attendance below threshold with recovery insight', (
      tester,
    ) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Fall 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      final subId = await subRepo.createSubject(
        semesterId: semId,
        name: 'Computer Networks',
        lectureEnabled: true,
        labEnabled: false,
      );

      final attRepo = AttendanceRepositoryImpl(db);
      // 6 Present, 4 Absent = 60% (needs 6 consecutive presents)
      for (var i = 1; i <= 6; i++) {
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-03-0$i',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
      }
      for (var i = 7; i <= 10; i++) {
        final d = i < 10 ? '0$i' : '$i';
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-03-$d',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );
      }

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(OverallAttendanceHero),
          matching: find.text('60%'),
        ),
        findsOneWidget,
      );
      expect(find.text('-15.0%'), findsOneWidget);

      // Recovery card
      expect(find.text('Needs 6 Consecutive Presents'), findsOneWidget);
      expect(
        find.text(
          'Attend the next 6 classes with zero absences to reach 75% attendance.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('renders Component Average provisional state correctly', (
      tester,
    ) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Fall 2026',
        attendanceThreshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      final subId = await subRepo.createSubject(
        semesterId: semId,
        name: 'Physics',
        lectureEnabled: true,
        labEnabled: true,
      );

      final attRepo = AttendanceRepositoryImpl(db);
      // Only lecture has sessions, lab has none
      await attRepo.createSession(
        subjectId: subId,
        sessionDate: '2026-04-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Combined percentage must not be treated as final; provisional note shown
      expect(
        find.text('Combined available when both components have sessions.'),
        findsOneWidget,
      );
      expect(find.text('Depends on the next classes'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('navigates to subjects screen when tapping View All', (
      tester,
    ) async {
      var navigated = false;

      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Fall 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      await subRepo.createSubject(
        semesterId: semId,
        name: 'Operating Systems',
        lectureEnabled: true,
        labEnabled: true,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(onNavigateToSubjects: () => navigated = true),
      );
      await tester.pumpAndSettle();

      expect(find.text('View All'), findsOneWidget);
      await tester.ensureVisible(find.text('View All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(navigated, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('shows trend empty state when fewer than 2 dates logged', (
      tester,
    ) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Fall 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      final subId = await subRepo.createSubject(
        semesterId: semId,
        name: 'Chemistry',
        lectureEnabled: true,
        labEnabled: false,
      );

      final attRepo = AttendanceRepositoryImpl(db);
      // Only 1 session on 1 date
      await attRepo.createSession(
        subjectId: subId,
        sessionDate: '2026-05-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Trend empty state
      expect(find.text('More Data Needed'), findsOneWidget);
      expect(
        find.text(
          'Trend visualization appears after sessions across at least two dates are logged.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('renders trend chart when 2 or more dates logged', (
      tester,
    ) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Fall 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      final subId = await subRepo.createSubject(
        semesterId: semId,
        name: 'Chemistry',
        lectureEnabled: true,
        labEnabled: false,
      );

      final attRepo = AttendanceRepositoryImpl(db);
      await attRepo.createSession(
        subjectId: subId,
        sessionDate: '2026-05-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );
      await attRepo.createSession(
        subjectId: subId,
        sessionDate: '2026-05-02',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Analytics section and trend chart are rendered without redundant target label
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.byType(DashboardTrendCard), findsOneWidget);
      expect(find.text('May 1 – May 2'), findsOneWidget);
      expect(find.text('Latest: '), findsOneWidget);
      expect(find.text('75% Target'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'reactively updates dashboard when attendance session is logged',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Fall 2026',
          attendanceThreshold: 0.75,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        final subId = await subRepo.createSubject(
          semesterId: semId,
          name: 'Calculus',
          lectureEnabled: true,
          labEnabled: false,
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Initially empty
        expect(find.text('No Classes Recorded Yet'), findsOneWidget);
        expect(find.text('—'), findsOneWidget);

        // Log a session
        final attRepo = AttendanceRepositoryImpl(db);
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-05-10',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        // Settle UI stream
        await tester.pump();
        await tester.pumpAndSettle();

        // Should now display 100% in hero, 1 conducted, 1 present
        expect(
          find.descendant(
            of: find.byType(OverallAttendanceHero),
            matching: find.text('100%'),
          ),
          findsOneWidget,
        );
        expect(find.text('+25.0%'), findsOneWidget);
        expect(find.text('Conducted'), findsOneWidget);
        expect(find.text('1'), findsWidgets);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'does not overflow on narrow screens with Component Average and provisional badge',
      (tester) async {
        // Set narrow screen size (320px width)
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Narrow Screen Term',
          attendanceThreshold: 0.75,
          calculationMethod: AttendanceCalculationMethod.componentAverage,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        final subId = await subRepo.createSubject(
          semesterId: semId,
          name: 'Operating Systems & Architecture',
          lectureEnabled: true,
          labEnabled: true,
        );

        final attRepo = AttendanceRepositoryImpl(db);
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-05-10',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Verify widgets rendered cleanly without throwing RenderFlex overflow
        expect(
          find.text('Combined available when both components have sessions.'),
          findsOneWidget,
        );
        expect(find.text('Target: 75%'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'toggles between Overall and This Month attendance scope on dashboard',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Fall 2026',
          attendanceThreshold: 0.75,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        final subId = await subRepo.createSubject(
          semesterId: semId,
          name: 'Computer Networks',
          lectureEnabled: true,
          labEnabled: false,
        );

        final now = DateTime.now();
        final currentMonthStr =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-05';

        final attRepo = AttendanceRepositoryImpl(db);
        // Past month sessions (4 conducted: 2 present, 2 absent)
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2025-01-01',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2025-01-02',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );

        // Current month sessions (2 conducted: 2 present = 100%)
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: currentMonthStr,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: currentMonthStr,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // 1. Initially Overall: Total Conducted = 4 (2 past + 2 current)
        expect(find.text('Overall'), findsOneWidget);
        expect(find.text('This Month'), findsOneWidget);
        expect(find.text('Total Percentage'), findsOneWidget);
        expect(find.text('4'), findsOneWidget); // Conducted

        // 2. Tap "This Month"
        await tester.tap(find.text('This Month'));
        await tester.pumpAndSettle();

        // Current month has 2 sessions (2 present = 100%)
        expect(find.text('Total Percentage'), findsNothing);
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('2'), findsNWidgets(2)); // Conducted 2, Present 2

        // 3. Tap "Overall" again
        await tester.tap(find.text('Overall'));
        await tester.pumpAndSettle();

        expect(find.text('Total Percentage'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'tapping "+ X more subjects to review" reveals remaining subjects in-place without navigating away',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Fall 2026',
          attendanceThreshold: 0.75,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        // Create 6 subjects (all unrecorded = attention subjects)
        for (var i = 1; i <= 6; i++) {
          await subRepo.createSubject(
            semesterId: semId,
            name: 'Course $i',
            lectureEnabled: true,
            labEnabled: false,
          );
        }

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Needs Attention section should show Course 1 to 4 initially
        expect(find.text('Course 1'), findsOneWidget);
        expect(find.text('Course 4'), findsOneWidget);
        expect(find.text('Course 5'), findsNothing);
        expect(find.text('Course 6'), findsNothing);

        // Verify "+ 2 more subjects to review" button
        final expandButton = find.text('+ 2 more subjects to review');
        await tester.ensureVisible(expandButton);
        await tester.pumpAndSettle();
        expect(expandButton, findsOneWidget);

        // Tap expand button: reveals Course 5 and Course 6 in-place
        await tester.tap(expandButton);
        await tester.pumpAndSettle();

        final course5 = find.text('Course 5');
        await tester.ensureVisible(course5);
        expect(course5, findsOneWidget);
        expect(find.text('Course 6'), findsOneWidget);

        final showLessButton = find.text('Show less');
        await tester.ensureVisible(showLessButton);
        expect(showLessButton, findsOneWidget);

        // Tap "Show less": collapses back
        await tester.tap(showLessButton);
        await tester.pumpAndSettle();

        expect(find.text('Course 5'), findsNothing);
        expect(find.text('Course 6'), findsNothing);
        expect(find.text('+ 2 more subjects to review'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });
}
