import 'attendance_availability.dart';
import 'recovery_result.dart';
import 'safe_absence_result.dart';
import 'session_component.dart';
import 'threshold_status.dart';

class ComponentAttendanceSummary {
  const ComponentAttendanceSummary({
    required this.component,
    required this.presentCount,
    required this.absentCount,
    required this.conductedCount,
    this.percentage,
    required this.availability,
    required this.isEnabled,
    this.thresholdStatus = ThresholdStatus.notAvailable,
    this.safeAbsenceResult = const SafeAbsenceResult.notAvailable(),
    this.recoveryResult = const RecoveryResult.notAvailable(),
    this.goalRecoveryResult = const RecoveryResult.notAvailable(),
  });

  final SessionComponent component;
  final int presentCount;
  final int absentCount;
  final int conductedCount;
  final double? percentage;
  final AttendanceAvailability availability;
  final bool isEnabled;
  final ThresholdStatus thresholdStatus;
  final SafeAbsenceResult safeAbsenceResult;
  final RecoveryResult recoveryResult;
  final RecoveryResult goalRecoveryResult;

  bool get isAvailable => availability.isAvailable;
  bool get isNotAvailable => availability.isNotAvailable;

  bool get meetsThreshold => thresholdStatus == ThresholdStatus.meeting;
  bool get isBelowThreshold => thresholdStatus == ThresholdStatus.below;

  String displayName(String baseSubjectName) {
    if (component == SessionComponent.lab) {
      if (baseSubjectName.toLowerCase().endsWith('lab')) {
        return baseSubjectName;
      }
      return '$baseSubjectName Lab';
    }
    return baseSubjectName;
  }

  String get formattedPercentage {
    if (percentage == null || isNotAvailable) return '—';
    final pct = percentage!;
    if (pct == pct.roundToDouble()) return '${pct.toInt()}%';
    return '${pct.toStringAsFixed(1)}%';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentAttendanceSummary &&
          runtimeType == other.runtimeType &&
          component == other.component &&
          presentCount == other.presentCount &&
          absentCount == other.absentCount &&
          conductedCount == other.conductedCount &&
          percentage == other.percentage &&
          availability == other.availability &&
          isEnabled == other.isEnabled &&
          thresholdStatus == other.thresholdStatus &&
          safeAbsenceResult == other.safeAbsenceResult &&
          recoveryResult == other.recoveryResult &&
          goalRecoveryResult == other.goalRecoveryResult;

  @override
  int get hashCode =>
      component.hashCode ^
      presentCount.hashCode ^
      absentCount.hashCode ^
      conductedCount.hashCode ^
      percentage.hashCode ^
      availability.hashCode ^
      isEnabled.hashCode ^
      thresholdStatus.hashCode ^
      safeAbsenceResult.hashCode ^
      recoveryResult.hashCode ^
      goalRecoveryResult.hashCode;
}

