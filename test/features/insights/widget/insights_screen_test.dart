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
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/shell/presentation/screens/insights_screen.dart';
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

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: InsightsScreen()),
    );
  }

  group('InsightsScreen Widget Tests', () {
    testWidgets('renders empty state when no sessions recorded', (
      tester,
    ) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Fall 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      await subRepo.createSubject(
        semesterId: semId,
        name: 'Networks',
        lectureEnabled: true,
        labEnabled: true,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsWidgets);
      expect(find.text('No Attendance Data Yet'), findsOneWidget);
      expect(find.text('Log First Class'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'renders populated insights with overview, subjects, and comparisons',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Fall 2026',
          attendanceThreshold: 0.75,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        final s1 = await subRepo.createSubject(
          semesterId: semId,
          name: 'Networks',
          lectureEnabled: true,
          labEnabled: true,
        );
        final s2 = await subRepo.createSubject(
          semesterId: semId,
          name: 'Algorithms',
          lectureEnabled: true,
          labEnabled: false,
        );

        final attRepo = AttendanceRepositoryImpl(db);
        // 8 Present, 2 Absent across different dates
        for (var i = 1; i <= 4; i++) {
          await attRepo.createSession(
            subjectId: s1,
            sessionDate: '2026-11-0$i',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
          );
        }
        for (var i = 5; i <= 6; i++) {
          await attRepo.createSession(
            subjectId: s1,
            sessionDate: '2026-11-0$i',
            component: SessionComponent.lab,
            status: AttendanceStatus.present,
          );
        }
        // Absent
        await attRepo.createSession(
          subjectId: s1,
          sessionDate: '2026-11-07',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );
        await attRepo.createSession(
          subjectId: s2,
          sessionDate: '2026-11-08',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Check Header & Overview
        expect(find.text('Attendance Overview'), findsOneWidget);
        expect(find.text('Equal weight'), findsWidgets);
        expect(find.text('Subject Comparison'), findsOneWidget);
        expect(find.text('Lecture vs. Lab Breakdown'), findsOneWidget);
        expect(find.text('Attendance History & Trend'), findsOneWidget);

        // Verify subject names appear in comparison
        expect(find.text('Networks'), findsWidgets);
        expect(find.text('Algorithms'), findsWidgets);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets('keeps the simulator on its own screen', (tester) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Fall 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      final subjectId = await subRepo.createSubject(
        semesterId: semId,
        name: 'Networks',
        lectureEnabled: true,
        labEnabled: true,
      );
      final attRepo = AttendanceRepositoryImpl(db);
      await attRepo.createSession(
        subjectId: subjectId,
        sessionDate: '2026-11-14',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('What-if'), findsOneWidget);
      expect(find.text('Add Hypothetical Classes'), findsNothing);
      expect(find.text('All classes'), findsOneWidget);
      expect(find.text('All Subjects'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('filtering by Last 7 Days updates filter chips', (
      tester,
    ) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Fall 2026',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      final s1 = await subRepo.createSubject(
        semesterId: semId,
        name: 'Networks',
        lectureEnabled: true,
        labEnabled: true,
      );

      final attRepo = AttendanceRepositoryImpl(db);
      await attRepo.createSession(
        subjectId: s1,
        sessionDate: '2026-11-14',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 'Last 7 Days'
      final last7Chip = find.text('Last 7 Days');
      expect(last7Chip, findsOneWidget);
      await tester.tap(last7Chip);
      await tester.pumpAndSettle();

      // Reset button should appear when filter is non-default
      expect(find.text('Reset'), findsOneWidget);

      // Tap Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('Reset'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'Component Average shows provisional state when one component lacks sessions',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Spring 2026',
          attendanceThreshold: 0.75,
          calculationMethod: AttendanceCalculationMethod.componentAverage,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        final s1 = await subRepo.createSubject(
          semesterId: semId,
          name: 'Networks',
          lectureEnabled: true,
          labEnabled: true,
        );

        final attRepo = AttendanceRepositoryImpl(db);
        // Only Lecture sessions, NO Lab sessions
        await attRepo.createSession(
          subjectId: s1,
          sessionDate: '2026-11-14',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Provisional'), findsWidgets);
        expect(find.text('50/50 Lecture & Lab'), findsWidgets);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'renders without RenderFlex overflow in narrow viewport (286px-320px)',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Spring 2026',
          attendanceThreshold: 0.75,
          calculationMethod: AttendanceCalculationMethod.componentAverage,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        final s1 = await subRepo.createSubject(
          semesterId: semId,
          name: 'Networks',
          lectureEnabled: true,
          labEnabled: true,
        );

        final attRepo = AttendanceRepositoryImpl(db);
        await attRepo.createSession(
          subjectId: s1,
          sessionDate: '2026-11-14',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        // Constrain to narrow device size (320px width)
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Attendance Overview'), findsOneWidget);
        expect(find.text('50/50 Lecture & Lab'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'hides Lecture vs. Lab Breakdown when filtered to a single component',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Fall 2026',
          attendanceThreshold: 0.75,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        final s1 = await subRepo.createSubject(
          semesterId: semId,
          name: 'Networks',
          lectureEnabled: true,
          labEnabled: true,
        );

        final attRepo = AttendanceRepositoryImpl(db);
        await attRepo.createSession(
          subjectId: s1,
          sessionDate: '2026-11-10',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
        await attRepo.createSession(
          subjectId: s1,
          sessionDate: '2026-11-11',
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Lecture vs. Lab Breakdown'), findsOneWidget);

        // Tap scope chip to filter to Lectures only
        await tester.tap(find.text('All classes'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lectures').last);
        await tester.pumpAndSettle();

        // Lecture vs. Lab breakdown should now be hidden
        expect(find.text('Lecture vs. Lab Breakdown'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });
}
