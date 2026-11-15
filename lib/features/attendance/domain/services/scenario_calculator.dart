import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';

import '../entities/attendance_session.dart';
import '../entities/hypothetical_session.dart';
import '../entities/simulator_projection.dart';
import 'attendance_calculator.dart';

/// Calculation engine for the What-if Simulator.
///
/// Combines the actual recorded attendance baseline with hypothetical future sessions
/// to project overall attendance, threshold status, and subject breakdowns using the
/// authoritative [AttendanceCalculator] engine.
///
/// This service is 100% pure Dart and never writes to or interacts with the database.
class ScenarioCalculator {
  const ScenarioCalculator({
    this.attendanceCalculator = const AttendanceCalculator(),
  });

  final AttendanceCalculator attendanceCalculator;

  /// Calculates a [SimulatorProjection] from actual records and hypothetical sessions.
  SimulatorProjection calculateProjection({
    required Semester semester,
    required List<Subject> subjects,
    required List<AttendanceSession> actualSessions,
    required List<HypotheticalSession> hypotheticalSessions,
  }) {
    // 1. Calculate actual attendance baseline
    final baselineSummary = attendanceCalculator.calculateSemester(
      semester: semester,
      subjects: subjects,
      sessions: actualSessions,
    );

    // 2. If no hypothetical sessions, projected equals baseline
    if (hypotheticalSessions.isEmpty) {
      return SimulatorProjection(
        baselineSummary: baselineSummary,
        projectedSummary: baselineSummary,
        hypotheticalSessions: const [],
      );
    }

    // 3. Map hypothetical sessions to ephemeral AttendanceSession instances
    final now = DateTime.now();
    final dummyDate =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final simulatedSessions = <AttendanceSession>[];
    for (var i = 0; i < hypotheticalSessions.length; i++) {
      final h = hypotheticalSessions[i];
      simulatedSessions.add(
        AttendanceSession(
          id: -(i + 1), // Negative ID guarantees no collision with DB records
          subjectId: h.subjectId,
          sessionDate: dummyDate,
          component: h.component,
          status: h.status,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // 4. Combine actual and simulated sessions for projection calculation
    final combinedSessions = [...actualSessions, ...simulatedSessions];

    final projectedSummary = attendanceCalculator.calculateSemester(
      semester: semester,
      subjects: subjects,
      sessions: combinedSessions,
    );

    return SimulatorProjection(
      baselineSummary: baselineSummary,
      projectedSummary: projectedSummary,
      hypotheticalSessions: List.unmodifiable(hypotheticalSessions),
    );
  }
}
