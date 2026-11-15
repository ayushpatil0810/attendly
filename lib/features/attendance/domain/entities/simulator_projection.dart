import 'hypothetical_session.dart';
import 'semester_attendance_summary.dart';

/// Represents the mathematical projection computed by the What-if Simulator.
///
/// Combines the immutable actual attendance baseline with temporary hypothetical
/// sessions to evaluate projected attendance impact.
class SimulatorProjection {
  const SimulatorProjection({
    required this.baselineSummary,
    required this.projectedSummary,
    required this.hypotheticalSessions,
  });

  /// The actual recorded attendance baseline.
  final SemesterAttendanceSummary baselineSummary;

  /// The projected attendance summary incorporating actual + hypothetical sessions.
  final SemesterAttendanceSummary projectedSummary;

  /// The hypothetical sessions currently modeled.
  final List<HypotheticalSession> hypotheticalSessions;

  /// Total hypothetical sessions added.
  int get simulatedCount => hypotheticalSessions.length;

  /// Number of hypothetical sessions marked Present.
  int get simulatedPresentCount =>
      hypotheticalSessions.where((s) => s.isPresent).length;

  /// Number of hypothetical sessions marked Absent.
  int get simulatedAbsentCount =>
      hypotheticalSessions.where((s) => s.isAbsent).length;

  /// Whether any hypothetical sessions have been added to the scenario.
  bool get hasSimulatedSessions => hypotheticalSessions.isNotEmpty;

  /// The difference in percentage points between projected and baseline attendance.
  ///
  /// Returns null if either baseline or projected percentage is not available.
  double? get percentageDifference {
    if (baselineSummary.overallPercentage == null ||
        projectedSummary.overallPercentage == null) {
      return null;
    }
    return projectedSummary.overallPercentage! -
        baselineSummary.overallPercentage!;
  }

  /// Whether projected attendance meets the required threshold.
  bool get projectedMeetsThreshold => projectedSummary.meetsThreshold;

  /// Whether the projection caused a status transition from below threshold to meeting.
  bool get improvedToThreshold {
    return baselineSummary.isBelowThreshold && projectedSummary.meetsThreshold;
  }

  /// Whether the projection caused a status drop from meeting threshold to below.
  bool get droppedBelowThreshold {
    return baselineSummary.meetsThreshold && projectedSummary.isBelowThreshold;
  }
}
