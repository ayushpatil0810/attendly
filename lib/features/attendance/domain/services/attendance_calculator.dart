import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';

import '../entities/attendance_availability.dart';
import '../entities/attendance_calculation_method.dart';
import '../entities/attendance_session.dart';
import '../entities/attendance_trend_point.dart';
import '../entities/component_attendance_summary.dart';
import '../entities/semester_attendance_summary.dart';
import '../entities/session_component.dart';
import '../entities/subject_attendance_summary.dart';
import '../entities/threshold_status.dart';
import 'recovery_calculator.dart';
import 'safe_absence_calculator.dart';

class AttendanceCalculator {
  const AttendanceCalculator({
    this.safeAbsenceCalculator = const SafeAbsenceCalculator(),
    this.recoveryCalculator = const RecoveryCalculator(),
  });

  final SafeAbsenceCalculator safeAbsenceCalculator;
  final RecoveryCalculator recoveryCalculator;

  /// Calculates attendance summary for a single component (Lecture or Lab).
  ComponentAttendanceSummary calculateComponent({
    required SessionComponent component,
    required int presentCount,
    required int conductedCount,
    required bool isEnabled,
  }) {
    final absentCount = conductedCount - presentCount;
    if (conductedCount == 0 || !isEnabled) {
      return ComponentAttendanceSummary(
        component: component,
        presentCount: presentCount,
        absentCount: absentCount,
        conductedCount: conductedCount,
        percentage: null,
        availability: AttendanceAvailability.notAvailable,
        isEnabled: isEnabled,
      );
    }

    final pct = (presentCount / conductedCount) * 100.0;
    return ComponentAttendanceSummary(
      component: component,
      presentCount: presentCount,
      absentCount: absentCount,
      conductedCount: conductedCount,
      percentage: pct,
      availability: AttendanceAvailability.available,
      isEnabled: isEnabled,
    );
  }

