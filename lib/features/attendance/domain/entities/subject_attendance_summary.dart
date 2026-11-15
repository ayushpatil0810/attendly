import 'attendance_availability.dart';
import 'component_attendance_summary.dart';
import 'recovery_result.dart';
import 'safe_absence_result.dart';
import 'threshold_status.dart';

class SubjectAttendanceSummary {
  const SubjectAttendanceSummary({
    required this.subjectId,
    required this.subjectName,
    required this.lectureEnabled,
    required this.labEnabled,
    this.lectureSummary,
    this.labSummary,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalConducted,
    this.percentage,
    required this.availability,
    required this.thresholdStatus,
    required this.safeAbsenceResult,
    required this.recoveryResult,
  });

  final int subjectId;
  final String subjectName;
  final bool lectureEnabled;
  final bool labEnabled;
  final ComponentAttendanceSummary? lectureSummary;
  final ComponentAttendanceSummary? labSummary;
  final int totalPresent;
  final int totalAbsent;
  final int totalConducted;
  final double? percentage;
  final AttendanceAvailability availability;
  final ThresholdStatus thresholdStatus;
  final SafeAbsenceResult safeAbsenceResult;
  final RecoveryResult recoveryResult;

  bool get isAvailable => availability.isAvailable;
  bool get isProvisional => availability.isProvisional;
  bool get isNotAvailable => availability.isNotAvailable;

  bool get meetsThreshold => thresholdStatus == ThresholdStatus.meeting;
  bool get isBelowThreshold => thresholdStatus == ThresholdStatus.below;

  String get formattedPercentage {
    if (percentage == null || isNotAvailable) return '—';
    final pct = percentage!;
    if (pct == pct.roundToDouble()) return '${pct.toInt()}%';
    return '${pct.toStringAsFixed(1)}%';
  }

  int? get roundedPercentage => percentage?.round();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectAttendanceSummary &&
          runtimeType == other.runtimeType &&
          subjectId == other.subjectId &&
          subjectName == other.subjectName &&
          lectureEnabled == other.lectureEnabled &&
          labEnabled == other.labEnabled &&
          lectureSummary == other.lectureSummary &&
          labSummary == other.labSummary &&
          totalPresent == other.totalPresent &&
          totalAbsent == other.totalAbsent &&
          totalConducted == other.totalConducted &&
          percentage == other.percentage &&
          availability == other.availability &&
          thresholdStatus == other.thresholdStatus &&
          safeAbsenceResult == other.safeAbsenceResult &&
          recoveryResult == other.recoveryResult;

  @override
  int get hashCode =>
      subjectId.hashCode ^
      subjectName.hashCode ^
      lectureEnabled.hashCode ^
      labEnabled.hashCode ^
      lectureSummary.hashCode ^
      labSummary.hashCode ^
      totalPresent.hashCode ^
      totalAbsent.hashCode ^
      totalConducted.hashCode ^
      percentage.hashCode ^
      availability.hashCode ^
      thresholdStatus.hashCode ^
      safeAbsenceResult.hashCode ^
      recoveryResult.hashCode;
}
