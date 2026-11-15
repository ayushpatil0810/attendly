import '../entities/attendance_session.dart';
import '../entities/attendance_status.dart';
import '../entities/session_component.dart';

abstract interface class AttendanceRepository {
  Stream<List<AttendanceSession>> watchSessionsForSemester(int semesterId);

  Stream<List<AttendanceSession>> watchSessionsForDate(
    int semesterId,
    String sessionDate,
  );

  Stream<List<AttendanceSession>> watchSessionsForMonth(
    int semesterId,
    int year,
    int month,
  );

  Future<List<AttendanceSession>> getSessionsForDate(
    int semesterId,
    String sessionDate,
  );

  Future<List<AttendanceSession>> getSessionsForSubject(int subjectId);

  Future<AttendanceSession?> getSessionBySubjectDateComponent(
    int subjectId,
    String sessionDate,
    SessionComponent component,
  );

  Future<AttendanceSession?> getSessionById(int id);

  Future<int> createSession({
    required int subjectId,
    required String sessionDate,
    required SessionComponent component,
    required AttendanceStatus status,
    String? note,
  });

  Future<void> updateSession(AttendanceSession session);

  Future<void> deleteSession(int id);
}
