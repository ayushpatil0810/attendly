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
    test('database opens and schemaVersion is 1', () {
      expect(db.schemaVersion, equals(1));
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
}
