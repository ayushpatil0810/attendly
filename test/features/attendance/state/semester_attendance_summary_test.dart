import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_availability.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Reactive semester attendance summary updates', () {
    test(
      'updates reactively when adding, editing, and deleting sessions',
      () async {
        final container = createContainer();
        container.listen(activeSemestersStreamProvider, (_, _) {});
        container.listen(activeSemesterSubjectsProvider, (_, _) {});
        container.listen(activeSemesterSessionsStreamProvider, (_, _) {});
        container.listen(semesterAttendanceSummaryProvider, (_, _) {});

        // 1. Create active semester
        final semId = await container
            .read(semesterControllerProvider.notifier)
            .createSemester(name: 'Semester 1', attendanceThreshold: 0.75);
        expect(semId, isNotNull);
        await container.read(activeSemestersStreamProvider.future);

        // 2. Create subject
        final subId = await container
            .read(subjectControllerProvider.notifier)
            .createSubject(
              semesterId: semId!,
              name: 'Algorithms',
              lectureEnabled: true,
              labEnabled: true,
            );
        expect(subId, isNotNull);
        await container.read(activeSemesterSubjectsProvider.future);
        await container.read(activeSemesterSessionsStreamProvider.future);

        // Initially no sessions -> not available
        var summaryAsync = container.read(semesterAttendanceSummaryProvider);
        expect(summaryAsync.value, isNotNull);
        expect(
          summaryAsync.value!.availability,
          AttendanceAvailability.notAvailable,
        );
        expect(summaryAsync.value!.totalConducted, 0);

        // 3. Add a Present session
        final controller = container.read(
          attendanceControllerProvider.notifier,
        );
        final sessionId = await controller.recordSession(
          subjectId: subId!,
          sessionDate: '2026-09-01',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
        expect(sessionId, greaterThan(0));

        await Future<void>.delayed(Duration.zero);
        summaryAsync = container.read(semesterAttendanceSummaryProvider);
        expect(summaryAsync.value!.totalConducted, 1);
        expect(summaryAsync.value!.totalPresent, 1);
        expect(summaryAsync.value!.overallPercentage, 100.0);
        expect(summaryAsync.value!.thresholdStatus, ThresholdStatus.meeting);

        // 4. Add an Absent session
        await controller.recordSession(
          subjectId: subId,
          sessionDate: '2026-09-02',
          component: SessionComponent.lab,
          status: AttendanceStatus.absent,
        );

        await Future<void>.delayed(Duration.zero);
        summaryAsync = container.read(semesterAttendanceSummaryProvider);
        expect(summaryAsync.value!.totalConducted, 2);
        expect(summaryAsync.value!.totalPresent, 1);
        expect(summaryAsync.value!.totalAbsent, 1);
        expect(summaryAsync.value!.overallPercentage, 50.0);
        expect(summaryAsync.value!.thresholdStatus, ThresholdStatus.below);

        // 5. Edit session from Absent to Present
        final repo = container.read(attendanceRepositoryProvider);
        final allSessions = await repo.getSessionsForSubject(subId);
        final absentSession = allSessions.firstWhere((s) => s.isAbsent);
        await controller.updateSession(
          absentSession.copyWith(status: AttendanceStatus.present),
        );

        await Future<void>.delayed(Duration.zero);
        summaryAsync = container.read(semesterAttendanceSummaryProvider);
        expect(summaryAsync.value!.totalConducted, 2);
        expect(summaryAsync.value!.totalPresent, 2);
        expect(summaryAsync.value!.totalAbsent, 0);
        expect(summaryAsync.value!.overallPercentage, 100.0);
        expect(summaryAsync.value!.thresholdStatus, ThresholdStatus.meeting);

        // 6. Delete a session
        await controller.deleteSession(absentSession);

        await Future<void>.delayed(Duration.zero);
        summaryAsync = container.read(semesterAttendanceSummaryProvider);
        expect(summaryAsync.value!.totalConducted, 1);
        expect(summaryAsync.value!.totalPresent, 1);
        expect(summaryAsync.value!.overallPercentage, 100.0);
      },
    );

    test('recalculates immediately when switching semesters', () async {
      final container = createContainer();
      container.listen(activeSemestersStreamProvider, (_, _) {});
      container.listen(activeSemesterSubjectsProvider, (_, _) {});
      container.listen(activeSemesterSessionsStreamProvider, (_, _) {});
      container.listen(semesterAttendanceSummaryProvider, (_, _) {});

      final sem1 = (await container
          .read(semesterControllerProvider.notifier)
          .createSemester(name: 'Sem 1', attendanceThreshold: 0.75))!;
      final sub1 = (await container
          .read(subjectControllerProvider.notifier)
          .createSubject(semesterId: sem1, name: 'Sub 1'))!;

      final sem2 = (await container
          .read(semesterControllerProvider.notifier)
          .createSemester(name: 'Sem 2', attendanceThreshold: 0.85))!;
      final sub2 = (await container
          .read(subjectControllerProvider.notifier)
          .createSubject(semesterId: sem2, name: 'Sub 2'))!;

      final controller = container.read(attendanceControllerProvider.notifier);

      // Sem 1: 1 present / 1 conducted = 100%
      await controller.recordSession(
        subjectId: sub1,
        sessionDate: '2026-09-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      // Sem 2: 0 present / 1 conducted = 0%
      await controller.recordSession(
        subjectId: sub2,
        sessionDate: '2026-09-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.absent,
      );

      // Select Sem 1
      container.read(selectedSemesterIdProvider.notifier).selectSemester(sem1);
      await Future<void>.delayed(Duration.zero);

      var summary = container.read(semesterAttendanceSummaryProvider).value!;
      expect(summary.semesterId, sem1);
      expect(summary.overallPercentage, 100.0);

      // Switch to Sem 2
      container.read(selectedSemesterIdProvider.notifier).selectSemester(sem2);
      await Future<void>.delayed(Duration.zero);

      summary = container.read(semesterAttendanceSummaryProvider).value!;
      expect(summary.semesterId, sem2);
      expect(summary.overallPercentage, 0.0);
      expect(summary.threshold, 0.85);
      expect(summary.thresholdStatus, ThresholdStatus.below);
    });

    test('recalculates immediately when threshold changes', () async {
      final container = createContainer();
      container.listen(activeSemestersStreamProvider, (_, _) {});
      container.listen(activeSemesterSubjectsProvider, (_, _) {});
      container.listen(activeSemesterSessionsStreamProvider, (_, _) {});
      container.listen(semesterAttendanceSummaryProvider, (_, _) {});

      final semId = (await container
          .read(semesterControllerProvider.notifier)
          .createSemester(name: 'Sem 1', attendanceThreshold: 0.75))!;
      final subId = (await container
          .read(subjectControllerProvider.notifier)
          .createSubject(semesterId: semId, name: 'Sub 1'))!;

      final controller = container.read(attendanceControllerProvider.notifier);
      // 8 present / 10 conducted = 80%
      for (var i = 1; i <= 8; i++) {
        await controller.recordSession(
          subjectId: subId,
          sessionDate: '2026-09-0$i',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
      }
      for (var i = 9; i <= 10; i++) {
        final d = i < 10 ? '0$i' : '$i';
        await controller.recordSession(
          subjectId: subId,
          sessionDate: '2026-09-$d',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );
      }

      await Future<void>.delayed(Duration.zero);

      // At 75% threshold, 80% is meeting threshold
      var summary = container.read(semesterAttendanceSummaryProvider).value!;
      expect(summary.threshold, 0.75);
      expect(summary.thresholdStatus, ThresholdStatus.meeting);

      // Update semester threshold to 85% (0.85)
      final sem = container.read(activeSemesterProvider)!;
      final updatedSem = sem.copyWith(attendanceThreshold: 0.85);
      await container
          .read(semesterControllerProvider.notifier)
          .updateSemester(updatedSem);

      await Future<void>.delayed(Duration.zero);
      summary = container.read(semesterAttendanceSummaryProvider).value!;
      expect(summary.threshold, 0.85);
      // Now 80% is below 85%
      expect(summary.thresholdStatus, ThresholdStatus.below);
      expect(summary.recoveryResult.requiredConsecutivePresents, isNotNull);
    });

    test('recalculates immediately when calculation method changes', () async {
      final container = createContainer();
      container.listen(activeSemestersStreamProvider, (_, _) {});
      container.listen(activeSemesterSubjectsProvider, (_, _) {});
      container.listen(activeSemesterSessionsStreamProvider, (_, _) {});
      container.listen(semesterAttendanceSummaryProvider, (_, _) {});

      final semId = (await container
          .read(semesterControllerProvider.notifier)
          .createSemester(
            name: 'Sem 1',
            attendanceThreshold: 0.75,
            calculationMethod: AttendanceCalculationMethod.rawCombined,
          ))!;
      final subId = (await container
          .read(subjectControllerProvider.notifier)
          .createSubject(
            semesterId: semId,
            name: 'Math',
            lectureEnabled: true,
            labEnabled: true,
          ))!;

      final controller = container.read(attendanceControllerProvider.notifier);
      // Lecture: 2 present, 0 absent (100%)
      await controller.recordSession(
        subjectId: subId,
        sessionDate: '2026-01-01',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );
      await controller.recordSession(
        subjectId: subId,
        sessionDate: '2026-01-02',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );
      // Lab: 0 present, 1 absent (0%)
      await controller.recordSession(
        subjectId: subId,
        sessionDate: '2026-01-03',
        component: SessionComponent.lab,
        status: AttendanceStatus.absent,
      );

      await Future<void>.delayed(Duration.zero);

      // Raw Combined: 2 / 3 = 66.666%
      var summary = container.read(semesterAttendanceSummaryProvider).value!;
      expect(
        summary.calculationMethod,
        AttendanceCalculationMethod.rawCombined,
      );
      expect(summary.overallPercentage, closeTo(66.666, 0.01));

      // Switch to Component Average: (100% + 0%) / 2 = 50%
      final sem = container.read(activeSemesterProvider)!;
      final updatedSem = sem.copyWith(
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );
      await container
          .read(semesterControllerProvider.notifier)
          .updateSemester(updatedSem);

      await Future<void>.delayed(Duration.zero);
      summary = container.read(semesterAttendanceSummaryProvider).value!;
      expect(
        summary.calculationMethod,
        AttendanceCalculationMethod.componentAverage,
      );
      expect(summary.overallPercentage, 50.0);
      expect(summary.lecturePercentage, 100.0);
      expect(summary.labPercentage, 0.0);
    });
  });
}
