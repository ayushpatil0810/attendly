import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/shared/widgets/apple/apple_week_strip.dart';
import 'package:attendly/core/theme/app_theme.dart';
import 'package:attendly/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/presentation/widgets/day_status_dots.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_subject_preview.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_trend_card.dart';
import 'package:attendly/features/dashboard/presentation/widgets/overall_attendance_hero.dart';
import 'package:attendly/features/insights/presentation/widgets/subject_comparison_card.dart';
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

  Widget buildHomeScreen({ThemeData? theme}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: HomeScreen(onNavigateToSubjects: () {}),
      ),
    );
  }

  group('Home Screen UX & Data Consistency Tests', () {
    testWidgets(
      '1. Progress ring and Trend Latest value match 100% under Component Average (50/50 split)',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Semester 1',
          attendanceThreshold: 0.74,
          calculationMethod: AttendanceCalculationMethod.componentAverage,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        final subId = await subRepo.createSubject(
          semesterId: semId,
          name: 'Computer Networks',
          lectureEnabled: true,
          labEnabled: true,
        );

        final attRepo = AttendanceRepositoryImpl(db);
        // Day 1: 10 Lectures present (100% Lecture)
        for (var i = 1; i <= 10; i++) {
          await attRepo.createSession(
            subjectId: subId,
            sessionDate: '2026-03-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
          );
        }
        // Day 2: 2 Labs: 1 Present, 1 Absent (50% Lab)
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-03-02',
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
        );
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-03-02',
          component: SessionComponent.lab,
          status: AttendanceStatus.absent,
        );

        // Expected Component Average: (100% + 50%) / 2 = 75.0%
        // Raw Combined would have been: 11 / 12 = 91.7%
        await tester.pumpWidget(buildHomeScreen());
        await tester.pumpAndSettle();

        // 1. Overall ring shows 75%
        expect(
          find.descendant(
            of: find.byType(OverallAttendanceHero),
            matching: find.text('75%'),
          ),
          findsOneWidget,
        );

        // 2. Trend card "Latest" shows 75.0% (NOT 91.7%)
        expect(
          find.descendant(
            of: find.byType(DashboardTrendCard),
            matching: find.text('75.0%'),
          ),
          findsOneWidget,
        );

        // 3. Info icon exists and has tooltip explaining calculation method
        final infoTooltipFinder = find.byTooltip('Calculated using 50/50 Lecture & Lab split');
        expect(infoTooltipFinder, findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      '2. Actionable class counts display under progress ring and in Needs Attention row',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Semester Fall',
          attendanceThreshold: 0.74,
          calculationMethod: AttendanceCalculationMethod.rawCombined,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        final subId = await subRepo.createSubject(
          semesterId: semId,
          name: 'Database Systems',
          lectureEnabled: true,
          labEnabled: false,
        );

        final attRepo = AttendanceRepositoryImpl(db);
        // 5 present, 3 absent (8 conducted = 62.5% < 74%)
        // Needs 4 consecutive classes: (5 + 4) / (8 + 4) = 9 / 12 = 75% >= 74%
        for (var i = 1; i <= 5; i++) {
          await attRepo.createSession(
            subjectId: subId,
            sessionDate: '2026-03-0$i',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
          );
        }
        for (var i = 6; i <= 8; i++) {
          await attRepo.createSession(
            subjectId: subId,
            sessionDate: '2026-03-0$i',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
          );
        }

        await tester.pumpWidget(buildHomeScreen());
        await tester.pumpAndSettle();

        // Under main progress ring: "Attend next 4 classes"
        expect(
          find.descendant(
            of: find.byType(OverallAttendanceHero),
            matching: find.text('Attend next 4 classes'),
          ),
          findsOneWidget,
        );

        // In Needs Attention section row: "Attend next 4 classes to reach 74%"
        expect(
          find.text('Attend next 4 classes to reach 74%'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      '3. Mixed attendance day renders both Mint and Coral dots on weekly strip identically with calendar',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Semester Fall',
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
        // Record 1 Present and 1 Absent on the same date (e.g. today)
        final now = DateTime.now();
        final dateKey =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        await attRepo.createSession(
          subjectId: subId,
          sessionDate: dateKey,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: dateKey,
          component: SessionComponent.lab,
          status: AttendanceStatus.absent,
        );

        await tester.pumpWidget(buildHomeScreen());
        await tester.pumpAndSettle();

        // Verify AppleWeekStrip contains DayStatusDots with both hasPresent and hasAbsent true
        final weekStripDots = find.descendant(
          of: find.byType(AppleWeekStrip),
          matching: find.byType(DayStatusDots),
        );
        expect(weekStripDots, findsWidgets);

        final statusDotsWidgets = tester.widgetList<DayStatusDots>(weekStripDots);
        final mixedDayDots = statusDotsWidgets.where(
          (d) => d.status.hasPresent && d.status.hasAbsent,
        );
        expect(mixedDayDots.length, 1);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      '4. Subject Comparison renders horizontal bars with full subject names without ellipsis truncation',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Semester Fall',
          attendanceThreshold: 0.75,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        const longSubjectName =
            'Advanced Computer Architecture & Distributed Systems';
        final subId = await subRepo.createSubject(
          semesterId: semId,
          name: longSubjectName,
          lectureEnabled: true,
          labEnabled: false,
        );

        final attRepo = AttendanceRepositoryImpl(db);
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-03-01',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-03-02',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        await tester.pumpWidget(buildHomeScreen());
        await tester.pumpAndSettle();

        // 1. Full subject name is rendered in Subject Comparison
        final subjectTextFinder = find.descendant(
          of: find.byType(SubjectComparisonCard),
          matching: find.text(longSubjectName),
        );
        expect(subjectTextFinder, findsOneWidget);

        final textWidget = tester.widget<Text>(subjectTextFinder);
        // Verify no ellipsis truncation
        expect(textWidget.overflow, isNot(TextOverflow.ellipsis));

        // 2. Count ratio (2/2) and 100% are displayed
        expect(
          find.descendant(
            of: find.byType(SubjectComparisonCard),
            matching: find.text('(2/2)'),
          ),
          findsOneWidget,
        );

        // 3. Trend card shows Y-axis labels and target pill
        expect(find.text('100%'), findsWidgets);
        expect(find.text('50%'), findsWidgets);
        expect(find.text('0%'), findsWidgets);
        expect(find.text('75% Target'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets('5. Renders cleanly in Dark Mode', (tester) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(
        name: 'Dark Term',
        attendanceThreshold: 0.75,
      );
      prefs.setInt('selected_active_semester_id_v1', semId);

      final subRepo = SubjectRepositoryImpl(db);
      final subId = await subRepo.createSubject(
        semesterId: semId,
        name: 'Cyber Security',
        lectureEnabled: true,
        labEnabled: false,
      );

      final attRepo = AttendanceRepositoryImpl(db);
      await attRepo.createSession(
        subjectId: subId,
        sessionDate: '2026-03-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );
      await attRepo.createSession(
        subjectId: subId,
        sessionDate: '2026-03-02',
        component: SessionComponent.lecture,
        status: AttendanceStatus.absent,
      );

      await tester.pumpWidget(buildHomeScreen(theme: AppTheme.darkTheme));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Cyber Security'), findsWidgets);
      expect(find.text('50%'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      '6. Needs Attention flags courses when Lab is below target and comparison splits components',
      (tester) async {
        final semRepo = SemesterRepositoryImpl(db);
        final semId = await semRepo.createSemester(
          name: 'Spring 2026',
          attendanceThreshold: 0.75,
        );
        prefs.setInt('selected_active_semester_id_v1', semId);

        final subRepo = SubjectRepositoryImpl(db);
        final subId = await subRepo.createSubject(
          semesterId: semId,
          name: 'Machine Learning',
          lectureEnabled: true,
          labEnabled: true,
        );

        final attRepo = AttendanceRepositoryImpl(db);
        // 10/10 Lectures present = 100%
        for (var i = 1; i <= 10; i++) {
          final day = i < 10 ? '0$i' : '$i';
          await attRepo.createSession(
            subjectId: subId,
            sessionDate: '2026-03-$day',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
          );
        }
        // 1/4 Labs present = 25% (failing 75% target)
        await attRepo.createSession(
          subjectId: subId,
          sessionDate: '2026-03-11',
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
        );
        for (var i = 12; i <= 14; i++) {
          await attRepo.createSession(
            subjectId: subId,
            sessionDate: '2026-03-$i',
            component: SessionComponent.lab,
            status: AttendanceStatus.absent,
          );
        }

        await tester.pumpWidget(buildHomeScreen());
        await tester.pumpAndSettle();

        // 1. "Needs Attention" section is surfaced on Home
        expect(find.text('Needs Attention'), findsOneWidget);

        // 2. Machine Learning is surfaced in Needs Attention with Lab alert
        expect(find.text('Machine Learning'), findsWidgets);
        expect(
          find.descendant(
            of: find.byType(DashboardSubjectPreview),
            matching: find.text('Lab: Attend next 8 classes'),
          ),
          findsOneWidget,
        );

        // 3. Subject Comparison Card has segmented control
        final comparisonFinder = find.byType(SubjectComparisonCard);
        expect(comparisonFinder, findsOneWidget);
        expect(
          find.descendant(
            of: comparisonFinder,
            matching: find.text('Lectures'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: comparisonFinder,
            matching: find.text('Labs'),
          ),
          findsOneWidget,
        );

        // 4. Default Lectures tab shows Machine Learning 100% (10/10)
        expect(
          find.descendant(
            of: comparisonFinder,
            matching: find.text('(10/10)'),
          ),
          findsOneWidget,
        );

        // 5. Scroll to comparison card and switch to Labs tab
        final labsFinder = find.descendant(
          of: comparisonFinder,
          matching: find.text('Labs'),
        );
        await tester.ensureVisible(labsFinder);
        await tester.pumpAndSettle();
        await tester.tap(labsFinder);
        await tester.pumpAndSettle();

        // 6. Displays Machine Learning Lab with 25% (1/4)
        expect(
          find.descendant(
            of: comparisonFinder,
            matching: find.text('Machine Learning Lab'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: comparisonFinder,
            matching: find.text('(1/4)'),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });
}
