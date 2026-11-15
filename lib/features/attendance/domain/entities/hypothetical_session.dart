import 'attendance_status.dart';
import 'session_component.dart';

/// A temporary hypothetical class session used exclusively in the What-if Simulator.
///
/// MUST NEVER be saved to the attendance database or treated as real attendance.
class HypotheticalSession {
  const HypotheticalSession({
    required this.id,
    required this.subjectId,
    required this.component,
    required this.status,
  });

  /// Ephemeral identifier within the simulator scenario.
  final String id;

  /// The subject this hypothetical session belongs to.
  final int subjectId;

  /// Whether this is a lecture or lab.
  final SessionComponent component;

  /// Hypothetical outcome: Present or Absent.
  final AttendanceStatus status;

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;

  HypotheticalSession copyWith({
    String? id,
    int? subjectId,
    SessionComponent? component,
    AttendanceStatus? status,
  }) {
    return HypotheticalSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      component: component ?? this.component,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HypotheticalSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subjectId == other.subjectId &&
          component == other.component &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, subjectId, component, status);

  @override
  String toString() =>
      'HypotheticalSession(id: $id, subjectId: $subjectId, component: ${component.name}, status: ${status.name})';
}
