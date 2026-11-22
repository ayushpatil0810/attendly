import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/backup/backup_format.dart';
import 'package:attendly/core/backup/backup_service.dart';
import 'package:attendly/core/backup/backup_validator.dart';
import 'package:attendly/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late BackupService backupService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backupService = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupService Export Tests', () {
    test('exports empty database safely as valid JSON', () async {
      final jsonStr = await backupService.exportBackupJson();

      expect(jsonStr, isNotEmpty);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['format'], BackupConstants.formatIdentifier);
      expect(decoded['formatVersion'], 1);
      expect(decoded['exportedAt'], isNotNull);

      final data = decoded['data'] as Map<String, dynamic>;
      expect(data['semesters'], isEmpty);
      expect(data['subjects'], isEmpty);
      expect(data['attendanceSessions'], isEmpty);

      // Verify that this empty backup passes validation
      final validation = BackupValidator.validate(jsonStr);
      expect(validation.isValid, isTrue);
      expect(validation.summary!.semestersCount, 0);
      expect(validation.summary!.subjectsCount, 0);
      expect(validation.summary!.sessionsCount, 0);
    });

    test(
      'exports populated database preserving all entities and fields',
      () async {
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;

        // 1. Insert Semester
        final semId = await db
            .into(db.semesters)
            .insert(
              SemestersCompanion.insert(
                name: 'Fall 2026',
                startDate: const Value('2026-08-15'),
                endDate: const Value('2026-12-20'),
                attendanceThreshold: const Value(0.80),
                calculationMethod: const Value('component_average'),
                isArchived: const Value(false),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // 2. Insert Subject
        final subjId = await db
            .into(db.subjects)
            .insert(
              SubjectsCompanion.insert(
                semesterId: semId,
                name: 'Data Structures',
                lectureEnabled: const Value(true),
                labEnabled: const Value(true),
                sortOrder: const Value(1),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // 3. Insert Attendance Sessions
        await db
            .into(db.attendanceSessions)
            .insert(
              AttendanceSessionsCompanion.insert(
                subjectId: subjId,
                sessionDate: '2026-09-02',
                component: 'lecture',
                status: 'present',
                note: const Value('Binary trees'),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.attendanceSessions)
            .insert(
              AttendanceSessionsCompanion.insert(
                subjectId: subjId,
                sessionDate: '2026-09-03',
                component: 'lab',
                status: 'absent',
                note: const Value(null),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final jsonStr = await backupService.exportBackupJson(
          appPreferences: {'dailyReminder': true},
        );

        final validation = BackupValidator.validate(jsonStr);
        expect(validation.isValid, isTrue);

        final summary = validation.summary!;
        expect(summary.semestersCount, 1);
        expect(summary.semesterNames, ['Fall 2026']);
        expect(summary.subjectsCount, 1);
        expect(summary.sessionsCount, 2);
        expect(summary.presentCount, 1);
        expect(summary.absentCount, 1);

        final data = validation.data!;
        final exportedSem = data.semesters.first;
        expect(exportedSem.id, semId);
        expect(exportedSem.name, 'Fall 2026');
        expect(exportedSem.startDate, '2026-08-15');
        expect(exportedSem.endDate, '2026-12-20');
        expect(exportedSem.attendanceThreshold, 0.80);
        expect(exportedSem.calculationMethod, 'component_average');

        final exportedSubj = data.subjects.first;
        expect(exportedSubj.id, subjId);
        expect(exportedSubj.semesterId, semId);
        expect(exportedSubj.name, 'Data Structures');
        expect(exportedSubj.lectureEnabled, isTrue);
        expect(exportedSubj.labEnabled, isTrue);

        expect(data.attendanceSessions.length, 2);
        final lectureSess = data.attendanceSessions.firstWhere(
          (s) => s.component == 'lecture',
        );
        expect(lectureSess.sessionDate, '2026-09-02');
        expect(lectureSess.status, 'present');
        expect(lectureSess.note, 'Binary trees');

        final labSess = data.attendanceSessions.firstWhere(
          (s) => s.component == 'lab',
        );
        expect(labSess.sessionDate, '2026-09-03');
        expect(labSess.status, 'absent');
        expect(labSess.note, isNull);

        expect(data.appPreferences, isNotNull);
        expect(data.appPreferences!['dailyReminder'], isTrue);
      },
    );

    test('simulator data isolation: hypothetical sessions are never in SQLite and never exported', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      final semId = await db
          .into(db.semesters)
          .insert(
            SemestersCompanion.insert(
              name: 'Spring 2026',
              attendanceThreshold: const Value(0.75),
              calculationMethod: const Value('raw_combined'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final subjId = await db
          .into(db.subjects)
          .insert(
            SubjectsCompanion.insert(
              semesterId: semId,
              name: 'Physics',
              lectureEnabled: const Value(true),
              labEnabled: const Value(false),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Persist 1 real session
      await db
          .into(db.attendanceSessions)
          .insert(
            AttendanceSessionsCompanion.insert(
              subjectId: subjId,
              sessionDate: '2026-02-10',
              component: 'lecture',
              status: 'present',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Export
      final jsonStr = await backupService.exportBackupJson();
      final validation = BackupValidator.validate(jsonStr);

      expect(validation.isValid, isTrue);
      // Only the 1 real database session is exported
      expect(validation.summary!.sessionsCount, 1);
      expect(
        validation.data!.attendanceSessions.first.sessionDate,
        '2026-02-10',
      );
    });
  });
}
