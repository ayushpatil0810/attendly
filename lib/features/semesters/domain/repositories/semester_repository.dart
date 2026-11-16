import '../entities/semester.dart';
import '../entities/semester_qr_payload.dart';

import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';

abstract interface class SemesterRepository {
  Stream<List<Semester>> watchAllSemesters();
  Stream<List<Semester>> watchActiveSemesters();
  Future<List<Semester>> getSemesters({bool includeArchived = false});
  Future<Semester?> getSemesterById(int id);
  Future<int> createSemester({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
    double attendanceThreshold = 0.75,
    double targetGoal = 0.85,
    AttendanceCalculationMethod calculationMethod =
        AttendanceCalculationMethod.rawCombined,
  });
  Future<void> updateSemester(Semester semester);
  Future<void> archiveSemester(int id, {required bool isArchived});
  Future<void> deleteSemester(int id);
  Future<SemesterQrPayload> exportSemesterPayload(int semesterId);
  Future<int> importSemesterPayload(
    SemesterQrPayload payload, {
    String? customName,
    bool replaceExisting = false,
  });
}