  /// Calculates attendance summary for a single subject.
  SubjectAttendanceSummary calculateSubject({
    required Subject subject,
    required List<AttendanceSession> sessions,
    required double threshold,
    required AttendanceCalculationMethod calculationMethod,
    double targetGoal = 0.85,
  }) {
    // Filter sessions belonging to this subject
    final subjectSessions = sessions
        .where((s) => s.subjectId == subject.id)
        .toList();

    var lecPresent = 0;
    var lecConducted = 0;
    var labPresent = 0;
    var labConducted = 0;

    for (final session in subjectSessions) {
      if (session.component == SessionComponent.lecture) {
        lecConducted++;
        if (session.isPresent) lecPresent++;
      } else if (session.component == SessionComponent.lab) {
        labConducted++;
        if (session.isPresent) labPresent++;
      }
    }

    final lecSummary = subject.lectureEnabled
        ? calculateComponent(
            component: SessionComponent.lecture,
            presentCount: lecPresent,
            conductedCount: lecConducted,
            isEnabled: true,
          )
        : null;

    final labSummary = subject.labEnabled
        ? calculateComponent(
            component: SessionComponent.lab,
            presentCount: labPresent,
            conductedCount: labConducted,
            isEnabled: true,
          )
        : null;

    final totalPresent = lecPresent + labPresent;
    final totalConducted = lecConducted + labConducted;
    final totalAbsent = totalConducted - totalPresent;

    double? percentage;
    AttendanceAvailability availability;
    ThresholdStatus thresholdStatus;

    if (totalConducted == 0) {
      percentage = null;
      availability = AttendanceAvailability.notAvailable;
      thresholdStatus = ThresholdStatus.notAvailable;
    } else if (calculationMethod == AttendanceCalculationMethod.rawCombined) {
      percentage = (totalPresent / totalConducted) * 100.0;
      availability = AttendanceAvailability.available;
      thresholdStatus = (percentage >= threshold * 100.0 - 1e-9)
          ? ThresholdStatus.meeting
          : ThresholdStatus.below;
    } else {
      // Component Average (50/50)
      if (subject.lectureEnabled && subject.labEnabled) {
        if (lecConducted > 0 && labConducted > 0) {
          final lecPct = (lecPresent / lecConducted) * 100.0;
          final labPct = (labPresent / labConducted) * 100.0;
          percentage = (lecPct + labPct) / 2.0;
          availability = AttendanceAvailability.available;
          thresholdStatus = (percentage >= threshold * 100.0 - 1e-9)
              ? ThresholdStatus.meeting
              : ThresholdStatus.below;
        } else if (lecConducted > 0) {
          // Lab has no sessions -> provisional
          percentage = (lecPresent / lecConducted) * 100.0;
          availability = AttendanceAvailability.provisional;
          thresholdStatus = ThresholdStatus.notAvailable;
        } else if (labConducted > 0) {
          // Lecture has no sessions -> provisional
          percentage = (labPresent / labConducted) * 100.0;
          availability = AttendanceAvailability.provisional;
          thresholdStatus = ThresholdStatus.notAvailable;
        } else {
          percentage = null;
          availability = AttendanceAvailability.notAvailable;
          thresholdStatus = ThresholdStatus.notAvailable;
        }
      } else if (subject.lectureEnabled) {
        if (lecConducted > 0) {
          percentage = (lecPresent / lecConducted) * 100.0;
          availability = AttendanceAvailability.available;
          thresholdStatus = (percentage >= threshold * 100.0 - 1e-9)
              ? ThresholdStatus.meeting
              : ThresholdStatus.below;
        } else {
          percentage = null;
          availability = AttendanceAvailability.notAvailable;
          thresholdStatus = ThresholdStatus.notAvailable;
        }
      } else if (subject.labEnabled) {
        if (labConducted > 0) {
          percentage = (labPresent / labConducted) * 100.0;
          availability = AttendanceAvailability.available;
          thresholdStatus = (percentage >= threshold * 100.0 - 1e-9)
              ? ThresholdStatus.meeting
              : ThresholdStatus.below;
        } else {
          percentage = null;
          availability = AttendanceAvailability.notAvailable;
          thresholdStatus = ThresholdStatus.notAvailable;
        }
      } else {
        percentage = null;
        availability = AttendanceAvailability.notAvailable;
        thresholdStatus = ThresholdStatus.notAvailable;
      }
    }

    final safeAbsences = safeAbsenceCalculator.calculate(
      present: totalPresent,
      conducted: totalConducted,
      threshold: threshold,
      calculationMethod: calculationMethod,
    );

    final recovery = recoveryCalculator.calculate(
      present: totalPresent,
      conducted: totalConducted,
      threshold: threshold,
      calculationMethod: calculationMethod,
    );

    final goalRecovery = recoveryCalculator.calculateGoalRecovery(
      present: totalPresent,
      conducted: totalConducted,
      goal: targetGoal,
      calculationMethod: calculationMethod,
    );

    return SubjectAttendanceSummary(
      subjectId: subject.id,
      subjectName: subject.name,
      lectureEnabled: subject.lectureEnabled,
      labEnabled: subject.labEnabled,
      lectureSummary: lecSummary,
      labSummary: labSummary,
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      totalConducted: totalConducted,
      percentage: percentage,
      availability: availability,
      thresholdStatus: thresholdStatus,
      safeAbsenceResult: safeAbsences,
      recoveryResult: recovery,
      targetGoal: targetGoal,
      goalRecoveryResult: goalRecovery,
    );
  }

