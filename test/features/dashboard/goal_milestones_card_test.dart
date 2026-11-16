import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_availability.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/recovery_result.dart';
import 'package:attendly/features/attendance/domain/entities/safe_absence_result.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/dashboard/presentation/widgets/goal_milestones_card.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestWidget({
    required SemesterAttendanceSummary summary,
    required Semester semester,
  }) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoalMilestonesCard(summary: summary, semester: semester),
          ),
        ),
      ),
    );
  }

  final testSemester = Semester(
    id: 1,
    name: 'Fall 2026',
    attendanceThreshold: 0.75,
    calculationMethod: AttendanceCalculationMethod.rawCombined,
    targetGoal: 0.85,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets(
    'GoalMilestonesCard displays goal percentage and milestone badges',
    (tester) async {
      final summary = SemesterAttendanceSummary(
        semesterId: 1,
        semesterName: 'Fall 2026',
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
        totalPresent: 26,
        totalAbsent: 4,
        totalConducted: 30,
        lecturePresent: 20,
        lectureConducted: 22,
        labPresent: 6,
        labConducted: 8,
        overallPercentage: 86.7,
        availability: AttendanceAvailability.available,
        thresholdStatus: ThresholdStatus.meeting,
        targetGoal: 0.85,
        safeAbsenceResult: const SafeAbsenceResult(
          safeAbsences: 4,
          isAvailable: true,
          message: '',
        ),
        recoveryResult: const RecoveryResult.notNeeded(),
        goalRecoveryResult: const RecoveryResult.notNeeded(
          message: 'Goal reached!',
        ),
        subjectSummaries: const [],
        trendPoints: const [],
      );

      await tester.pumpWidget(
        buildTestWidget(summary: summary, semester: testSemester),
      );
      await tester.pumpAndSettle();

      // Verify Title & Goal Badge
      expect(find.text('Personal Goal'), findsOneWidget);
      expect(find.text('85%'), findsWidgets);

      // Verify Goal Met message (86.7% >= 85%)
      expect(find.text('Personal Goal Met! 🎉'), findsOneWidget);

      // Verify Milestones Section
      expect(find.text('Milestones'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    },
  );

  testWidgets(
    'GoalMilestonesCard displays consecutive classes advice when below goal',
    (tester) async {
      final summary = SemesterAttendanceSummary(
        semesterId: 1,
        semesterName: 'Fall 2026',
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
        totalPresent: 10,
        totalAbsent: 5,
        totalConducted: 15,
        lecturePresent: 10,
        lectureConducted: 15,
        labPresent: 0,
        labConducted: 0,
        overallPercentage: 66.7,
        availability: AttendanceAvailability.available,
        thresholdStatus: ThresholdStatus.below,
        targetGoal: 0.85,
        safeAbsenceResult: const SafeAbsenceResult(
          safeAbsences: 0,
          isAvailable: true,
          message: '',
        ),
        recoveryResult: const RecoveryResult(
          requiredConsecutivePresents: 5,
          isAvailable: true,
          message: 'Attend next 5 classes',
        ),
        goalRecoveryResult: const RecoveryResult(
          requiredConsecutivePresents: 19,
          isAvailable: true,
          message: 'Attend next 19 consecutive classes',
        ),
        subjectSummaries: const [],
        trendPoints: const [],
      );

      await tester.pumpWidget(
        buildTestWidget(summary: summary, semester: testSemester),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reach Your 85% Goal'), findsOneWidget);
      expect(
        find.textContaining(
          'Attend the next 19 consecutive classes with no absences',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Assumption: All upcoming sessions are attended without absences.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Tapping Edit opens goal adjustment sheet', (tester) async {
    final summary = SemesterAttendanceSummary(
      semesterId: 1,
      semesterName: 'Fall 2026',
      threshold: 0.75,
      calculationMethod: AttendanceCalculationMethod.rawCombined,
      totalPresent: 0,
      totalAbsent: 0,
      totalConducted: 0,
      lecturePresent: 0,
      lectureConducted: 0,
      labPresent: 0,
      labConducted: 0,
      availability: AttendanceAvailability.notAvailable,
      thresholdStatus: ThresholdStatus.notAvailable,
      targetGoal: 0.85,
      safeAbsenceResult: const SafeAbsenceResult.notAvailable(),
      recoveryResult: const RecoveryResult.notAvailable(),
      goalRecoveryResult: const RecoveryResult.notAvailable(),
      subjectSummaries: const [],
      trendPoints: const [],
    );

    await tester.pumpWidget(
      buildTestWidget(summary: summary, semester: testSemester),
    );
    await tester.pumpAndSettle();

    final editButton = find.text('Edit');
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.text('Target Goal'), findsOneWidget);
    expect(find.text('Save Goal'), findsOneWidget);
    expect(find.text('80%'), findsWidgets);
    expect(find.text('90%'), findsWidgets);
  });

  testWidgets('Tapping a milestone opens milestone detail sheet', (
    tester,
  ) async {
    final summary = SemesterAttendanceSummary(
      semesterId: 1,
      semesterName: 'Fall 2026',
      threshold: 0.75,
      calculationMethod: AttendanceCalculationMethod.rawCombined,
      totalPresent: 20,
      totalAbsent: 2,
      totalConducted: 22,
      lecturePresent: 20,
      lectureConducted: 22,
      labPresent: 0,
      labConducted: 0,
      overallPercentage: 90.9,
      availability: AttendanceAvailability.available,
      thresholdStatus: ThresholdStatus.meeting,
      targetGoal: 0.85,
      safeAbsenceResult: const SafeAbsenceResult(
        safeAbsences: 3,
        isAvailable: true,
        message: '',
      ),
      recoveryResult: const RecoveryResult.notNeeded(),
      goalRecoveryResult: const RecoveryResult.notNeeded(),
      subjectSummaries: const [],
      trendPoints: const [],
    );

    await tester.pumpWidget(
      buildTestWidget(summary: summary, semester: testSemester),
    );
    await tester.pumpAndSettle();

    final chip90 = find.text('90%');
    expect(chip90, findsOneWidget);

    await tester.tap(chip90);
    await tester.pumpAndSettle();

    expect(find.text('90% Milestone'), findsOneWidget);
    expect(find.textContaining('Unlocked & Achieved!'), findsOneWidget);
  });
}
