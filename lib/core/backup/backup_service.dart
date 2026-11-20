import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/errors/app_failure.dart';

import 'backup_format.dart';
import 'backup_validator.dart';

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  /// Exports all semesters, subjects, and attendance sessions to a versioned JSON string.
  Future<String> exportBackupJson({
    Map<String, dynamic>? appPreferences,
  }) async {
    try {
      final semesterRows =
          await (_db.select(_db.semesters)..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
              .get();

      final subjectRows =
          await (_db.select(_db.subjects)..orderBy([
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

      final sessionRows =
          await (_db.select(_db.attendanceSessions)..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.sessionDate,
                  mode: OrderingMode.asc,
                ),
                (tbl) =>
                    OrderingTerm(expression: tbl.id, mode: OrderingMode.asc),
              ]))
              .get();

      final dayNoteRows =
          await (_db.select(_db.dayNotes)..orderBy([
                (tbl) =>
                    OrderingTerm(expression: tbl.date, mode: OrderingMode.asc),
                (tbl) =>
                    OrderingTerm(expression: tbl.id, mode: OrderingMode.asc),
              ]))
              .get();

      final backupData = BackupData(
        format: BackupConstants.formatIdentifier,
        formatVersion: BackupConstants.currentFormatVersion,
        exportedAt: DateTime.now().toUtc().toIso8601String(),
        semesters: semesterRows
            .map(
              (r) => SemesterBackupModel(
                id: r.id,
                name: r.name,
                startDate: r.startDate,
                endDate: r.endDate,
                attendanceThreshold: r.attendanceThreshold,
                targetGoal: r.targetGoal,
                calculationMethod: r.calculationMethod,
                isArchived: r.isArchived,
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              ),
            )
            .toList(),
        subjects: subjectRows
            .map(
              (r) => SubjectBackupModel(
                id: r.id,
                semesterId: r.semesterId,
                name: r.name,
                lectureEnabled: r.lectureEnabled,
                labEnabled: r.labEnabled,
                sortOrder: r.sortOrder,
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              ),
            )
            .toList(),
        attendanceSessions: sessionRows
            .map(
              (r) => AttendanceSessionBackupModel(
                id: r.id,
                subjectId: r.subjectId,
                sessionDate: r.sessionDate,
                component: r.component,
                status: r.status,
                note: r.note,
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              ),
            )
            .toList(),
        dayNotes: dayNoteRows
            .map(
              (r) => DayNoteBackupModel(
                id: r.id,
                semesterId: r.semesterId,
                date: r.date,
                content: r.content,
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              ),
            )
            .toList(),
        appPreferences: appPreferences,
      );

      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(backupData.toJson());
    } catch (e) {
      throw DatabaseFailure('Failed to generate backup export: $e');
    }
  }

  /// Parses and validates a JSON string without modifying the database.
  BackupValidationResult validateBackup(String jsonContent) {
    return BackupValidator.validate(jsonContent);
  }

  /// Restores the database from [BackupData] inside an atomic transaction.
  /// If any error occurs, the entire transaction rolls back and the existing database is preserved.
  /// Returns the ID of the new active semester (or null if no active semesters).
  Future<int?> restoreBackup(BackupData backupData) async {
    return await _db.transaction<int?>(() async {
      // 1. Delete all existing records (cascading from semesters, but explicit on each table)
      await _db.delete(_db.attendanceSessions).go();
      await _db.delete(_db.dayNotes).go();
      await _db.delete(_db.subjects).go();
      await _db.delete(_db.semesters).go();

      // 2. Insert semesters and remap old IDs to new auto-increment IDs
      final oldToNewSemesterId = <int, int>{};
      int? firstActiveSemesterId;

      for (final semester in backupData.semesters) {
        final newId = await _db
            .into(_db.semesters)
            .insert(
              SemestersCompanion.insert(
                name: semester.name,
                startDate: Value(semester.startDate),
                endDate: Value(semester.endDate),
                attendanceThreshold: Value(semester.attendanceThreshold),
                targetGoal: Value(semester.targetGoal),
                calculationMethod: Value(semester.calculationMethod),
                isArchived: Value(semester.isArchived),
                createdAt: semester.createdAt,
                updatedAt: semester.updatedAt,
              ),
            );
        oldToNewSemesterId[semester.id] = newId;

        if (!semester.isArchived && firstActiveSemesterId == null) {
          firstActiveSemesterId = newId;
        }
      }

      // 3. Insert subjects and remap old IDs to new auto-increment IDs
      final oldToNewSubjectId = <int, int>{};
      for (final subject in backupData.subjects) {
        final newSemesterId = oldToNewSemesterId[subject.semesterId];
        if (newSemesterId == null) {
          throw ValidationFailure(
            'Subject "${subject.name}" references missing semester ${subject.semesterId}.',
          );
        }

        final newId = await _db
            .into(_db.subjects)
            .insert(
              SubjectsCompanion.insert(
                semesterId: newSemesterId,
                name: subject.name,
                lectureEnabled: Value(subject.lectureEnabled),
                labEnabled: Value(subject.labEnabled),
                sortOrder: Value(subject.sortOrder),
                createdAt: subject.createdAt,
                updatedAt: subject.updatedAt,
              ),
            );
        oldToNewSubjectId[subject.id] = newId;
      }

      // 4. Insert attendance sessions with remapped subject IDs in batch
      if (backupData.attendanceSessions.isNotEmpty) {
        final sessionCompanions = <AttendanceSessionsCompanion>[];
        for (final session in backupData.attendanceSessions) {
          final newSubjectId = oldToNewSubjectId[session.subjectId];
          if (newSubjectId == null) {
            throw ValidationFailure(
              'Session on ${session.sessionDate} references missing subject ${session.subjectId}.',
            );
          }

          sessionCompanions.add(
            AttendanceSessionsCompanion.insert(
              subjectId: newSubjectId,
              sessionDate: session.sessionDate,
              component: session.component,
              status: session.status,
              note: Value(session.note),
              createdAt: session.createdAt,
              updatedAt: session.updatedAt,
            ),
          );
        }
        await _db.batch((batch) {
          batch.insertAll(_db.attendanceSessions, sessionCompanions);
        });
      }

      // 5. Insert day notes with remapped semester IDs in batch
      if (backupData.dayNotes.isNotEmpty) {
        final dayNoteCompanions = <DayNotesCompanion>[];
        for (final note in backupData.dayNotes) {
          final newSemesterId = oldToNewSemesterId[note.semesterId];
          if (newSemesterId == null) {
            throw ValidationFailure(
              'Day note on ${note.date} references missing semester ${note.semesterId}.',
            );
          }

          dayNoteCompanions.add(
            DayNotesCompanion.insert(
              semesterId: newSemesterId,
              date: note.date,
              content: note.content,
              createdAt: note.createdAt,
              updatedAt: note.updatedAt,
            ),
          );
        }
        await _db.batch((batch) {
          batch.insertAll(_db.dayNotes, dayNoteCompanions);
        });
      }

      return firstActiveSemesterId;
    });
  }
}