  /// Calculates semester-level overall attendance summary.
  SemesterAttendanceSummary calculateSemester({
    required Semester semester,
    required List<Subject> subjects,
    required List<AttendanceSession> sessions,
  }) {
    final subjectSummaries = subjects
        .map(
          (subject) => calculateSubject(
            subject: subject,
            sessions: sessions,
            threshold: semester.attendanceThreshold,
            calculationMethod: semester.calculationMethod,
            targetGoal: semester.targetGoal,
          ),
        )
        .toList();

    var totalLecPresent = 0;
    var totalLecConducted = 0;
    var totalLabPresent = 0;
    var totalLabConducted = 0;

    for (final session in sessions) {
      if (session.component == SessionComponent.lecture) {
        totalLecConducted++;
        if (session.isPresent) totalLecPresent++;
      } else if (session.component == SessionComponent.lab) {
        totalLabConducted++;
        if (session.isPresent) totalLabPresent++;
      }
    }

    final totalPresent = totalLecPresent + totalLabPresent;
    final totalConducted = totalLecConducted + totalLabConducted;
    final totalAbsent = totalConducted - totalPresent;

    final double? lecPct = totalLecConducted > 0
        ? (totalLecPresent / totalLecConducted) * 100.0
        : null;
    final double? labPct = totalLabConducted > 0
        ? (totalLabPresent / totalLabConducted) * 100.0
        : null;

    double? overallPct;
    AttendanceAvailability availability;
    ThresholdStatus thresholdStatus;
    double? differenceFromThreshold;

    final anyLectureEnabled = subjects.isEmpty
        ? true
        : subjects.any((s) => s.lectureEnabled);
    final anyLabEnabled = subjects.isEmpty
        ? false
        : subjects.any((s) => s.labEnabled);

    if (totalConducted == 0) {
      overallPct = null;
      availability = AttendanceAvailability.notAvailable;
      thresholdStatus = ThresholdStatus.notAvailable;
      differenceFromThreshold = null;
    } else if (semester.calculationMethod ==
        AttendanceCalculationMethod.rawCombined) {
      overallPct = (totalPresent / totalConducted) * 100.0;
      availability = AttendanceAvailability.available;
      thresholdStatus =
          (overallPct >= semester.attendanceThreshold * 100.0 - 1e-9)
          ? ThresholdStatus.meeting
          : ThresholdStatus.below;
      differenceFromThreshold =
          overallPct - (semester.attendanceThreshold * 100.0);
    } else {
      // Component Average (50/50)
      if (anyLectureEnabled && anyLabEnabled) {
        if (totalLecConducted > 0 && totalLabConducted > 0) {
          overallPct = (lecPct! + labPct!) / 2.0;
          availability = AttendanceAvailability.available;
          thresholdStatus =
              (overallPct >= semester.attendanceThreshold * 100.0 - 1e-9)
              ? ThresholdStatus.meeting
              : ThresholdStatus.below;
          differenceFromThreshold =
              overallPct - (semester.attendanceThreshold * 100.0);
        } else if (totalLecConducted > 0) {
          // Lab enabled but has no sessions -> provisional lecture
          overallPct = lecPct;
          availability = AttendanceAvailability.provisional;
          thresholdStatus = ThresholdStatus.notAvailable;
          differenceFromThreshold = null;
        } else if (totalLabConducted > 0) {
          // Lecture enabled but has no sessions -> provisional lab
          overallPct = labPct;
          availability = AttendanceAvailability.provisional;
          thresholdStatus = ThresholdStatus.notAvailable;
          differenceFromThreshold = null;
        } else {
          overallPct = null;
          availability = AttendanceAvailability.notAvailable;
          thresholdStatus = ThresholdStatus.notAvailable;
          differenceFromThreshold = null;
        }
      } else if (anyLectureEnabled) {
        if (totalLecConducted > 0) {
          overallPct = lecPct;
          availability = AttendanceAvailability.available;
          thresholdStatus =
              (overallPct! >= semester.attendanceThreshold * 100.0 - 1e-9)
              ? ThresholdStatus.meeting
              : ThresholdStatus.below;
          differenceFromThreshold =
              overallPct - (semester.attendanceThreshold * 100.0);
        } else {
          overallPct = null;
          availability = AttendanceAvailability.notAvailable;
          thresholdStatus = ThresholdStatus.notAvailable;
          differenceFromThreshold = null;
        }
      } else if (anyLabEnabled) {
        if (totalLabConducted > 0) {
          overallPct = labPct;
          availability = AttendanceAvailability.available;
          thresholdStatus =
              (overallPct! >= semester.attendanceThreshold * 100.0 - 1e-9)
              ? ThresholdStatus.meeting
              : ThresholdStatus.below;
          differenceFromThreshold =
              overallPct - (semester.attendanceThreshold * 100.0);
        } else {
          overallPct = null;
          availability = AttendanceAvailability.notAvailable;
          thresholdStatus = ThresholdStatus.notAvailable;
          differenceFromThreshold = null;
        }
      } else {
        overallPct = null;
        availability = AttendanceAvailability.notAvailable;
        thresholdStatus = ThresholdStatus.notAvailable;
        differenceFromThreshold = null;
      }
    }

    final safeAbsences = safeAbsenceCalculator.calculate(
      present: totalPresent,
      conducted: totalConducted,
      threshold: semester.attendanceThreshold,
      calculationMethod: semester.calculationMethod,
    );

    final recovery = recoveryCalculator.calculate(
      present: totalPresent,
      conducted: totalConducted,
      threshold: semester.attendanceThreshold,
      calculationMethod: semester.calculationMethod,
    );

    final goalRecovery = recoveryCalculator.calculateGoalRecovery(
      present: totalPresent,
      conducted: totalConducted,
      goal: semester.targetGoal,
      calculationMethod: semester.calculationMethod,
    );

    // Compute Trend Points from actual recorded sessions
    final trendPoints = _computeTrendPoints(sessions);

    return SemesterAttendanceSummary(
      semesterId: semester.id,
      semesterName: semester.name,
      threshold: semester.attendanceThreshold,
      calculationMethod: semester.calculationMethod,
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      totalConducted: totalConducted,
      lecturePresent: totalLecPresent,
      lectureConducted: totalLecConducted,
      labPresent: totalLabPresent,
      labConducted: totalLabConducted,
      lecturePercentage: lecPct,
      labPercentage: labPct,
      overallPercentage: overallPct,
      availability: availability,
      thresholdStatus: thresholdStatus,
      differenceFromThreshold: differenceFromThreshold,
      safeAbsenceResult: safeAbsences,
      recoveryResult: recovery,
      targetGoal: semester.targetGoal,
      goalRecoveryResult: goalRecovery,
      subjectSummaries: subjectSummaries,
      trendPoints: trendPoints,
    );
  }

