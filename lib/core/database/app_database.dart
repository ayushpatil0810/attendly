import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/attendance_sessions_table.dart';
import 'tables/semesters_table.dart';
import 'tables/subjects_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Semesters, Subjects, AttendanceSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_attendance_sessions_date '
        'ON attendance_sessions(session_date);',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Enforce uniqueness on (subject_id, session_date, component) and index session_date
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_attendance_sessions_unique '
          'ON attendance_sessions(subject_id, session_date, component);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_attendance_sessions_date '
          'ON attendance_sessions(session_date);',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
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
