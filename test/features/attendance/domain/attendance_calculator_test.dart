import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_availability.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/attendance/domain/services/attendance_calculator.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';

void main() {
  const calculator = AttendanceCalculator();

  final baseSemester = Semester(
    id: 1,
    name: 'Fall 2026',
    attendanceThreshold: 0.75,
    calculationMethod: AttendanceCalculationMethod.rawCombined,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  final baseSubject = Subject(
    id: 10,
    semesterId: 1,
    name: 'Machine Learning',
    lectureEnabled: true,
    labEnabled: true,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  group('AttendanceCalculator - Raw Combined', () {
    test('no recorded sessions returns Not available (not 0%)', () {
      final summary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: [],
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(summary.availability, AttendanceAvailability.notAvailable);
      expect(summary.percentage, isNull);
      expect(summary.totalConducted, 0);
      expect(summary.totalPresent, 0);
      expect(summary.totalAbsent, 0);
      expect(summary.thresholdStatus, ThresholdStatus.notAvailable);
    });

    test('all present returns 100% and meeting threshold', () {
      final sessions = List.generate(
        10,
        (i) => AttendanceSession(
          id: i + 1,
          subjectId: 10,
          sessionDate: '2026-09-01',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
      );

      final summary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: sessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(summary.availability, AttendanceAvailability.available);
      expect(summary.percentage, 100.0);
      expect(summary.totalConducted, 10);
      expect(summary.totalPresent, 10);
      expect(summary.totalAbsent, 0);
      expect(summary.thresholdStatus, ThresholdStatus.meeting);
    });

    test('all absent returns 0% and below threshold (not unavailable)', () {
      final sessions = List.generate(
        10,
        (i) => AttendanceSession(
          id: i + 1,
          subjectId: 10,
          sessionDate: '2026-09-01',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
      );

      final summary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: sessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(summary.availability, AttendanceAvailability.available);
      expect(summary.percentage, 0.0);
      expect(summary.totalConducted, 10);
      expect(summary.totalPresent, 0);
      expect(summary.totalAbsent, 10);
      expect(summary.thresholdStatus, ThresholdStatus.below);
    });

    test('mixed attendance 80 present / 100 conducted returns 80%', () {
      final sessions = [
        ...List.generate(
          80,
          (i) => AttendanceSession(
            id: i + 1,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
            createdAt: DateTime(2026, 9, 1),
            updatedAt: DateTime(2026, 9, 1),
          ),
        ),
        ...List.generate(
          20,
          (i) => AttendanceSession(
            id: i + 81,
            subjectId: 10,
            sessionDate: '2026-09-02',
            component: SessionComponent.lab,
            status: AttendanceStatus.absent,
            createdAt: DateTime(2026, 9, 2),
            updatedAt: DateTime(2026, 9, 2),
          ),
        ),
      ];

      final summary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: sessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(summary.availability, AttendanceAvailability.available);
      expect(summary.percentage, 80.0);
      expect(summary.totalConducted, 100);
      expect(summary.totalPresent, 80);
      expect(summary.totalAbsent, 20);
      expect(summary.thresholdStatus, ThresholdStatus.meeting);
      expect(summary.safeAbsenceResult.safeAbsences, 6);
    });

    test('threshold status boundaries (exact, just below, just above)', () {
      // 75 / 100 at 75% -> meeting
      final atSessions = [
        ...List.generate(
          75,
          (i) => AttendanceSession(
            id: i,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          25,
          (i) => AttendanceSession(
            id: i + 100,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];
      final atSummary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: atSessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );
      expect(atSummary.thresholdStatus, ThresholdStatus.meeting);
      expect(atSummary.safeAbsenceResult.safeAbsences, 0);

      // 74 / 100 at 75% -> below
      final belowSessions = [
        ...List.generate(
          74,
          (i) => AttendanceSession(
            id: i,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          26,
          (i) => AttendanceSession(
            id: i + 100,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];
      final belowSummary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: belowSessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );
      expect(belowSummary.thresholdStatus, ThresholdStatus.below);
      expect(belowSummary.recoveryResult.requiredConsecutivePresents, 4);

      // 76 / 100 at 75% -> meeting
      final aboveSessions = [
        ...List.generate(
          76,
          (i) => AttendanceSession(
            id: i,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          24,
          (i) => AttendanceSession(
            id: i + 100,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];
      final aboveSummary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: aboveSessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );
      expect(aboveSummary.thresholdStatus, ThresholdStatus.meeting);
      expect(aboveSummary.safeAbsenceResult.safeAbsences, 1);
    });
  });

  group('AttendanceCalculator - Component Average (50/50)', () {
    test('both components have sessions: Lecture 36/40 (90%), Lab 6/10 (60%) -> 75%', () {
      final sessions = [
        ...List.generate(
          36,
          (i) => AttendanceSession(
            id: i + 1,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          4,
          (i) => AttendanceSession(
            id: i + 50,
            subjectId: 10,
            sessionDate: '2026-09-02',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          6,
          (i) => AttendanceSession(
            id: i + 100,
            subjectId: 10,
            sessionDate: '2026-09-03',
            component: SessionComponent.lab,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          4,
          (i) => AttendanceSession(
            id: i + 150,
            subjectId: 10,
            sessionDate: '2026-09-04',
            component: SessionComponent.lab,
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];

      final summary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: sessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      expect(summary.availability, AttendanceAvailability.available);
      expect(summary.percentage, 75.0);
      expect(summary.lectureSummary?.percentage, 90.0);
      expect(summary.labSummary?.percentage, 60.0);
      expect(summary.thresholdStatus, ThresholdStatus.meeting);
    });

    test('only Lecture enabled: Lecture 36/40, Lab disabled -> 90%', () {
      final lectureOnlySubject = baseSubject.copyWith(labEnabled: false);
      final sessions = [
        ...List.generate(
          36,
          (i) => AttendanceSession(
            id: i + 1,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          4,
          (i) => AttendanceSession(
            id: i + 50,
            subjectId: 10,
            sessionDate: '2026-09-02',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];

      final summary = calculator.calculateSubject(
        subject: lectureOnlySubject,
        sessions: sessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      expect(summary.availability, AttendanceAvailability.available);
      expect(summary.percentage, 90.0);
      expect(summary.lectureSummary?.percentage, 90.0);
      expect(summary.labSummary, isNull);
    });

    test('only Lab enabled: Lab 6/10, Lecture disabled -> 60%', () {
      final labOnlySubject = baseSubject.copyWith(
        lectureEnabled: false,
        labEnabled: true,
      );
      final sessions = [
        ...List.generate(
          6,
          (i) => AttendanceSession(
            id: i + 1,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lab,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          4,
          (i) => AttendanceSession(
            id: i + 50,
            subjectId: 10,
            sessionDate: '2026-09-02',
            component: SessionComponent.lab,
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];

      final summary = calculator.calculateSubject(
        subject: labOnlySubject,
        sessions: sessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      expect(summary.availability, AttendanceAvailability.available);
      expect(summary.percentage, 60.0);
      expect(summary.lectureSummary, isNull);
      expect(summary.labSummary?.percentage, 60.0);
    });

    test('both enabled, but Lab has no sessions -> provisional lecture, combined not available', () {
      final sessions = List.generate(
        10,
        (i) => AttendanceSession(
          id: i + 1,
          subjectId: 10,
          sessionDate: '2026-09-01',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final summary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: sessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      expect(summary.availability, AttendanceAvailability.provisional);
      expect(summary.percentage, 100.0); // provisional lecture percentage
      expect(summary.lectureSummary?.percentage, 100.0);
      expect(summary.labSummary?.percentage, isNull);
      expect(
        summary.labSummary?.availability,
        AttendanceAvailability.notAvailable,
      );
      expect(summary.thresholdStatus, ThresholdStatus.notAvailable);
    });

    test('both enabled, but Lecture has no sessions -> provisional lab, combined not available', () {
      final sessions = List.generate(
        5,
        (i) => AttendanceSession(
          id: i + 1,
          subjectId: 10,
          sessionDate: '2026-09-01',
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final summary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: sessions,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      expect(summary.availability, AttendanceAvailability.provisional);
      expect(summary.percentage, 100.0); // provisional lab percentage
      expect(summary.lectureSummary?.percentage, isNull);
      expect(summary.labSummary?.percentage, 100.0);
      expect(summary.thresholdStatus, ThresholdStatus.notAvailable);
    });

    test('both enabled, neither has sessions -> not available', () {
      final summary = calculator.calculateSubject(
        subject: baseSubject,
        sessions: [],
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      expect(summary.availability, AttendanceAvailability.notAvailable);
      expect(summary.percentage, isNull);
    });

    test(
      'one component all absent: Lecture 10/10 (100%), Lab 0/5 (0%) -> 50%',
      () {
        final sessions = [
          ...List.generate(
            10,
            (i) => AttendanceSession(
              id: i + 1,
              subjectId: 10,
              sessionDate: '2026-09-01',
              component: SessionComponent.lecture,
              status: AttendanceStatus.present,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          ...List.generate(
            5,
            (i) => AttendanceSession(
              id: i + 50,
              subjectId: 10,
              sessionDate: '2026-09-02',
              component: SessionComponent.lab,
              status: AttendanceStatus.absent,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ];

        final summary = calculator.calculateSubject(
          subject: baseSubject,
          sessions: sessions,
          threshold: 0.75,
          calculationMethod: AttendanceCalculationMethod.componentAverage,
        );

        expect(summary.availability, AttendanceAvailability.available);
        expect(summary.percentage, 50.0);
        expect(summary.lectureSummary?.percentage, 100.0);
        expect(summary.labSummary?.percentage, 0.0);
        expect(summary.thresholdStatus, ThresholdStatus.below);
      },
    );
  });

  group('AttendanceCalculator - Semester Level & Trends', () {
    test('computes semester summary under Raw Combined', () {
      final subject1 = baseSubject.copyWith(id: 10, name: 'Machine Learning');
      final subject2 = baseSubject.copyWith(id: 20, name: 'Networks');

      final sessions = [
        AttendanceSession(
          id: 1,
          subjectId: 10,
          sessionDate: '2026-09-01',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
        AttendanceSession(
          id: 2,
          subjectId: 10,
          sessionDate: '2026-09-02',
          component: SessionComponent.lab,
          status: AttendanceStatus.absent,
          createdAt: DateTime(2026, 9, 2),
          updatedAt: DateTime(2026, 9, 2),
        ),
        AttendanceSession(
          id: 3,
          subjectId: 20,
          sessionDate: '2026-09-02',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
          createdAt: DateTime(2026, 9, 2),
          updatedAt: DateTime(2026, 9, 2),
        ),
        AttendanceSession(
          id: 4,
          subjectId: 20,
          sessionDate: '2026-09-03',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
          createdAt: DateTime(2026, 9, 3),
          updatedAt: DateTime(2026, 9, 3),
        ),
      ];

      final summary = calculator.calculateSemester(
        semester: baseSemester,
        subjects: [subject1, subject2],
        sessions: sessions,
      );

      expect(summary.totalConducted, 4);
      expect(summary.totalPresent, 3);
      expect(summary.totalAbsent, 1);
      expect(summary.overallPercentage, 75.0);
      expect(summary.availability, AttendanceAvailability.available);
      expect(summary.thresholdStatus, ThresholdStatus.meeting);
      expect(summary.differenceFromThreshold, closeTo(0.0, 1e-6));
      expect(summary.subjectSummaries.length, 2);
      expect(
        summary.trendPoints.length,
        3,
      ); // 2026-09-01, 2026-09-02, 2026-09-03

      expect(summary.trendPoints[0].dateStr, '2026-09-01');
      expect(summary.trendPoints[0].cumulativePresent, 1);
      expect(summary.trendPoints[0].cumulativeConducted, 1);
      expect(summary.trendPoints[0].cumulativePercentage, 100.0);

      expect(summary.trendPoints[1].dateStr, '2026-09-02');
      expect(summary.trendPoints[1].cumulativePresent, 2);
      expect(summary.trendPoints[1].cumulativeConducted, 3);
      expect(
        summary.trendPoints[1].cumulativePercentage,
        closeTo(66.666, 0.01),
      );

      expect(summary.trendPoints[2].dateStr, '2026-09-03');
      expect(summary.trendPoints[2].cumulativePresent, 3);
      expect(summary.trendPoints[2].cumulativeConducted, 4);
      expect(summary.trendPoints[2].cumulativePercentage, 75.0);
    });

    test('computes semester summary under Component Average', () {
      final compAvgSemester = baseSemester.copyWith(
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      final subject = baseSubject.copyWith(
        id: 10,
        lectureEnabled: true,
        labEnabled: true,
      );

      // 36/40 lecture, 6/10 lab
      final sessions = [
        ...List.generate(
          36,
          (i) => AttendanceSession(
            id: i + 1,
            subjectId: 10,
            sessionDate: '2026-09-01',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          4,
          (i) => AttendanceSession(
            id: i + 50,
            subjectId: 10,
            sessionDate: '2026-09-02',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          6,
          (i) => AttendanceSession(
            id: i + 100,
            subjectId: 10,
            sessionDate: '2026-09-03',
            component: SessionComponent.lab,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          4,
          (i) => AttendanceSession(
            id: i + 150,
            subjectId: 10,
            sessionDate: '2026-09-04',
            component: SessionComponent.lab,
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];

      final summary = calculator.calculateSemester(
        semester: compAvgSemester,
        subjects: [subject],
        sessions: sessions,
      );

      expect(summary.overallPercentage, 75.0);
      expect(summary.availability, AttendanceAvailability.available);
      expect(summary.lecturePercentage, 90.0);
      expect(summary.labPercentage, 60.0);
      expect(summary.safeAbsenceResult.requiresScenario, isTrue);
      expect(summary.recoveryResult.requiresScenario, isTrue);
    });
  });
}
