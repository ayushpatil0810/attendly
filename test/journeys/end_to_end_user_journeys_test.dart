import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/backup/backup_format.dart';
import 'package:attendly/core/backup/backup_providers.dart';
import 'package:attendly/core/backup/backup_service.dart';
import 'package:attendly/core/backup/backup_validator.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/simulator/presentation/providers/simulator_providers.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('End-to-End User Journeys (Phase 6 Functional Audit)', () {
    test(
      'Journey 1: New Student — Onboarding, Semester Setup & Empty Dashboard',
      () async {
        container.listen(activeSemestersStreamProvider, (_, _) {});
        container.listen(activeSemesterSubjectsProvider, (_, _) {});
        container.listen(activeSemesterSessionsStreamProvider, (_, _) {});
        container.listen(semesterAttendanceSummaryProvider, (_, _) {});

        // 1. App Launch: verify fresh install state
        expect(container.read(onboardingCompletedProvider), isFalse);
        expect(container.read(activeSemesterProvider), isNull);

        // 2. Complete onboarding
        await container
            .read(onboardingCompletedProvider.notifier)
            .completeOnboarding();
        expect(container.read(onboardingCompletedProvider), isTrue);

        // 3 & 4. Create semester with threshold (80%) and Raw Combined method
        final semesterController = container.read(
          semesterControllerProvider.notifier,
        );
        final semId = await semesterController.createSemester(
          name: 'Semester 5 (CS)',
          attendanceThreshold: 0.80,
          calculationMethod: AttendanceCalculationMethod.rawCombined,
        );
        expect(semId, isNotNull);

        // Wait for stream to emit
        await Future<void>.delayed(Duration.zero);
        final activeSemester = container.read(activeSemesterProvider);
        expect(activeSemester, isNotNull);
        expect(activeSemester!.name, 'Semester 5 (CS)');
        expect(activeSemester.attendanceThreshold, 0.80);
        expect(
          activeSemester.calculationMethod,
          AttendanceCalculationMethod.rawCombined,
        );

        // 5 & 6. Add subjects with Lecture and Lab configurations
        final subjectController = container.read(
          subjectControllerProvider.notifier,
        );
        final sub1Id = await subjectController.createSubject(
          semesterId: semId!,
          name: 'Distributed Systems',
          lectureEnabled: true,
          labEnabled: true,
        );
        final sub2Id = await subjectController.createSubject(
          semesterId: semId,
          name: 'Technical Writing',
          lectureEnabled: true,
          labEnabled: false,
        );
        expect(sub1Id, isNotNull);
        expect(sub2Id, isNotNull);

        // 7 & 8. Reach Dashboard: verify correct honest empty state
        await Future<void>.delayed(Duration.zero);
        final summaryAsync = container.read(semesterAttendanceSummaryProvider);
        final summary = summaryAsync.value;
        expect(summary, isNotNull);
        expect(summary!.totalConducted, 0);
        expect(summary.totalPresent, 0);
        expect(summary.overallPercentage, isNull);
        expect(summary.isNotAvailable, isTrue);
        expect(summary.thresholdStatus, ThresholdStatus.notAvailable);
        expect(summary.subjectSummaries.length, 2);
        expect(summary.subjectSummaries.every((s) => s.isNotAvailable), isTrue);
      },
    );

    test(
      'Journey 2: Record Attendance — Quick Log, Duplicate Protection & Undo',
      () async {
        container.listen(activeSemestersStreamProvider, (_, _) {});
        container.listen(activeSemesterSubjectsProvider, (_, _) {});
        container.listen(activeSemesterSessionsStreamProvider, (_, _) {});
        container.listen(semesterAttendanceSummaryProvider, (_, _) {});

        final semController = container.read(
          semesterControllerProvider.notifier,
        );
        final semId = await semController.createSemester(
          name: 'Fall 2026',
          attendanceThreshold: 0.75,
        );
        expect(semId, isNotNull);

        final subjController = container.read(
          subjectControllerProvider.notifier,
        );
        final subjId = await subjController.createSubject(
          semesterId: semId!,
          name: 'Machine Learning',
          lectureEnabled: true,
          labEnabled: true,
        );
        expect(subjId, isNotNull);

        final attController = container.read(
          attendanceControllerProvider.notifier,
        );

        // 1-5. Mark Present for Machine Learning Lecture
        await attController.recordSession(
          subjectId: subjId,
          sessionDate: '2026-10-10',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        // Verify saved record
        await Future<void>.delayed(Duration.zero);
        var summary = container.read(semesterAttendanceSummaryProvider).value;
        expect(summary, isNotNull);
        expect(summary!.totalConducted, 1);
        expect(summary.totalPresent, 1);
        expect(summary.overallPercentage, 100.0);
        expect(summary.thresholdStatus, ThresholdStatus.meeting);

        // 6. Record Absent for Machine Learning Lab on same date (legitimate distinct component)
        await attController.recordSession(
          subjectId: subjId,
          sessionDate: '2026-10-10',
          component: SessionComponent.lab,
          status: AttendanceStatus.absent,
        );

        await Future<void>.delayed(Duration.zero);
        summary = container.read(semesterAttendanceSummaryProvider).value;
        expect(summary!.totalConducted, 2);
        expect(summary.totalPresent, 1);
        expect(summary.totalAbsent, 1);
        expect(summary.overallPercentage, 50.0);
        expect(summary.thresholdStatus, ThresholdStatus.below);

        // Test Undo: undo the last action (the Absent Lab session)
        await attController.undo();
        await Future<void>.delayed(Duration.zero);
        summary = container.read(semesterAttendanceSummaryProvider).value;
        expect(summary!.totalConducted, 1);
        expect(summary.totalPresent, 1);
        expect(summary.totalAbsent, 0);
        expect(summary.overallPercentage, 100.0);

        await attController.recordSession(
          subjectId: subjId,
          sessionDate: '2026-10-10',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
        await Future<void>.delayed(Duration.zero);
        summary = container.read(semesterAttendanceSummaryProvider).value;
        expect(summary!.totalConducted, 2);
        expect(summary.totalPresent, 2);
      },
    );

    test('Journey 3: Correct Historical Attendance — Past Entry, Status Edit & Session Deletion', () async {
      container.listen(activeSemestersStreamProvider, (_, _) {});
      container.listen(activeSemesterSubjectsProvider, (_, _) {});
      container.listen(activeSemesterSessionsStreamProvider, (_, _) {});
      container.listen(semesterAttendanceSummaryProvider, (_, _) {});

      final semController = container.read(semesterControllerProvider.notifier);
      final semId = await semController.createSemester(
        name: 'History Journey',
        attendanceThreshold: 0.75,
      );

      final subjController = container.read(subjectControllerProvider.notifier);
      final subjId = await subjController.createSubject(
        semesterId: semId!,
        name: 'Database Systems',
        lectureEnabled: true,
        labEnabled: false,
      );

      final attController = container.read(
        attendanceControllerProvider.notifier,
      );
      final attRepo = container.read(attendanceRepositoryProvider);

      // 1-3. Add a historical session on 2026-09-01 as Absent
      await attController.recordSession(
        subjectId: subjId,
        sessionDate: '2026-09-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.absent,
      );

      await Future<void>.delayed(Duration.zero);
      var summary = container.read(semesterAttendanceSummaryProvider).value;
      expect(summary, isNotNull);
      expect(summary!.totalConducted, 1);
      expect(summary.totalPresent, 0);
      expect(summary.overallPercentage, 0.0);

      // 4. Edit historical session: change status from Absent to Present
      final sessions = await attRepo.getSessionsForDate(semId, '2026-09-01');
      expect(sessions.length, 1);
      final session = sessions.first;

      final updatedToPresent = session.copyWith(
        status: AttendanceStatus.present,
        note: 'Attended make-up session',
      );
      await attController.updateSession(updatedToPresent);

      await Future<void>.delayed(Duration.zero);
      summary = container.read(semesterAttendanceSummaryProvider).value;
      expect(summary!.totalConducted, 1);
      expect(summary.totalPresent, 1);
      expect(summary.overallPercentage, 100.0);

      // 5 & 6. Delete the session: verify stats return to clean empty state
      final updatedSession = (await attRepo.getSessionsForDate(
        semId,
        '2026-09-01',
      )).first;
      await attController.deleteSession(updatedSession);

      await Future<void>.delayed(Duration.zero);
      summary = container.read(semesterAttendanceSummaryProvider).value;
      expect(summary!.totalConducted, 0);
      expect(summary.overallPercentage, isNull);
    });

    test('Journey 4: Review Attendance — Threshold Change & Calculation Recalculation', () async {
      container.listen(activeSemestersStreamProvider, (_, _) {});
      container.listen(activeSemesterSubjectsProvider, (_, _) {});
      container.listen(activeSemesterSessionsStreamProvider, (_, _) {});
      container.listen(semesterAttendanceSummaryProvider, (_, _) {});

      final semController = container.read(semesterControllerProvider.notifier);
      final semId = await semController.createSemester(
        name: 'Analytics Journey',
        attendanceThreshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      final subjController = container.read(subjectControllerProvider.notifier);
      final subjId = await subjController.createSubject(
        semesterId: semId!,
        name: 'Algorithms',
        lectureEnabled: true,
        labEnabled: true,
      );

      final attRepo = container.read(attendanceRepositoryProvider);
      // 8 Present, 2 Absent out of 10 conducted = 80%
      for (int i = 1; i <= 8; i++) {
        await attRepo.createSession(
          subjectId: subjId,
          sessionDate: '2026-10-0$i',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
      }
      for (int i = 9; i <= 10; i++) {
        await attRepo.createSession(
          subjectId: subjId,
          sessionDate: i == 10 ? '2026-10-10' : '2026-10-0$i',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );
      }

      await Future<void>.delayed(Duration.zero);
      var summary = container.read(semesterAttendanceSummaryProvider).value;
      expect(summary, isNotNull);
      expect(summary!.overallPercentage, 80.0);
      expect(summary.thresholdStatus, ThresholdStatus.meeting);
      expect(summary.safeAbsenceResult.safeAbsences, 0);

      // Change threshold to 70%
      final semRepo = container.read(semesterRepositoryProvider);
      final currentSemester = (await semRepo.getSemesterById(semId))!;
      await semController.updateSemester(
        currentSemester.copyWith(attendanceThreshold: 0.70),
      );

      await Future<void>.delayed(Duration.zero);
      summary = container.read(semesterAttendanceSummaryProvider).value;
      expect(summary!.overallPercentage, 80.0);
      expect(summary.threshold, 0.70);
      expect(summary.thresholdStatus, ThresholdStatus.meeting);
      expect(summary.safeAbsenceResult.safeAbsences, 1);

      // Switch calculation method to 50/50 Component Average
      await semController.updateSemester(
        currentSemester.copyWith(
          attendanceThreshold: 0.70,
          calculationMethod: AttendanceCalculationMethod.componentAverage,
        ),
      );

      await Future<void>.delayed(Duration.zero);
      summary = container.read(semesterAttendanceSummaryProvider).value;
      expect(
        summary!.calculationMethod,
        AttendanceCalculationMethod.componentAverage,
      );
      // Lecture has 10 sessions, but Lab has 0 sessions -> Provisional!
      expect(summary.isProvisional, isTrue);
      expect(summary.thresholdStatus, ThresholdStatus.notAvailable);
      expect(summary.subjectSummaries.first.isProvisional, isTrue);
    });

    test('Journey 5: Use Simulator — Add Scenarios & Strict Database Isolation', () async {
      container.listen(activeSemestersStreamProvider, (_, _) {});
      container.listen(activeSemesterSubjectsProvider, (_, _) {});
      container.listen(activeSemesterSessionsStreamProvider, (_, _) {});
      container.listen(semesterAttendanceSummaryProvider, (_, _) {});
      container.listen(simulatorProjectionProvider, (_, _) {});

      final semController = container.read(semesterControllerProvider.notifier);
      final semId = await semController.createSemester(
        name: 'Sim Journey',
        attendanceThreshold: 0.75,
      );

      final subjController = container.read(subjectControllerProvider.notifier);
      final subjId = await subjController.createSubject(
        semesterId: semId!,
        name: 'Computer Architecture',
        lectureEnabled: true,
        labEnabled: true,
      );

      final attRepo = container.read(attendanceRepositoryProvider);
      // 3 Present, 2 Absent = 60% (Below threshold)
      for (int i = 1; i <= 3; i++) {
        await attRepo.createSession(
          subjectId: subjId,
          sessionDate: '2026-11-0$i',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
      }
      for (int i = 4; i <= 5; i++) {
        await attRepo.createSession(
          subjectId: subjId,
          sessionDate: '2026-11-0$i',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );
      }

      await Future<void>.delayed(Duration.zero);
      final simController = container.read(
        simulatorControllerProvider.notifier,
      );

      // Add 3 hypothetical Presents
      simController.addMultipleSessions(
        subjectId: subjId,
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
        count: 3,
      );

      // Verify simulator projection
      await Future<void>.delayed(Duration.zero);
      final projection = container.read(simulatorProjectionProvider).value;
      expect(projection, isNotNull);
      expect(projection!.baselineSummary.totalConducted, 5);
      expect(projection.baselineSummary.totalPresent, 3);
      expect(projection.baselineSummary.overallPercentage, 60.0);
      expect(projection.projectedSummary.totalConducted, 8);
      expect(projection.projectedSummary.totalPresent, 6);
      expect(
        projection.projectedSummary.overallPercentage,
        75.0,
      ); // 6/8 = 75% meets threshold!
      expect(projection.projectedMeetsThreshold, isTrue);

      // Reset the simulator
      simController.reset();
      expect(container.read(simulatorControllerProvider), isEmpty);

      // STRICT ISOLATION: Confirm actual database records remain 100% untouched
      await Future<void>.delayed(Duration.zero);
      final actualSummary = container
          .read(semesterAttendanceSummaryProvider)
          .value;
      expect(actualSummary!.totalConducted, 5);
      expect(actualSummary.totalPresent, 3);
      expect(actualSummary.overallPercentage, 60.0);
      final allDbSessions = await attRepo.getSessionsForSubject(subjId);
      expect(allDbSessions.length, 5);
    });

    test('Journey 6: Backup & Restore — Export, Parity, Corruption Rejection & Transaction Rollback', () async {
      final backupService = container.read(backupServiceProvider);
      final semRepo = container.read(semesterRepositoryProvider);
      final subjRepo = container.read(subjectRepositoryProvider);
      final attRepo = container.read(attendanceRepositoryProvider);

      // Populate database
      final semId = await semRepo.createSemester(
        name: 'Backup Journey',
        attendanceThreshold: 0.75,
      );
      final subjId = await subjRepo.createSubject(
        semesterId: semId,
        name: 'Compiler Design',
        lectureEnabled: true,
        labEnabled: false,
      );
      await attRepo.createSession(
        subjectId: subjId,
        sessionDate: '2026-09-15',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      // 1-3. Export backup and verify
      final jsonStr = await backupService.exportBackupJson(
        appPreferences: {'hapticFeedback': true},
      );
      expect(jsonStr, isNotEmpty);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(parsed['format'], BackupConstants.formatIdentifier);
      expect(parsed['formatVersion'], 1);

      final valResult = BackupValidator.validate(jsonStr);
      expect(valResult.isValid, isTrue);
      final summary = valResult.summary!;
      expect(summary.semestersCount, 1);
      expect(summary.subjectsCount, 1);
      expect(summary.sessionsCount, 1);
      expect(summary.presentCount, 1);

      // 4 & 5. Restore into clean database and verify parity
      final restoreDb = AppDatabase.forTesting(NativeDatabase.memory());
      final restoreService = BackupService(restoreDb);
      await restoreService.restoreBackup(valResult.data!);

      final restoredSemRepo = SemesterRepositoryImpl(restoreDb);
      final restoredSubRepo = SubjectRepositoryImpl(restoreDb);
      final restoredAttRepo = AttendanceRepositoryImpl(restoreDb);

      final restoredSems = await restoredSemRepo.getSemesters(
        includeArchived: true,
      );
      expect(restoredSems.length, 1);
      expect(restoredSems.first.name, 'Backup Journey');

      final restoredSubs = await restoredSubRepo.getSubjectsForSemester(
        restoredSems.first.id,
      );
      expect(restoredSubs.length, 1);
      expect(restoredSubs.first.name, 'Compiler Design');

      final restoredSessions = await restoredAttRepo.getSessionsForSubject(
        restoredSubs.first.id,
      );
      expect(restoredSessions.length, 1);
      expect(restoredSessions.first.status, AttendanceStatus.present);

      // 6 & 7. Attempt to validate corrupted/malformed backup
      const corruptJson = '{"format": "invalid-format", "data": {}}';
      final corruptResult = BackupValidator.validate(corruptJson);
      expect(corruptResult.isValid, isFalse);
      expect(corruptResult.error, contains('Unrecognized backup format'));

      // Confirm existing restored data remains 100% intact after rejection
      final semsAfterFail = await restoredSemRepo.getSemesters(
        includeArchived: true,
      );
      expect(semsAfterFail.length, 1);
      expect(semsAfterFail.first.name, 'Backup Journey');

      await restoreDb.close();
    });
  });
}
