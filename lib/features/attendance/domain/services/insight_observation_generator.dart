import 'package:intl/intl.dart';

import '../entities/insight_observation.dart';
import '../entities/semester_attendance_summary.dart';
import '../entities/threshold_status.dart';

/// Pure Dart service that generates factual, data-driven observations
/// from recorded attendance data.
///
/// Strictly avoids unsupported predictions, generic motivational statements,
/// or overconfident conclusions from few sessions.
class InsightObservationGenerator {
  const InsightObservationGenerator();

  /// Generates reliable factual observations from the provided [summary].
  List<InsightObservation> generateObservations(
    SemesterAttendanceSummary summary,
  ) {
    // Insufficient evidence: avoid conclusions from fewer than 3 total sessions
    if (summary.totalConducted < 3) {
      return const [];
    }

    final observations = <InsightObservation>[];

    // 1. Threshold & Overall Status Observation
    if (summary.isAvailable) {
      if (summary.meetsThreshold) {
        final diff = summary.differenceFromThreshold ?? 0.0;
        final formattedDiff = diff.toStringAsFixed(1);
        observations.add(
          InsightObservation(
            title: 'Meeting Attendance Target',
            message:
                'Overall attendance is ${summary.formattedPercentage}, which is $formattedDiff% above your ${summary.thresholdPercent}% threshold.',
            type: InsightObservationType.positive,
            badgeText: 'On Track',
          ),
        );

        final safeAbsences = summary.safeAbsenceResult.safeAbsences;
        if (safeAbsences != null && safeAbsences > 0) {
          final s = safeAbsences == 1 ? '' : 'es';
          observations.add(
            InsightObservation(
              title: 'Safe Absence Allowance',
              message:
                  'You can miss up to $safeAbsences additional class$s while keeping your attendance at or above ${summary.thresholdPercent}%.',
              type: InsightObservationType.info,
              badgeText: '$safeAbsences Class$s',
            ),
          );
        }
      } else if (summary.isBelowThreshold) {
        final diff = (summary.differenceFromThreshold ?? 0.0).abs();
        observations.add(
          InsightObservation(
            title: 'Below Attendance Target',
            message:
                'Overall attendance is ${summary.formattedPercentage}, currently ${diff.toStringAsFixed(1)}% below your required ${summary.thresholdPercent}% threshold.',
            type: InsightObservationType.warning,
            badgeText: 'Attention',
          ),
        );

        final recovery = summary.recoveryResult.requiredConsecutivePresents;
        if (recovery != null && recovery > 0) {
          final s = recovery == 1 ? 'session' : 'sessions';
          observations.add(
            InsightObservation(
              title: 'Recovery Requirement',
              message:
                  'Attending the next $recovery consecutive $s with no absences will restore attendance to ${summary.thresholdPercent}%.',
              type: InsightObservationType.warning,
              badgeText: '$recovery $s',
            ),
          );
        }
      }
    } else if (summary.isProvisional) {
      observations.add(
        const InsightObservation(
          title: 'Provisional Attendance Policy',
          message: 'Both a lecture and a lab need to be logged before the split total can be calculated.',
          type: InsightObservationType.info,
          badgeText: 'Provisional',
        ),
      );
    }

    // 2. Subject Specific Performance
    final belowSubjects = summary.subjectSummaries
        .where((s) => s.thresholdStatus == ThresholdStatus.below)
        .toList();

    if (belowSubjects.isNotEmpty) {
      final names = belowSubjects.map((s) => s.subjectName).join(', ');
      final verb = belowSubjects.length == 1 ? 'is' : 'are';
      observations.add(
        InsightObservation(
          title: 'Subject Below Threshold',
          message:
              '$names $verb currently below the ${summary.thresholdPercent}% attendance threshold.',
          type: InsightObservationType.warning,
          badgeText:
              '${belowSubjects.length} Subject${belowSubjects.length == 1 ? '' : 's'}',
        ),
      );
    } else if (summary.subjectSummaries.length >= 2 &&
        summary.subjectSummaries.every((s) => s.meetsThreshold)) {
      observations.add(
        const InsightObservation(
          title: 'Consistent Performance',
          message: 'All recorded subjects are currently meeting or exceeding your attendance target.',
          type: InsightObservationType.positive,
          badgeText: 'All Good',
        ),
      );
    }

    // 3. Component Performance Comparison (Lecture vs Lab)
    for (final subject in summary.subjectSummaries) {
      if (subject.lectureEnabled &&
          subject.labEnabled &&
          subject.lectureSummary?.percentage != null &&
          subject.labSummary?.percentage != null &&
          (subject.lectureSummary?.conductedCount ?? 0) >= 2 &&
          (subject.labSummary?.conductedCount ?? 0) >= 2) {
        final lecPct = subject.lectureSummary!.percentage!;
        final labPct = subject.labSummary!.percentage!;
        final diff = labPct - lecPct;

        if (diff.abs() >= 10.0) {
          if (diff > 0) {
            observations.add(
              InsightObservation(
                title: 'Component Imbalance in ${subject.subjectName}',
                message:
                    'Lab attendance (${labPct.toStringAsFixed(0)}%) is ${diff.toStringAsFixed(0)}% higher than Lecture (${lecPct.toStringAsFixed(0)}%).',
                type: InsightObservationType.neutral,
                badgeText: 'Lecture Lag',
              ),
            );
          } else {
            observations.add(
              InsightObservation(
                title: 'Component Imbalance in ${subject.subjectName}',
                message:
                    'Lecture attendance (${lecPct.toStringAsFixed(0)}%) is ${(-diff).toStringAsFixed(0)}% higher than Lab (${labPct.toStringAsFixed(0)}%).',
                type: InsightObservationType.neutral,
                badgeText: 'Lab Lag',
              ),
            );
          }
        }
      }
    }

    // 4. Chronological Trend Trajectory (minimum 4 distinct session dates for significance)
    if (summary.trendPoints.length >= 4) {
      final firstPoint = summary.trendPoints.first;
      final lastPoint = summary.trendPoints.last;
      final trendDiff =
          lastPoint.cumulativePercentage - firstPoint.cumulativePercentage;

      final dateFormat = DateFormat('MMM d');
      final firstDateStr = dateFormat.format(firstPoint.date);

      if (trendDiff >= 5.0) {
        observations.add(
          InsightObservation(
            title: 'Improving Attendance Trend',
            message:
                'Overall attendance has improved by ${trendDiff.toStringAsFixed(1)}% since your first recorded date on $firstDateStr.',
            type: InsightObservationType.positive,
            badgeText: '+${trendDiff.toStringAsFixed(1)}%',
          ),
        );
      } else if (trendDiff <= -5.0) {
        observations.add(
          InsightObservation(
            title: 'Declining Attendance Trend',
            message:
                'Overall attendance has declined by ${(-trendDiff).toStringAsFixed(1)}% since your first recorded date on $firstDateStr.',
            type: InsightObservationType.warning,
            badgeText: '${trendDiff.toStringAsFixed(1)}%',
          ),
        );
      }
    }

    return observations;
  }
}
