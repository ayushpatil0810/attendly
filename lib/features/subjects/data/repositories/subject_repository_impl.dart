import 'package:drift/drift.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/domain/repositories/subject_repository.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  SubjectRepositoryImpl(this._db);

  final AppDatabase _db;

  Subject _toEntity(SubjectRow row) {
    return Subject(
      id: row.id,
      semesterId: row.semesterId,
      name: row.name,
      lectureEnabled: row.lectureEnabled,
      labEnabled: row.labEnabled,
      sortOrder: row.sortOrder,
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
  Stream<List<Subject>> watchSubjectsForSemester(int semesterId) {
    return (_db.select(_db.subjects)
          ..where((tbl) => tbl.semesterId.equals(semesterId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<Subject>> getSubjectsForSemester(int semesterId) async {
    final rows =
        await (_db.select(_db.subjects)
              ..where((tbl) => tbl.semesterId.equals(semesterId))
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.sortOrder,
                  mode: OrderingMode.asc,
                ),
                (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.asc,
                ),
              ]))
            .get();

    return rows.map(_toEntity).toList();
  }

  @override
  Future<Subject?> getSubjectById(int id) async {
    final row = await (_db.select(
      _db.subjects,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    return row != null ? _toEntity(row) : null;
  }

  @override
  Future<int> createSubject({
    required int semesterId,
    required String name,
    bool lectureEnabled = true,
    bool labEnabled = false,
    int sortOrder = 0,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationFailure('Subject name cannot be blank.');
    }
    if (!lectureEnabled && !labEnabled) {
      throw const ValidationFailure(
        'At least one component (Lecture or Lab) must be enabled.',
      );
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    try {
      final id = await _db
          .into(_db.subjects)
          .insert(
            SubjectsCompanion.insert(
              semesterId: semesterId,
              name: trimmedName,
              lectureEnabled: Value(lectureEnabled),
              labEnabled: Value(labEnabled),
              sortOrder: Value(sortOrder),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return id;
    } catch (e) {
      throw DatabaseFailure('Failed to create subject: $e');
    }
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    final trimmedName = subject.name.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationFailure('Subject name cannot be blank.');
    }
    if (!subject.lectureEnabled && !subject.labEnabled) {
      throw const ValidationFailure(
        'At least one component (Lecture or Lab) must be enabled.',
      );
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    try {
      await (_db.update(
        _db.subjects,
      )..where((tbl) => tbl.id.equals(subject.id))).write(
        SubjectsCompanion(
          name: Value(trimmedName),
          lectureEnabled: Value(subject.lectureEnabled),
          labEnabled: Value(subject.labEnabled),
          sortOrder: Value(subject.sortOrder),
          updatedAt: Value(now),
        ),
      );
    } catch (e) {
      throw DatabaseFailure('Failed to update subject: $e');
    }
  }

  @override
  Future<void> deleteSubject(int id) async {
    try {
      await (_db.delete(_db.subjects)..where((tbl) => tbl.id.equals(id))).go();
    } catch (e) {
      throw DatabaseFailure('Failed to delete subject: $e');
    }
  }
}
