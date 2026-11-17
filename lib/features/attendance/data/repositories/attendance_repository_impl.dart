import 'package:drift/drift.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._db);

  final AppDatabase _db;

  AttendanceSession _toEntity(AttendanceSessionRow row) {
    return AttendanceSession(
      id: row.id,
      subjectId: row.subjectId,
      sessionDate: row.sessionDate,
      component: SessionComponent.fromDbValue(row.component),
      status: AttendanceStatus.fromDbValue(row.status),
      note: row.note,
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

  void _validateSessionDate(String sessionDate) {
    if (sessionDate.length != 10) {
      throw const ValidationFailure(
        'Session date must be in YYYY-MM-DD format.',
      );
    }
    final parts = sessionDate.split('-');
    if (parts.length != 3) {
      throw const ValidationFailure(
        'Session date must be in YYYY-MM-DD format.',
      );
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      throw const ValidationFailure('Invalid calendar date.');
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      throw const ValidationFailure('Invalid calendar date.');
    }
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw const ValidationFailure('Invalid calendar date.');
    }
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (sessionDate.compareTo(todayStr) > 0) {
      throw const ValidationFailure(
        'Attendance cannot be recorded for future dates.',
      );
    }
  }

  @override
  Stream<List<AttendanceSession>> watchSessionsForSemester(int semesterId) {
    final query = _db.select(_db.attendanceSessions).join([
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.attendanceSessions.subjectId),
      ),
    ]);
    query.where(_db.subjects.semesterId.equals(semesterId));
    query.orderBy([
      OrderingTerm(
        expression: _db.attendanceSessions.sessionDate,
        mode: OrderingMode.desc,
      ),
      OrderingTerm(
        expression: _db.attendanceSessions.id,
        mode: OrderingMode.desc,
      ),
    ]);

    return query.watch().map((rows) {
      return rows
          .map((r) => _toEntity(r.readTable(_db.attendanceSessions)))
          .toList();
    });
  }

  @override
  Stream<List<AttendanceSession>> watchSessionsForDate(
    int semesterId,
    String sessionDate,
  ) {
    final query = _db.select(_db.attendanceSessions).join([
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.attendanceSessions.subjectId),
      ),
    ]);
    query.where(
      _db.subjects.semesterId.equals(semesterId) &
          _db.attendanceSessions.sessionDate.equals(sessionDate),
    );
    query.orderBy([
      OrderingTerm(
        expression: _db.attendanceSessions.id,
        mode: OrderingMode.asc,
      ),
    ]);

    return query.watch().map((rows) {
      return rows
          .map((r) => _toEntity(r.readTable(_db.attendanceSessions)))
          .toList();
    });
  }

  @override
  Stream<List<AttendanceSession>> watchSessionsForMonth(
    int semesterId,
    int year,
    int month,
  ) {
    final startStr =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final nextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    final endStr =
        '${lastDay.year.toString().padLeft(4, '0')}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';

    final query = _db.select(_db.attendanceSessions).join([
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.attendanceSessions.subjectId),
      ),
    ]);
    query.where(
      _db.subjects.semesterId.equals(semesterId) &
          _db.attendanceSessions.sessionDate.isBiggerOrEqualValue(startStr) &
          _db.attendanceSessions.sessionDate.isSmallerOrEqualValue(endStr),
    );
    query.orderBy([
      OrderingTerm(
        expression: _db.attendanceSessions.sessionDate,
        mode: OrderingMode.asc,
      ),
      OrderingTerm(
        expression: _db.attendanceSessions.id,
        mode: OrderingMode.asc,
      ),
    ]);

    return query.watch().map((rows) {
      return rows
          .map((r) => _toEntity(r.readTable(_db.attendanceSessions)))
          .toList();
    });
  }

  @override
  Future<List<AttendanceSession>> getSessionsForDate(
    int semesterId,
    String sessionDate,
  ) async {
    final query = _db.select(_db.attendanceSessions).join([
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.attendanceSessions.subjectId),
      ),
    ]);
    query.where(
      _db.subjects.semesterId.equals(semesterId) &
          _db.attendanceSessions.sessionDate.equals(sessionDate),
    );
    query.orderBy([
      OrderingTerm(
        expression: _db.attendanceSessions.id,
        mode: OrderingMode.asc,
      ),
    ]);

    final rows = await query.get();
    return rows
        .map((r) => _toEntity(r.readTable(_db.attendanceSessions)))
        .toList();
  }

  @override
  Future<List<AttendanceSession>> getSessionsForSubject(int subjectId) async {
    final rows =
        await (_db.select(_db.attendanceSessions)
              ..where((tbl) => tbl.subjectId.equals(subjectId))
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.sessionDate,
                  mode: OrderingMode.desc,
                ),
                (tbl) =>
                    OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
              ]))
            .get();

    return rows.map(_toEntity).toList();
  }

  @override
  Future<AttendanceSession?> getSessionBySubjectDateComponent(
    int subjectId,
    String sessionDate,
    SessionComponent component,
  ) async {
    final row =
        await (_db.select(_db.attendanceSessions)
              ..where(
                (tbl) =>
                    tbl.subjectId.equals(subjectId) &
                    tbl.sessionDate.equals(sessionDate) &
                    tbl.component.equals(component.dbValue),
              )
              ..orderBy([
                (tbl) =>
                    OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();

    return row != null ? _toEntity(row) : null;
  }

  @override
  Future<AttendanceSession?> getSessionById(int id) async {
    final row = await (_db.select(
      _db.attendanceSessions,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    return row != null ? _toEntity(row) : null;
  }

  @override
  Future<int> createSession({
    required int subjectId,
    required String sessionDate,
    required SessionComponent component,
    required AttendanceStatus status,
    String? note,
  }) async {
    _validateSessionDate(sessionDate);

    // Verify subject exists and has component enabled
    final subjectRow = await (_db.select(
      _db.subjects,
    )..where((tbl) => tbl.id.equals(subjectId))).getSingleOrNull();

    if (subjectRow == null) {
      throw const NotFoundFailure('Subject not found.');
    }

    if (component == SessionComponent.lecture && !subjectRow.lectureEnabled) {
      throw const ValidationFailure('Lecture is not enabled for this subject.');
    }
    if (component == SessionComponent.lab && !subjectRow.labEnabled) {
      throw const ValidationFailure('Lab is not enabled for this subject.');
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    try {
      final id = await _db
          .into(_db.attendanceSessions)
          .insert(
            AttendanceSessionsCompanion.insert(
              subjectId: subjectId,
              sessionDate: sessionDate,
              component: component.dbValue,
              status: status.dbValue,
              note: Value(note?.trim()),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return id;
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw DatabaseFailure('Failed to record attendance session: $e');
    }
  }

  @override
  Future<void> updateSession(AttendanceSession session) async {
    _validateSessionDate(session.sessionDate);

    final existing = await getSessionById(session.id);
    if (existing == null) {
      throw const NotFoundFailure('Session not found.');
    }

    final subjectRow = await (_db.select(
      _db.subjects,
    )..where((tbl) => tbl.id.equals(session.subjectId))).getSingleOrNull();

    if (subjectRow == null) {
      throw const NotFoundFailure('Subject not found.');
    }

    if (session.component == SessionComponent.lecture &&
        !subjectRow.lectureEnabled) {
      throw const ValidationFailure('Lecture is not enabled for this subject.');
    }
    if (session.component == SessionComponent.lab && !subjectRow.labEnabled) {
      throw const ValidationFailure('Lab is not enabled for this subject.');
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    try {
      await (_db.update(
        _db.attendanceSessions,
      )..where((tbl) => tbl.id.equals(session.id))).write(
        AttendanceSessionsCompanion(
          subjectId: Value(session.subjectId),
          sessionDate: Value(session.sessionDate),
          component: Value(session.component.dbValue),
          status: Value(session.status.dbValue),
          note: Value(session.note?.trim()),
          updatedAt: Value(now),
        ),
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw DatabaseFailure('Failed to update attendance session: $e');
    }
  }

  @override
  Future<void> deleteSession(int id) async {
    try {
      await (_db.delete(
        _db.attendanceSessions,
      )..where((tbl) => tbl.id.equals(id))).go();
    } catch (e) {
      throw DatabaseFailure('Failed to delete attendance session: $e');
    }
  }
}