  List<AttendanceTrendPoint> _computeTrendPoints(
    List<AttendanceSession> sessions,
  ) {
    if (sessions.isEmpty) return const [];

    // Group sessions by date string
    final Map<String, List<AttendanceSession>> byDate = {};
    for (final session in sessions) {
      byDate.putIfAbsent(session.sessionDate, () => []).add(session);
    }

    // Sort dates chronologically
    final sortedDates = byDate.keys.toList()..sort();

    final List<AttendanceTrendPoint> points = [];
    var cumPresent = 0;
    var cumConducted = 0;

    for (final dateStr in sortedDates) {
      final dateSessions = byDate[dateStr]!;
      var dayPresent = 0;
      for (final s in dateSessions) {
        if (s.isPresent) dayPresent++;
      }
      final dayConducted = dateSessions.length;

      cumPresent += dayPresent;
      cumConducted += dayConducted;

      final parts = dateStr.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      final cumPct = cumConducted > 0
          ? (cumPresent / cumConducted) * 100.0
          : 0.0;

      points.add(
        AttendanceTrendPoint(
          date: date,
          dateStr: dateStr,
          presentOnDate: dayPresent,
          conductedOnDate: dayConducted,
          cumulativePresent: cumPresent,
          cumulativeConducted: cumConducted,
          cumulativePercentage: cumPct,
        ),
      );
    }

    return points;
  }
}
