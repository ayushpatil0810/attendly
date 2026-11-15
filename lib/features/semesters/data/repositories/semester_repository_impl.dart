import 'package:drift/drift.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/semesters/domain/repositories/semester_repository.dart';

class SemesterRepositoryImpl implements SemesterRepository {
  SemesterRepositoryImpl(this._db);

  final AppDatabase _db;

  Semester _toEntity(SemesterRow row) {
    return Semester(
      id: row.id,
      name: row.name,
      startDate: row.startDate != null
          ? DateTime.tryParse(row.startDate!)
          : null,
      endDate: row.endDate != null ? DateTime.tryParse(row.endDate!) : null,
      attendanceThreshold: row.attendanceThreshold,
      calculationMethod: AttendanceCalculationMethod.fromDbValue(
        row.calculationMethod,
      ),
      isArchived: row.isArchived,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
    );
  }

  @override
  Stream<List<Semester>> watchAllSemesters() {
    return (_db.select(_db.semesters)..orderBy([
          (tbl) =>
              OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
        ]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<Semester>> watchActiveSemesters() {
    return (_db.select(_db.semesters)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<Semester>> getSemesters({bool includeArchived = false}) async {
    final query = _db.select(_db.semesters);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
    ]);

    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<Semester?> getSemesterById(int id) async {
    final row = await (_db.select(
      _db.semesters,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    return row != null ? _toEntity(row) : null;
  }

  @override
  Future<int> createSemester({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
    double attendanceThreshold = 0.75,
    AttendanceCalculationMethod calculationMethod =
        AttendanceCalculationMethod.rawCombined,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationFailure('Semester name cannot be blank.');
    }
    if (attendanceThreshold <= 0.0 || attendanceThreshold > 1.0) {
      throw const ValidationFailure(
        'Attendance threshold must be between 1% and 100%.',
      );
    }
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw const ValidationFailure(
        'Semester start date cannot be after end date.',
      );
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final startDateStr = startDate != null
        ? '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'
        : null;
    final endDateStr = endDate != null
        ? '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}'
        : null;

    try {
      final id = await _db
          .into(_db.semesters)
          .insert(
            SemestersCompanion.insert(
              name: trimmedName,
              startDate: Value(startDateStr),
              endDate: Value(endDateStr),
              attendanceThreshold: Value(attendanceThreshold),
              calculationMethod: Value(calculationMethod.dbValue),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return id;
    } catch (e) {
      throw DatabaseFailure('Failed to create semester: $e');
    }
  }

  @override
  Future<void> updateSemester(Semester semester) async {
    final trimmedName = semester.name.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationFailure('Semester name cannot be blank.');
    }
    if (semester.attendanceThreshold <= 0.0 ||
        semester.attendanceThreshold > 1.0) {
      throw const ValidationFailure(
        'Attendance threshold must be between 1% and 100%.',
      );
    }
    if (semester.startDate != null &&
        semester.endDate != null &&
        semester.startDate!.isAfter(semester.endDate!)) {
      throw const ValidationFailure(
        'Semester start date cannot be after end date.',
      );
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final startDateStr = semester.startDate != null
        ? '${semester.startDate!.year.toString().padLeft(4, '0')}-${semester.startDate!.month.toString().padLeft(2, '0')}-${semester.startDate!.day.toString().padLeft(2, '0')}'
        : null;
    final endDateStr = semester.endDate != null
        ? '${semester.endDate!.year.toString().padLeft(4, '0')}-${semester.endDate!.month.toString().padLeft(2, '0')}-${semester.endDate!.day.toString().padLeft(2, '0')}'
        : null;

    try {
      await (_db.update(
        _db.semesters,
      )..where((tbl) => tbl.id.equals(semester.id))).write(
        SemestersCompanion(
          name: Value(trimmedName),
          startDate: Value(startDateStr),
          endDate: Value(endDateStr),
          attendanceThreshold: Value(semester.attendanceThreshold),
          calculationMethod: Value(semester.calculationMethod.dbValue),
          isArchived: Value(semester.isArchived),
          updatedAt: Value(now),
        ),
      );
    } catch (e) {
      throw DatabaseFailure('Failed to update semester: $e');
    }
  }

  @override
  Future<void> archiveSemester(int id, {required bool isArchived}) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    try {
      await (_db.update(
        _db.semesters,
      )..where((tbl) => tbl.id.equals(id))).write(
        SemestersCompanion(
          isArchived: Value(isArchived),
          updatedAt: Value(now),
        ),
      );
    } catch (e) {
      throw DatabaseFailure('Failed to update archive status: $e');
    }
  }

  @override
  Future<void> deleteSemester(int id) async {
    try {
      await (_db.delete(_db.semesters)..where((tbl) => tbl.id.equals(id))).go();
    } catch (e) {
      throw DatabaseFailure('Failed to delete semester: $e');
    }
  }
}
