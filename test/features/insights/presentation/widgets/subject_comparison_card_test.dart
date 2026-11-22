import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/shared/widgets/app_segmented_control.dart';
import 'package:attendly/core/theme/app_theme.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_availability.dart';
import 'package:attendly/features/attendance/domain/entities/component_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/recovery_result.dart';
import 'package:attendly/features/attendance/domain/entities/safe_absence_result.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/insights/presentation/widgets/subject_comparison_card.dart';

Widget _buildWrapper({required Widget child, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  group('SubjectComparisonCard - Split Lectures vs. Labs', () {
    testWidgets('1. Hides segmented control when only Lecture courses exist', (
      tester,
    ) async {
      final summaries = [
        const SubjectAttendanceSummary(
          subjectId: 1,
          subjectName: 'Mathematics',
          lectureEnabled: true,
          labEnabled: false,
          totalPresent: 8,
          totalAbsent: 2,
          totalConducted: 10,
          percentage: 80.0,
          availability: AttendanceAvailability.available,
          thresholdStatus: ThresholdStatus.meeting,
          safeAbsenceResult: SafeAbsenceResult(
            safeAbsences: 0,
            isAvailable: true,
            requiresScenario: false,
            message: 'Target met',
          ),
          recoveryResult: RecoveryResult.notNeeded(),
          lectureSummary: ComponentAttendanceSummary(
            component: SessionComponent.lecture,
            presentCount: 8,
            absentCount: 2,
            conductedCount: 10,
            percentage: 80.0,
            availability: AttendanceAvailability.available,
            isEnabled: true,
            thresholdStatus: ThresholdStatus.meeting,
          ),
        ),
      ];

      await tester.pumpWidget(
        _buildWrapper(
          child: SubjectComparisonCard(
            subjectSummaries: summaries,
            threshold: 0.75,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Segmented control should be hidden because there are no labs
      expect(
        find.byType(AppSegmentedControl<SessionComponent>),
        findsNothing,
      );
      expect(find.text('1 Lecture'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('(8/10)'), findsOneWidget);
    });

    testWidgets(
      '2. Shows segmented control and splits ML into Lectures vs Labs',
      (tester) async {
        final summaries = [
          const SubjectAttendanceSummary(
            subjectId: 1,
            subjectName: 'Machine Learning',
            lectureEnabled: true,
            labEnabled: true,
            totalPresent: 11,
            totalAbsent: 3,
            totalConducted: 14,
            percentage: 78.57,
            availability: AttendanceAvailability.available,
            thresholdStatus: ThresholdStatus.meeting,
            safeAbsenceResult: SafeAbsenceResult(
              safeAbsences: 0,
              isAvailable: true,
              requiresScenario: false,
              message: 'Target met',
            ),
            recoveryResult: RecoveryResult.notNeeded(),
            lectureSummary: ComponentAttendanceSummary(
              component: SessionComponent.lecture,
              presentCount: 10,
              absentCount: 0,
              conductedCount: 10,
              percentage: 100.0,
              availability: AttendanceAvailability.available,
              isEnabled: true,
              thresholdStatus: ThresholdStatus.meeting,
            ),
            labSummary: ComponentAttendanceSummary(
              component: SessionComponent.lab,
              presentCount: 1,
              absentCount: 3,
              conductedCount: 4,
              percentage: 25.0,
              availability: AttendanceAvailability.available,
              isEnabled: true,
              thresholdStatus: ThresholdStatus.below,
            ),
          ),
        ];

        await tester.pumpWidget(
          _buildWrapper(
            child: SubjectComparisonCard(
              subjectSummaries: summaries,
              threshold: 0.75,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Segmented control exists
        expect(
          find.byType(AppSegmentedControl<SessionComponent>),
          findsOneWidget,
        );
        expect(find.text('Lectures'), findsOneWidget);
        expect(find.text('Labs'), findsOneWidget);

        // 2. Default tab is Lectures: shows "Machine Learning" with 100% (10/10)
        expect(find.text('Machine Learning'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('(10/10)'), findsOneWidget);
        expect(find.text('Machine Learning Lab'), findsNothing);

        // 3. Switch to Labs tab
        await tester.tap(find.text('Labs'));
        await tester.pumpAndSettle();

        // 4. Now shows "Machine Learning Lab" with 25% (1/4)
        expect(find.text('Machine Learning Lab'), findsOneWidget);
        expect(find.text('25%'), findsOneWidget);
        expect(find.text('(1/4)'), findsOneWidget);
      },
    );

    testWidgets('3. Renders cleanly in Dark Mode with no overflow', (
      tester,
    ) async {
      final summaries = [
        const SubjectAttendanceSummary(
          subjectId: 1,
          subjectName: 'Design and Analysis of Algorithms',
          lectureEnabled: true,
          labEnabled: true,
          totalPresent: 14,
          totalAbsent: 2,
          totalConducted: 16,
          percentage: 87.5,
          availability: AttendanceAvailability.available,
          thresholdStatus: ThresholdStatus.meeting,
          safeAbsenceResult: SafeAbsenceResult(
            safeAbsences: 2,
            isAvailable: true,
            requiresScenario: false,
            message: 'Target met',
          ),
          recoveryResult: RecoveryResult.notNeeded(),
          lectureSummary: ComponentAttendanceSummary(
            component: SessionComponent.lecture,
            presentCount: 10,
            absentCount: 2,
            conductedCount: 12,
            percentage: 83.33,
            availability: AttendanceAvailability.available,
            isEnabled: true,
            thresholdStatus: ThresholdStatus.meeting,
          ),
          labSummary: ComponentAttendanceSummary(
            component: SessionComponent.lab,
            presentCount: 4,
            absentCount: 0,
            conductedCount: 4,
            percentage: 100.0,
            availability: AttendanceAvailability.available,
            isEnabled: true,
            thresholdStatus: ThresholdStatus.meeting,
          ),
        ),
      ];

      await tester.pumpWidget(
        _buildWrapper(
          theme: AppTheme.darkTheme,
          child: SubjectComparisonCard(
            subjectSummaries: summaries,
            threshold: 0.75,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Design and Analysis of Algorithms'),
        findsOneWidget,
      );
      expect(find.text('83%'), findsOneWidget);
      expect(find.text('(10/12)'), findsOneWidget);
    });
  });
}
