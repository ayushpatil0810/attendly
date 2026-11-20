import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/attendance_sessions_table.dart';
import 'tables/day_notes_table.dart';
import 'tables/semesters_table.dart';
import 'tables/subjects_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Semesters, Subjects, AttendanceSessions, DayNotes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_attendance_sessions_date '
        'ON attendance_sessions(session_date);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_attendance_sessions_subject_date '
        'ON attendance_sessions(subject_id, session_date);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_subjects_semester_sort '
        'ON subjects(semester_id, sort_order);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_day_notes_date '
        'ON day_notes(date);',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_attendance_sessions_date '
          'ON attendance_sessions(session_date);',
        );
      }
      if (from < 3) {
        // A subject can have more than one lecture, or more than one lab,
        // on the same day. Drop the unique index and any table-level UNIQUE
        // by rebuilding the table. Existing rows are copied first.
        await customStatement('PRAGMA foreign_keys = OFF;');
        await customStatement(
          'DROP INDEX IF EXISTS idx_attendance_sessions_unique;',
        );
        await customStatement('''
          CREATE TABLE attendance_sessions_v3 (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            subject_id INTEGER NOT NULL REFERENCES subjects (id) ON DELETE CASCADE,
            session_date TEXT NOT NULL,
            component TEXT NOT NULL,
            status TEXT NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            CHECK (component IN ('lecture', 'lab')),
            CHECK (status IN ('present', 'absent')),
            CHECK (length(session_date) = 10)
          );
        ''');
        await customStatement('''
          INSERT INTO attendance_sessions_v3 (
            id, subject_id, session_date, component, status, note, created_at, updated_at
          )
          SELECT id, subject_id, session_date, component, status, note, created_at, updated_at
          FROM attendance_sessions;
        ''');
        await customStatement('DROP TABLE attendance_sessions;');
        await customStatement(
          'ALTER TABLE attendance_sessions_v3 RENAME TO attendance_sessions;',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_attendance_sessions_date '
          'ON attendance_sessions(session_date);',
        );
        await customStatement('PRAGMA foreign_keys = ON;');
      }
      if (from < 4) {
        await m.createTable(dayNotes);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_day_notes_date '
          'ON day_notes(date);',
        );
      }
      if (from < 5) {
        await m.addColumn(semesters, semesters.targetGoal);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_attendance_sessions_subject_date '
        'ON attendance_sessions(subject_id, session_date);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_subjects_semester_sort '
        'ON subjects(semester_id, sort_order);',
      );
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'attendly.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
