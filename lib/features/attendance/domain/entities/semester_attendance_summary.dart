import 'attendance_availability.dart';
import 'attendance_calculation_method.dart';
import 'attendance_trend_point.dart';
import 'recovery_result.dart';
import 'safe_absence_result.dart';
import 'subject_attendance_summary.dart';
import 'threshold_status.dart';

class SemesterAttendanceSummary {
  const SemesterAttendanceSummary({
    required this.semesterId,
    required this.semesterName,
    required this.threshold,
    required this.calculationMethod,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalConducted,
    required this.lecturePresent,
    required this.lectureConducted,
    required this.labPresent,
    required this.labConducted,
    this.lecturePercentage,
    this.labPercentage,
    this.overallPercentage,
    required this.availability,
    required this.thresholdStatus,
    this.differenceFromThreshold,
    required this.safeAbsenceResult,
    required this.recoveryResult,
    this.targetGoal = 0.85,
    this.goalRecoveryResult = const RecoveryResult.notAvailable(),
    required this.subjectSummaries,
    required this.trendPoints,
  });

  final int semesterId;
  final String semesterName;
  final double threshold;
  final AttendanceCalculationMethod calculationMethod;
  final int totalPresent;
  final int totalAbsent;
  final int totalConducted;
  final int lecturePresent;
  final int lectureConducted;
  final int labPresent;
  final int labConducted;
  final double? lecturePercentage;
  final double? labPercentage;
  final double? overallPercentage;
  final AttendanceAvailability availability;
  final ThresholdStatus thresholdStatus;
  final double? differenceFromThreshold;
  final SafeAbsenceResult safeAbsenceResult;
  final RecoveryResult recoveryResult;
  final double targetGoal;
  final RecoveryResult goalRecoveryResult;
  final List<SubjectAttendanceSummary> subjectSummaries;
  final List<AttendanceTrendPoint> trendPoints;

  int get thresholdPercent => (threshold * 100).round();
  int get targetGoalPercent => (targetGoal * 100).round();

  int? get roundedPercentage => overallPercentage?.round();

  bool get isAvailable => availability.isAvailable;
  bool get isProvisional => availability.isProvisional;
  bool get isNotAvailable => availability.isNotAvailable;

  bool get meetsThreshold => thresholdStatus == ThresholdStatus.meeting;
  bool get isBelowThreshold => thresholdStatus == ThresholdStatus.below;

  bool get meetsGoal =>
      overallPercentage != null &&
      !isNotAvailable &&
      overallPercentage! >= (targetGoal * 100.0 - 1e-9);

  double? get differenceFromGoal => overallPercentage != null
      ? overallPercentage! - (targetGoal * 100.0)
      : null;

  String get formattedPercentage {
    if (overallPercentage == null || isNotAvailable) return '—';
    final pct = overallPercentage!;
    if (pct == pct.roundToDouble()) return '${pct.toInt()}%';
    return '${pct.toStringAsFixed(1)}%';
  }

  int get totalSubjects => subjectSummaries.length;

  int get subjectsNeedingAttention => subjectSummaries
      .where(
        (s) =>
            s.thresholdStatus == ThresholdStatus.below ||
            (s.availability.isProvisional &&
                s.percentage != null &&
                s.percentage! < threshold * 100),
      )
      .length;
}
