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
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/simulator/presentation/screens/simulator_screen.dart';
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
      child: const MaterialApp(home: SimulatorScreen()),
    );
  }

  group('SimulatorScreen Widget Tests', () {
    testWidgets('renders baseline attendance and empty simulation state', (
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
      // Actual baseline: 8 Present, 2 Absent = 80%
      for (var i = 1; i <= 8; i++) {
        await attRepo.createSession(
          subjectId: s1,
          sessionDate: '2026-11-${i.toString().padLeft(2, '0')}',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
      }
      for (var i = 1; i <= 2; i++) {
        await attRepo.createSession(
          subjectId: s1,
          sessionDate: '2026-11-${(i + 8).toString().padLeft(2, '0')}',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );
      }

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Attendance Simulator'), findsOneWidget);
      expect(find.text('Projected Outcome'), findsOneWidget);
      expect(find.text('Actual Baseline'), findsOneWidget);
      expect(
        find.text('80%'),
        findsWidgets,
      ); // Both baseline and projected start at 80%
      expect(find.text('No Hypothetical Sessions'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'adding +1 Present session updates projection and adds to session list',
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
        // 8/10 = 80%
        for (var i = 1; i <= 8; i++) {
          await attRepo.createSession(
            subjectId: s1,
            sessionDate: '2026-11-${i.toString().padLeft(2, '0')}',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
          );
        }
        for (var i = 1; i <= 2; i++) {
          await attRepo.createSession(
            subjectId: s1,
            sessionDate: '2026-11-${(i + 8).toString().padLeft(2, '0')}',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
          );
        }

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Tap '+1 Present'
        final addPresentButton = find.text('+1 Present');
        expect(addPresentButton, findsOneWidget);
        await tester.tap(addPresentButton);
        await tester.pumpAndSettle();

        // 9/11 = 81.8%
        expect(find.text('81.8%'), findsOneWidget);
        expect(find.text('Simulated Classes (1)'), findsOneWidget);
        expect(find.text('Reset Scenario'), findsOneWidget);
        expect(
          find.textContaining('projected attendance improvement'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'toggling simulated class status flips between Present and Absent',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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
          sessionDate: '2026-11-01',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Add 1 Present
        await tester.tap(find.text('+1 Present'));
        await tester.pumpAndSettle();

        // Find status toggle in the list
        final presentPill = find.descendant(
          of: find.byType(ListView),
          matching: find.text('Present'),
        );
        expect(presentPill, findsOneWidget);

        // Tap to toggle to Absent
        await tester.tap(presentPill);
        await tester.pumpAndSettle();

        // Should now be Absent in the list!
        final absentPill = find.descendant(
          of: find.byType(ListView),
          matching: find.text('Absent'),
        );
        expect(absentPill, findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets('tapping Reset Scenario clears hypothetical sessions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
        sessionDate: '2026-11-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Add two sessions
      await tester.tap(find.text('+1 Present'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1 Absent'));
      await tester.pumpAndSettle();

      expect(find.text('Simulated Classes (2)'), findsOneWidget);

      // Tap Reset Scenario
      await tester.tap(find.text('Reset Scenario'));
      await tester.pumpAndSettle();

      expect(find.text('Simulated Classes (0)'), findsOneWidget);
      expect(find.text('No Hypothetical Sessions'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('batch add (+3 Present) adds 3 sessions at once', (
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
        sessionDate: '2026-11-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap '+3 Present'
      await tester.tap(find.text('+3 Present'));
      await tester.pumpAndSettle();

      expect(find.text('Simulated Classes (3)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}
