import 'package:drift/drift.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/errors/app_failure.dart';
import '../../domain/entities/day_note.dart';
import '../../domain/repositories/day_note_repository.dart';

class DayNoteRepositoryImpl implements DayNoteRepository {
  DayNoteRepositoryImpl(this._db);

  final AppDatabase _db;

  DayNote _toEntity(DayNoteRow row) {
    return DayNote(
      id: row.id,
      semesterId: row.semesterId,
      date: row.date,
      content: row.content,
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
  Stream<DayNote?> watchNoteForDate(int semesterId, String date) {
    return (_db.select(_db.dayNotes)
          ..where(
            (tbl) => tbl.semesterId.equals(semesterId) & tbl.date.equals(date),
          ))
        .watchSingleOrNull()
        .map((row) => row != null ? _toEntity(row) : null);
  }

  @override
  Future<DayNote?> getNoteForDate(int semesterId, String date) async {
    final row = await (_db.select(_db.dayNotes)
          ..where(
            (tbl) => tbl.semesterId.equals(semesterId) & tbl.date.equals(date),
          ))
        .getSingleOrNull();
    return row != null ? _toEntity(row) : null;
  }

  @override
  Stream<List<DayNote>> watchNotesForMonth(
    int semesterId,
    String yearMonthPrefix,
  ) {
    return (_db.select(_db.dayNotes)
          ..where(
            (tbl) =>
                tbl.semesterId.equals(semesterId) &
                tbl.date.like('$yearMonthPrefix%'),
          ))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<DayNote>> getNotesForMonth(
    int semesterId,
    String yearMonthPrefix,
  ) async {
    final rows = await (_db.select(_db.dayNotes)
          ..where(
            (tbl) =>
                tbl.semesterId.equals(semesterId) &
                tbl.date.like('$yearMonthPrefix%'),
          ))
        .get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> setNoteForDate({
    required int semesterId,
    required String date,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      // Empty content removes the note
      await deleteNoteForDate(semesterId: semesterId, date: date);
      return;
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    try {
      final existing = await getNoteForDate(semesterId, date);
      if (existing != null) {
        await (_db.update(_db.dayNotes)
              ..where(
                (tbl) =>
                    tbl.semesterId.equals(semesterId) & tbl.date.equals(date),
              ))
            .write(
          DayNotesCompanion(
            content: Value(trimmed),
            updatedAt: Value(now),
          ),
        );
      } else {
        await _db.into(_db.dayNotes).insert(
              DayNotesCompanion.insert(
                semesterId: semesterId,
                date: date,
                content: trimmed,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    } catch (e) {
      throw DatabaseFailure('Failed to save day note: $e');
    }
  }

  @override
  Future<void> deleteNoteForDate({
    required int semesterId,
    required String date,
  }) async {
    try {
      await (_db.delete(_db.dayNotes)
            ..where(
              (tbl) =>
                  tbl.semesterId.equals(semesterId) & tbl.date.equals(date),
            ))
          .go();
    } catch (e) {
      throw DatabaseFailure('Failed to delete day note: $e');
    }
  }
}
