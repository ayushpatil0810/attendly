import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/simulator/presentation/providers/simulator_providers.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int semesterId;
  late int subjectId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final semRepo = SemesterRepositoryImpl(db);
    semesterId = await semRepo.createSemester(name: 'Fall 2026');

    final subjRepo = SubjectRepositoryImpl(db);
    subjectId = await subjRepo.createSubject(
      semesterId: semesterId,
      name: 'Algorithms',
      lectureEnabled: true,
      labEnabled: true,
    );

    // Initial actual attendance: 1 session (Present)
    final attRepo = AttendanceRepositoryImpl(db);
    await attRepo.createSession(
      subjectId: subjectId,
      sessionDate: '2026-09-01',
      component: SessionComponent.lecture,
      status: AttendanceStatus.present,
    );

    final semester = await semRepo.getSemesterById(semesterId);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeSemesterProvider.overrideWithValue(semester),
      ],
    );

    // Keep streams active
    container.listen(activeSemesterSubjectsProvider, (_, _) {});
    container.listen(activeSemesterSessionsStreamProvider, (_, _) {});
    container.listen(semesterAttendanceSummaryProvider, (_, _) {});
    container.listen(simulatorProjectionProvider, (_, _) {});

    await container.read(activeSemesterSubjectsProvider.future);
    await container.read(activeSemesterSessionsStreamProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<int> getRealDatabaseSessionCount() async {
    final rows = await db.select(db.attendanceSessions).get();
    return rows.length;
  }

  group('Simulator Isolation Tests', () {
    test(
      'Adding a hypothetical session does not write to SQLite database',
      () async {
        final initialCount = await getRealDatabaseSessionCount();
        expect(initialCount, equals(1));

        // Add hypothetical session
        container
            .read(simulatorControllerProvider.notifier)
            .addSession(
              subjectId: subjectId,
              component: SessionComponent.lecture,
              status: AttendanceStatus.absent,
            );

        // Verify simulator has 1 hypothetical session
        final hypoList = container.read(simulatorControllerProvider);
        expect(hypoList.length, equals(1));

        // Verify SQLite record count is STRICTLY UNCHANGED
        final countAfter = await getRealDatabaseSessionCount();
        expect(countAfter, equals(1));
      },
    );

    test(
      'Toggling hypothetical session does not modify actual records',
      () async {
        container
            .read(simulatorControllerProvider.notifier)
            .addSession(
              subjectId: subjectId,
              component: SessionComponent.lecture,
              status: AttendanceStatus.present,
            );

        final hypoId = container.read(simulatorControllerProvider).first.id;

        // Toggle status to absent
        container
            .read(simulatorControllerProvider.notifier)
            .toggleSessionStatus(hypoId);

        // Verify in-memory state changed
        expect(
          container.read(simulatorControllerProvider).first.isAbsent,
          isTrue,
        );

        // Verify real SQLite row status remains 'present'
        final realRows = await db.select(db.attendanceSessions).get();
        expect(realRows.length, equals(1));
        expect(realRows.first.status, equals('present'));
      },
    );

    test(
      'Removing a hypothetical session does not delete actual records',
      () async {
        container
            .read(simulatorControllerProvider.notifier)
            .addSession(
              subjectId: subjectId,
              component: SessionComponent.lab,
              status: AttendanceStatus.present,
            );

        final hypoId = container.read(simulatorControllerProvider).first.id;
        container
            .read(simulatorControllerProvider.notifier)
            .removeSession(hypoId);

        expect(container.read(simulatorControllerProvider), isEmpty);

        // Verify SQLite row still exists!
        final count = await getRealDatabaseSessionCount();
        expect(count, equals(1));
      },
    );

    test('Resetting the simulator does not delete actual records', () async {
      container
          .read(simulatorControllerProvider.notifier)
          .addMultipleSessions(
            subjectId: subjectId,
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
            count: 5,
          );

      expect(container.read(simulatorControllerProvider).length, equals(5));

      // Reset
      container.read(simulatorControllerProvider.notifier).reset();
      expect(container.read(simulatorControllerProvider), isEmpty);

      // Real DB count is still 1
      final count = await getRealDatabaseSessionCount();
      expect(count, equals(1));
    });

    test('Dashboard attendance values remain unchanged while hypothetical sessions are added', () async {
      // Pump event loop to allow streams to emit
      await pumpEventQueue();

      final initialDashboardSummary = container
          .read(semesterAttendanceSummaryProvider)
          .asData
          ?.value;
      expect(initialDashboardSummary?.totalConducted, equals(1));
      expect(initialDashboardSummary?.overallPercentage, equals(100.0));

      // Add 10 hypothetical Absent sessions in simulator
      container
          .read(simulatorControllerProvider.notifier)
          .addMultipleSessions(
            subjectId: subjectId,
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            count: 10,
          );

      // Simulator projection reflects 1/11 = 9.09%
      final projection = container
          .read(simulatorProjectionProvider)
          .asData
          ?.value;
      expect(projection?.projectedSummary.totalConducted, equals(11));
      expect(
        projection?.projectedSummary.overallPercentage,
        closeTo(9.09, 0.01),
      );

      // REAL Dashboard summary is COMPLETELY UNAFFECTED! Still 1 conducted, 100%
      final dashboardSummaryAfter = container
          .read(semesterAttendanceSummaryProvider)
          .asData
          ?.value;
      expect(dashboardSummaryAfter?.totalConducted, equals(1));
      expect(dashboardSummaryAfter?.overallPercentage, equals(100.0));
      expect(dashboardSummaryAfter?.meetsThreshold, isTrue);
    });

    test('Actual attendance changes still refresh the simulator baseline reactively', () async {
      await pumpEventQueue();

      // Simulator has 1 hypothetical Present session
      container
          .read(simulatorControllerProvider.notifier)
          .addSession(
            subjectId: subjectId,
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
          );

      final initialProj = container
          .read(simulatorProjectionProvider)
          .asData
          ?.value;
      expect(initialProj?.baselineSummary.totalConducted, equals(1));
      expect(initialProj?.projectedSummary.totalConducted, equals(2));

      // Now add a real session via the real repository
      await container
          .read(attendanceControllerProvider.notifier)
          .recordSession(
            subjectId: subjectId,
            sessionDate: '2026-09-02',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
          );

      // Wait for stream to update
      await pumpEventQueue();

      final updatedProj = container
          .read(simulatorProjectionProvider)
          .asData
          ?.value;

      // Baseline refreshed to 2 real sessions, projection is 2 real + 1 hypothetical = 3!
      expect(updatedProj?.baselineSummary.totalConducted, equals(2));
      expect(updatedProj?.projectedSummary.totalConducted, equals(3));
    });
  });
}
