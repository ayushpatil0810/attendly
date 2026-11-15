import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/database/app_database.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Database initialization & schema', () {
    test('database opens and schemaVersion is 3', () {
      expect(db.schemaVersion, equals(3));
    });

    test('can insert and retrieve a semester', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final semesterId = await db
          .into(db.semesters)
          .insert(
            SemestersCompanion.insert(
              name: 'Fall 2026',
              attendanceThreshold: const Value(0.75),
              calculationMethod: const Value('raw_combined'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(semesterId, greaterThan(0));

      final fetched = await (db.select(
        db.semesters,
      )..where((tbl) => tbl.id.equals(semesterId))).getSingle();

      expect(fetched.name, equals('Fall 2026'));
      expect(fetched.attendanceThreshold, equals(0.75));
      expect(fetched.calculationMethod, equals('raw_combined'));
      expect(fetched.isArchived, isFalse);
    });

    test('rejects semester with blank name', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(
        () async => await db
            .into(db.semesters)
            .insert(
              SemestersCompanion.insert(
                name: '   ',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('rejects semester with invalid threshold', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Threshold <= 0
      expect(
        () async => await db
            .into(db.semesters)
            .insert(
              SemestersCompanion.insert(
                name: 'Test Sem',
                attendanceThreshold: const Value(0.0),
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      // Threshold > 1.0
      expect(
        () async => await db
            .into(db.semesters)
            .insert(
              SemestersCompanion.insert(
                name: 'Test Sem',
                attendanceThreshold: const Value(1.05),
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('rejects semester with unsupported calculation method', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(
        () async => await db
            .into(db.semesters)
            .insert(
              SemestersCompanion.insert(
                name: 'Test Sem',
                calculationMethod: const Value('magic_formula'),
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('Subjects table & constraints', () {
    late int semesterId;

    setUp(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      semesterId = await db
          .into(db.semesters)
          .insert(
            SemestersCompanion.insert(
              name: 'Fall 2026',
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    test('can insert and retrieve subject', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final subjectId = await db
          .into(db.subjects)
          .insert(
            SubjectsCompanion.insert(
              semesterId: semesterId,
              name: 'Computer Networks',
              lectureEnabled: const Value(true),
              labEnabled: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(subjectId, greaterThan(0));

      final fetched = await (db.select(
        db.subjects,
      )..where((tbl) => tbl.id.equals(subjectId))).getSingle();

      expect(fetched.name, equals('Computer Networks'));
      expect(fetched.lectureEnabled, isTrue);
      expect(fetched.labEnabled, isTrue);
    });

    test('rejects subject with blank name', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(
        () async => await db
            .into(db.subjects)
            .insert(
              SubjectsCompanion.insert(
                semesterId: semesterId,
                name: '',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('rejects subject with both lecture and lab disabled', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(
        () async => await db
            .into(db.subjects)
            .insert(
              SubjectsCompanion.insert(
                semesterId: semesterId,
                name: 'Ghost Subject',
                lectureEnabled: const Value(false),
                labEnabled: const Value(false),
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test(
      'foreign key constraint prevents subject with invalid semesterId',
      () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        expect(
          () async => await db
              .into(db.subjects)
              .insert(
                SubjectsCompanion.insert(
                  semesterId: 99999,
                  name: 'Orphan Subject',
                  createdAt: now,
                  updatedAt: now,
                ),
              ),
          throwsA(isA<SqliteException>()),
        );
      },
    );
  });

  group('Cascade deletion & AttendanceSessions constraints', () {
    test('cascades delete from semester to subjects and sessions', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final semId = await db
          .into(db.semesters)
          .insert(
            SemestersCompanion.insert(
              name: 'Spring 2026',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final subjId = await db
          .into(db.subjects)
          .insert(
            SubjectsCompanion.insert(
              semesterId: semId,
              name: 'Data Structures',
              lectureEnabled: const Value(true),
              labEnabled: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final sessId = await db
          .into(db.attendanceSessions)
          .insert(
            AttendanceSessionsCompanion.insert(
              subjectId: subjId,
              sessionDate: '2026-03-10',
              component: 'lecture',
              status: 'present',
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(sessId, greaterThan(0));

      // Verify records exist
      expect(await db.select(db.subjects).get(), isNotEmpty);
      expect(await db.select(db.attendanceSessions).get(), isNotEmpty);

      // Delete the semester
      await (db.delete(
        db.semesters,
      )..where((tbl) => tbl.id.equals(semId))).go();

      // Subjects and sessions must be cascade deleted
      final remainingSubjects = await db.select(db.subjects).get();
      final remainingSessions = await db.select(db.attendanceSessions).get();

      expect(remainingSubjects, isEmpty);
      expect(remainingSessions, isEmpty);
    });

    test(
      'rejects invalid component or status in attendance_sessions',
      () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        final semId = await db
            .into(db.semesters)
            .insert(
              SemestersCompanion.insert(
                name: 'Spring 2026',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final subjId = await db
            .into(db.subjects)
            .insert(
              SubjectsCompanion.insert(
                semesterId: semId,
                name: 'Algorithms',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Invalid component
        expect(
          () async => await db
              .into(db.attendanceSessions)
              .insert(
                AttendanceSessionsCompanion.insert(
                  subjectId: subjId,
                  sessionDate: '2026-03-10',
                  component: 'workshop',
                  status: 'present',
                  createdAt: now,
                  updatedAt: now,
                ),
              ),
          throwsA(isA<SqliteException>()),
        );

        // Invalid status
        expect(
          () async => await db
              .into(db.attendanceSessions)
              .insert(
                AttendanceSessionsCompanion.insert(
                  subjectId: subjId,
                  sessionDate: '2026-03-10',
                  component: 'lecture',
                  status: 'excused',
                  createdAt: now,
                  updatedAt: now,
                ),
              ),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test(
      'allows another session for the same subject, date, and component',
      () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        final semId = await db
            .into(db.semesters)
            .insert(
              SemestersCompanion.insert(
                name: 'Spring 2026',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final subjId = await db
            .into(db.subjects)
            .insert(
              SubjectsCompanion.insert(
                semesterId: semId,
                name: 'Operating Systems',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Insert first session
        await db
            .into(db.attendanceSessions)
            .insert(
              AttendanceSessionsCompanion.insert(
                subjectId: subjId,
                sessionDate: '2026-03-10',
                component: 'lecture',
                status: 'present',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final secondId = await db
            .into(db.attendanceSessions)
            .insert(
              AttendanceSessionsCompanion.insert(
                subjectId: subjId,
                sessionDate: '2026-03-10',
                component: 'lecture',
                status: 'absent',
                createdAt: now,
                updatedAt: now,
              ),
            );
        expect(secondId, greaterThan(0));
      },
    );

    test('data persists across database reopening', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'attendly_db_test_',
      );
      final dbFile = File('${tempDir.path}/test_reopen.sqlite');

      final db1 = AppDatabase.forTesting(NativeDatabase(dbFile));
      final now = DateTime.now().millisecondsSinceEpoch;
      await db1
          .into(db1.semesters)
          .insert(
            SemestersCompanion.insert(
              name: 'Persisted Semester',
              attendanceThreshold: const Value(0.80),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db1.close();

      // Reopen with new AppDatabase instance pointing to same file
      final db2 = AppDatabase.forTesting(NativeDatabase(dbFile));
      final semesters = await db2.select(db2.semesters).get();
      expect(semesters.length, equals(1));
      expect(semesters.first.name, equals('Persisted Semester'));
      expect(semesters.first.attendanceThreshold, equals(0.80));
      await db2.close();

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('Database migrations (v1 -> v3)', () {
    test('migrates database from v1 to v3 and keeps same-day sessions', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'attendly_migration_test_',
      );
      final dbFile = File('${tempDir.path}/migration_test.sqlite');

      // 1. Manually create v1 database using raw sqlite statements
      final rawDb = NativeDatabase(dbFile);
      final executor = rawDb;
      await executor.ensureOpen(_FakeQueryExecutorUser());

      await executor.runCustom('PRAGMA user_version = 1;');
      await executor.runCustom('''
        CREATE TABLE semesters (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          start_date TEXT,
          end_date TEXT,
          attendance_threshold REAL NOT NULL DEFAULT 0.75,
          calculation_method TEXT NOT NULL DEFAULT 'raw_combined',
          is_archived INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          CHECK (length(trim(name)) > 0),
          CHECK (attendance_threshold > 0.0 AND attendance_threshold <= 1.0),
          CHECK (calculation_method IN ('raw_combined', 'component_average')),
          CHECK (is_archived IN (0, 1))
        );
      ''');
      await executor.runCustom('''
        CREATE TABLE subjects (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          semester_id INTEGER NOT NULL REFERENCES semesters (id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          lecture_enabled INTEGER NOT NULL DEFAULT 1,
          lab_enabled INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          CHECK (length(trim(name)) > 0),
          CHECK (lecture_enabled IN (0, 1)),
          CHECK (lab_enabled IN (0, 1)),
          CHECK (lecture_enabled = 1 OR lab_enabled = 1)
        );
      ''');
      await executor.runCustom('''
        CREATE TABLE attendance_sessions (
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

      final now = DateTime.now().millisecondsSinceEpoch;
      await executor.runCustom(
        "INSERT INTO semesters (name, created_at, updated_at) VALUES ('V1 Semester', $now, $now);",
      );
      await executor.runCustom(
        "INSERT INTO subjects (semester_id, name, created_at, updated_at) VALUES (1, 'V1 Subject', $now, $now);",
      );
      await executor.runCustom(
        "INSERT INTO attendance_sessions (subject_id, session_date, component, status, created_at, updated_at) "
        "VALUES (1, '2026-03-01', 'lecture', 'present', $now, $now);",
      );

      await executor.close();

      // 2. Open with AppDatabase v2, triggering onUpgrade from v1 to v2
      final upgradedDb = AppDatabase.forTesting(NativeDatabase(dbFile));
      expect(upgradedDb.schemaVersion, equals(3));

      // 3. Verify existing data preserved
      final semesters = await upgradedDb.select(upgradedDb.semesters).get();
      expect(semesters.length, equals(1));
      expect(semesters.first.name, equals('V1 Semester'));

      final subjects = await upgradedDb.select(upgradedDb.subjects).get();
      expect(subjects.length, equals(1));
      expect(subjects.first.name, equals('V1 Subject'));

      final sessions = await upgradedDb
          .select(upgradedDb.attendanceSessions)
          .get();
      expect(sessions.length, equals(1));
      expect(sessions.first.sessionDate, equals('2026-03-01'));
      expect(sessions.first.status, equals('present'));

      final sameDayId = await upgradedDb
          .into(upgradedDb.attendanceSessions)
          .insert(
            AttendanceSessionsCompanion.insert(
              subjectId: 1,
              sessionDate: '2026-03-01',
              component: 'lecture',
              status: 'absent',
              createdAt: now,
              updatedAt: now,
            ),
          );
      expect(sameDayId, greaterThan(0));

      // 5. Valid session on different component or date succeeds
      final newSessId = await upgradedDb
          .into(upgradedDb.attendanceSessions)
          .insert(
            AttendanceSessionsCompanion.insert(
              subjectId: 1,
              sessionDate: '2026-03-02',
              component: 'lecture',
              status: 'present',
              createdAt: now,
              updatedAt: now,
            ),
          );
      expect(newSessId, greaterThan(0));

      await upgradedDb.close();

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
  });
}

class _FakeQueryExecutorUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
