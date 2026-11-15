import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/backup/backup_format.dart';
import 'package:attendly/core/backup/backup_service.dart';
import 'package:attendly/core/backup/backup_validator.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/services/attendance_calculator.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

void main() {
  late AppDatabase db;
  late BackupService backupService;
  late SemesterRepositoryImpl semesterRepo;
  late SubjectRepositoryImpl subjectRepo;
  late AttendanceRepositoryImpl attendanceRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backupService = BackupService(db);
    semesterRepo = SemesterRepositoryImpl(db);
    subjectRepo = SubjectRepositoryImpl(db);
    attendanceRepo = AttendanceRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupService Restore Tests', () {
    test('restores into fresh database correctly and calculates attendance with parity', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      final backupData = BackupData(
        format: BackupConstants.formatIdentifier,
        formatVersion: 1,
        exportedAt: '2026-11-15T12:00:00.000Z',
        semesters: [
          SemesterBackupModel(
            id: 10,
            name: 'Semester 4',
            startDate: '2026-01-10',
            endDate: '2026-05-30',
            attendanceThreshold: 0.75,
            calculationMethod: 'raw_combined',
            isArchived: false,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        subjects: [
          SubjectBackupModel(
            id: 201,
            semesterId: 10,
            name: 'Operating Systems',
            lectureEnabled: true,
            labEnabled: true,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        attendanceSessions: [
          AttendanceSessionBackupModel(
            id: 3001,
            subjectId: 201,
            sessionDate: '2026-02-01',
            component: 'lecture',
            status: 'present',
            createdAt: now,
            updatedAt: now,
          ),
          AttendanceSessionBackupModel(
            id: 3002,
            subjectId: 201,
            sessionDate: '2026-02-02',
            component: 'lab',
            status: 'absent',
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final activeSemId = await backupService.restoreBackup(backupData);
      expect(activeSemId, isNotNull);

      // Verify Semesters
      final semesters = await semesterRepo.getSemesters();
      expect(semesters.length, 1);
      final restoredSem = semesters.first;
      expect(restoredSem.name, 'Semester 4');
      expect(restoredSem.attendanceThreshold, 0.75);
      expect(
        restoredSem.calculationMethod,
        AttendanceCalculationMethod.rawCombined,
      );

      // Verify Subjects
      final subjects = await subjectRepo.getSubjectsForSemester(restoredSem.id);
      expect(subjects.length, 1);
      final restoredSubj = subjects.first;
      expect(restoredSubj.name, 'Operating Systems');
      expect(restoredSubj.lectureEnabled, isTrue);
      expect(restoredSubj.labEnabled, isTrue);

      // Verify Sessions
      final sessions = await attendanceRepo
          .watchSessionsForSemester(restoredSem.id)
          .first;
      expect(sessions.length, 2);

      // Verify domain calculation parity (1 present, 1 absent -> 50% under raw combined)
      const calculator = AttendanceCalculator();
      final summary = calculator.calculateSemester(
        semester: restoredSem,
        subjects: subjects,
        sessions: sessions,
      );

      expect(summary.totalConducted, 2);
      expect(summary.totalPresent, 1);
      expect(summary.totalAbsent, 1);
      expect(summary.overallPercentage, 50.0);
      expect(summary.isBelowThreshold, isTrue);
    });

    test(
      'replaces existing local data completely according to replace policy',
      () async {
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;

        // 1. Insert existing initial data
        final initialSemId = await semesterRepo.createSemester(
          name: 'Old Semester To Be Replaced',
          attendanceThreshold: 0.85,
        );
        final initialSubjId = await subjectRepo.createSubject(
          semesterId: initialSemId,
          name: 'Old Subject',
        );
        await attendanceRepo.createSession(
          subjectId: initialSubjId,
          sessionDate: '2026-01-01',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        // Verify pre-existing data
        expect((await semesterRepo.getSemesters()).length, 1);
        expect(
          (await attendanceRepo.watchSessionsForSemester(initialSemId).first)
              .length,
          1,
        );

        // 2. Prepare new backup data to restore
        final backupData = BackupData(
          format: BackupConstants.formatIdentifier,
          formatVersion: 1,
          exportedAt: '2026-11-15T12:00:00.000Z',
          semesters: [
            SemesterBackupModel(
              id: 1,
              name: 'Fresh Restored Semester',
              attendanceThreshold: 0.75,
              calculationMethod: 'raw_combined',
              isArchived: false,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          subjects: [
            SubjectBackupModel(
              id: 10,
              semesterId: 1,
              name: 'New Algorithms',
              lectureEnabled: true,
              labEnabled: false,
              sortOrder: 0,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          attendanceSessions: [],
        );

        // 3. Execute restore
        final newSemId = await backupService.restoreBackup(backupData);
        expect(newSemId, isNotNull);

        // 4. Verify old data was completely replaced
        final allSemesters = await semesterRepo.getSemesters();
        expect(allSemesters.length, 1);
        expect(allSemesters.first.name, 'Fresh Restored Semester');
        expect(allSemesters.first.id, isNot(equals(initialSemId)));

        final allSubjects = await subjectRepo.getSubjectsForSemester(
          allSemesters.first.id,
        );
        expect(allSubjects.length, 1);
        expect(allSubjects.first.name, 'New Algorithms');

        final allSessions = await attendanceRepo
            .watchSessionsForSemester(allSemesters.first.id)
            .first;
        expect(allSessions, isEmpty);
      },
    );

    test('failure during restore triggers transaction rollback and preserves pre-existing database', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      // 1. Populate existing database
      final initialSemId = await semesterRepo.createSemester(
        name: 'Precious Existing Semester',
        attendanceThreshold: 0.75,
      );
      final initialSubjId = await subjectRepo.createSubject(
        semesterId: initialSemId,
        name: 'Database Management',
        lectureEnabled: true,
        labEnabled: true,
      );
      await attendanceRepo.createSession(
        subjectId: initialSubjId,
        sessionDate: '2026-03-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      // 2. Craft corrupted backup data that passes validator initial check but causes database exception
      // (e.g. Session referencing invalid subjectId that wasn't in the subjects list)
      final brokenBackupData = BackupData(
        format: BackupConstants.formatIdentifier,
        formatVersion: 1,
        exportedAt: '2026-11-15T12:00:00.000Z',
        semesters: [
          SemesterBackupModel(
            id: 99,
            name: 'Corrupted Backup Semester',
            attendanceThreshold: 0.75,
            calculationMethod: 'raw_combined',
            isArchived: false,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        subjects: [], // No subjects!
        attendanceSessions: [
          AttendanceSessionBackupModel(
            id: 500,
            subjectId: 9999, // Unresolvable subject!
            sessionDate: '2026-03-01',
            component: 'lecture',
            status: 'present',
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      // 3. Attempt restore and verify it throws
      expect(
        () async => await backupService.restoreBackup(brokenBackupData),
        throwsA(isA<ValidationFailure>()),
      );

      // 4. Verify transaction rollback: Pre-existing database remains 100% intact!
      final preservedSemesters = await semesterRepo.getSemesters();
      expect(preservedSemesters.length, 1);
      expect(preservedSemesters.first.name, 'Precious Existing Semester');
      expect(preservedSemesters.first.id, initialSemId);

      final preservedSubjects = await subjectRepo.getSubjectsForSemester(
        initialSemId,
      );
      expect(preservedSubjects.length, 1);
      expect(preservedSubjects.first.name, 'Database Management');

      final preservedSessions = await attendanceRepo
          .watchSessionsForSemester(initialSemId)
          .first;
      expect(preservedSessions.length, 1);
      expect(preservedSessions.first.sessionDate, '2026-03-01');
      expect(preservedSessions.first.status.dbValue, 'present');
    });

    test(
      'full round-trip export and restore preserves 100% data integrity',
      () async {
        // 1. Create a rich dataset in DB 1
        final semId = await semesterRepo.createSemester(
          name: 'Semester 6',
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 5, 20),
          attendanceThreshold: 0.85,
          calculationMethod: AttendanceCalculationMethod.componentAverage,
        );

        final sub1 = await subjectRepo.createSubject(
          semesterId: semId,
          name: 'Computer Networks',
          lectureEnabled: true,
          labEnabled: true,
        );

        final sub2 = await subjectRepo.createSubject(
          semesterId: semId,
          name: 'Software Engineering',
          lectureEnabled: true,
          labEnabled: false,
        );

        await attendanceRepo.createSession(
          subjectId: sub1,
          sessionDate: '2026-02-01',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
          note: 'Lecture 1',
        );
        await attendanceRepo.createSession(
          subjectId: sub1,
          sessionDate: '2026-02-01',
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
        );
        await attendanceRepo.createSession(
          subjectId: sub2,
          sessionDate: '2026-02-02',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );

        // 2. Export DB 1 to JSON
        final exportedJson = await backupService.exportBackupJson();
        final validation = BackupValidator.validate(exportedJson);
        expect(validation.isValid, isTrue);

        // 3. Setup fresh DB 2
        final db2 = AppDatabase.forTesting(NativeDatabase.memory());
        final backupService2 = BackupService(db2);
        final semRepo2 = SemesterRepositoryImpl(db2);
        final subRepo2 = SubjectRepositoryImpl(db2);
        final attRepo2 = AttendanceRepositoryImpl(db2);

        // 4. Restore into DB 2
        final restoredSemId = await backupService2.restoreBackup(
          validation.data!,
        );
        expect(restoredSemId, isNotNull);

        // 5. Verify DB 2 contents
        final sems2 = await semRepo2.getSemesters();
        expect(sems2.length, 1);
        expect(sems2.first.name, 'Semester 6');
        expect(sems2.first.attendanceThreshold, 0.85);
        expect(
          sems2.first.calculationMethod,
          AttendanceCalculationMethod.componentAverage,
        );

        final subs2 = await subRepo2.getSubjectsForSemester(sems2.first.id);
        expect(subs2.length, 2);

        final sess2 = await attRepo2
            .watchSessionsForSemester(sems2.first.id)
            .first;
        expect(sess2.length, 3);

        await db2.close();
      },
    );
  });
}
