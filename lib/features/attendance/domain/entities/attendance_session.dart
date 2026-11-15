import 'attendance_status.dart';
import 'session_component.dart';

class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.subjectId,
    required this.sessionDate,
    required this.component,
    required this.status,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int subjectId;
  final String sessionDate; // ISO YYYY-MM-DD
  final SessionComponent component;
  final AttendanceStatus status;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;

  AttendanceSession copyWith({
    int? id,
    int? subjectId,
    String? sessionDate,
    SessionComponent? component,
    AttendanceStatus? status,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      sessionDate: sessionDate ?? this.sessionDate,
      component: component ?? this.component,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subjectId == other.subjectId &&
          sessionDate == other.sessionDate &&
          component == other.component &&
          status == other.status &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^
      subjectId.hashCode ^
      sessionDate.hashCode ^
      component.hashCode ^
      status.hashCode ^
      note.hashCode;
}
