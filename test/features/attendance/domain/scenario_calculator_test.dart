import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/hypothetical_session.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/services/attendance_calculator.dart';
import 'package:attendly/features/attendance/domain/services/scenario_calculator.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';

void main() {
  const calculator = ScenarioCalculator(
    attendanceCalculator: AttendanceCalculator(),
  );

  final testSemesterRaw = Semester(
    id: 1,
    name: 'Fall 2026',
    attendanceThreshold: 0.75,
    calculationMethod: AttendanceCalculationMethod.rawCombined,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  final testSemesterAvg = Semester(
    id: 2,
    name: 'Spring 2026',
    attendanceThreshold: 0.75,
    calculationMethod: AttendanceCalculationMethod.componentAverage,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final subject1 = Subject(
    id: 10,
    semesterId: 1,
    name: 'Networks',
    lectureEnabled: true,
    labEnabled: true,
    sortOrder: 0,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  final subject2 = Subject(
    id: 20,
    semesterId: 1,
    name: 'Algorithms',
    lectureEnabled: true,
    labEnabled: false,
    sortOrder: 1,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  List<AttendanceSession> createSessions({
    required int subjectId,
    required SessionComponent component,
    required int present,
    required int absent,
  }) {
    final list = <AttendanceSession>[];
    for (var i = 0; i < present; i++) {
      list.add(
        AttendanceSession(
          id: list.length + 1,
          subjectId: subjectId,
          sessionDate: '2026-09-01',
          component: component,
          status: AttendanceStatus.present,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
      );
    }
    for (var i = 0; i < absent; i++) {
      list.add(
        AttendanceSession(
          id: list.length + 1,
          subjectId: subjectId,
          sessionDate: '2026-09-02',
          component: component,
          status: AttendanceStatus.absent,
          createdAt: DateTime(2026, 9, 2),
          updatedAt: DateTime(2026, 9, 2),
        ),
      );
    }
    return list;
  }

  group('ScenarioCalculator - Raw Combined projections', () {
    test('No hypothetical sessions returns baseline projection', () {
      final actualSessions = createSessions(
        subjectId: 10,
        component: SessionComponent.lecture,
        present: 15,
        absent: 5,
      ); // 15/20 = 75%

      final projection = calculator.calculateProjection(
        semester: testSemesterRaw,
        subjects: [subject1],
        actualSessions: actualSessions,
        hypotheticalSessions: const [],
      );

      expect(projection.hasSimulatedSessions, isFalse);
      expect(projection.simulatedCount, equals(0));
      expect(projection.baselineSummary.overallPercentage, equals(75.0));
      expect(projection.projectedSummary.overallPercentage, equals(75.0));
      expect(projection.percentageDifference, equals(0.0));
      expect(projection.projectedMeetsThreshold, isTrue);
    });

    test('One hypothetical Present session increases percentage', () {
      final actualSessions = createSessions(
        subjectId: 10,
        component: SessionComponent.lecture,
        present: 7,
        absent: 3,
      ); // 7/10 = 70% (below 75%)

      final hypo = [
        const HypotheticalSession(
          id: 'h1',
          subjectId: 10,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        ),
      ];

      final projection = calculator.calculateProjection(
        semester: testSemesterRaw,
        subjects: [subject1],
        actualSessions: actualSessions,
        hypotheticalSessions: hypo,
      );

      // Baseline: 7/10 = 70%
      expect(projection.baselineSummary.overallPercentage, equals(70.0));
      expect(projection.baselineSummary.meetsThreshold, isFalse);

      // Projected: 8/11 = 72.727%
      expect(projection.projectedSummary.totalPresent, equals(8));
      expect(projection.projectedSummary.totalConducted, equals(11));
      expect(
        projection.projectedSummary.overallPercentage,
        closeTo(72.727, 0.01),
      );
      expect(projection.percentageDifference, closeTo(2.727, 0.01));
      expect(projection.improvedToThreshold, isFalse);
    });

    test('One hypothetical Absent session decreases percentage', () {
      final actualSessions = createSessions(
        subjectId: 10,
        component: SessionComponent.lecture,
        present: 8,
        absent: 2,
      ); // 8/10 = 80%

      final hypo = [
        const HypotheticalSession(
          id: 'h1',
          subjectId: 10,
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        ),
      ];

      final projection = calculator.calculateProjection(
        semester: testSemesterRaw,
        subjects: [subject1],
        actualSessions: actualSessions,
        hypotheticalSessions: hypo,
      );

      // Projected: 8/11 = 72.727% (crosses below 75% threshold!)
      expect(projection.baselineSummary.overallPercentage, equals(80.0));
      expect(projection.baselineSummary.meetsThreshold, isTrue);
      expect(
        projection.projectedSummary.overallPercentage,
        closeTo(72.727, 0.01),
      );
      expect(projection.projectedSummary.meetsThreshold, isFalse);
      expect(projection.droppedBelowThreshold, isTrue);
    });

    test('Multiple hypothetical sessions with mixed outcomes', () {
      final actualSessions = createSessions(
        subjectId: 10,
        component: SessionComponent.lecture,
        present: 10,
        absent: 10,
      ); // 10/20 = 50%

      final hypo = [
        const HypotheticalSession(
          id: 'h1',
          subjectId: 10,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        ),
        const HypotheticalSession(
          id: 'h2',
          subjectId: 10,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        ),
        const HypotheticalSession(
          id: 'h3',
          subjectId: 10,
          component: SessionComponent.lab,
          status: AttendanceStatus.absent,
        ),
      ];

      final projection = calculator.calculateProjection(
        semester: testSemesterRaw,
        subjects: [subject1],
        actualSessions: actualSessions,
        hypotheticalSessions: hypo,
      );

      expect(projection.simulatedCount, equals(3));
      expect(projection.simulatedPresentCount, equals(2));
      expect(projection.simulatedAbsentCount, equals(1));

      // 12/23 = 52.17%
      expect(projection.projectedSummary.totalPresent, equals(12));
      expect(projection.projectedSummary.totalConducted, equals(23));
      expect(
        projection.projectedSummary.overallPercentage,
        closeTo(52.174, 0.01),
      );
    });

    test('Threshold exactly met projection', () {
      final actualSessions = createSessions(
        subjectId: 10,
        component: SessionComponent.lecture,
        present: 2,
        absent: 1,
      ); // 2/3 = 66.67%

      // Adding 1 Present makes it 3/4 = 75.0%
      final hypo = [
        const HypotheticalSession(
          id: 'h1',
          subjectId: 10,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        ),
      ];

      final projection = calculator.calculateProjection(
        semester: testSemesterRaw,
        subjects: [subject1],
        actualSessions: actualSessions,
        hypotheticalSessions: hypo,
      );

      expect(projection.projectedSummary.totalPresent, equals(3));
      expect(projection.projectedSummary.totalConducted, equals(4));
      expect(projection.projectedSummary.overallPercentage, equals(75.0));
      expect(projection.projectedMeetsThreshold, isTrue);
      expect(projection.improvedToThreshold, isTrue);
    });

    test('Single-component subjects handled correctly', () {
      final actualSessions = createSessions(
        subjectId: 20, // Algorithms (Lecture only)
        component: SessionComponent.lecture,
        present: 9,
        absent: 1,
      ); // 9/10 = 90%

      final hypo = [
        const HypotheticalSession(
          id: 'h1',
          subjectId: 20,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        ),
      ];

      final projection = calculator.calculateProjection(
        semester: testSemesterRaw,
        subjects: [subject2],
        actualSessions: actualSessions,
        hypotheticalSessions: hypo,
      );

      expect(projection.projectedSummary.totalPresent, equals(10));
      expect(projection.projectedSummary.totalConducted, equals(11));
      expect(
        projection.projectedSummary.overallPercentage,
        closeTo(90.91, 0.01),
      );
    });
  });

  group('ScenarioCalculator - Component Average (50/50) projections', () {
    test('Calculates independent Lecture and Lab 50/50 averaging', () {
      // Lecture: 36/40 = 90%, Lab: 6/10 = 60% -> Average = 75%
      final actualSessions = [
        ...createSessions(
          subjectId: 10,
          component: SessionComponent.lecture,
          present: 36,
          absent: 4,
        ),
        ...createSessions(
          subjectId: 10,
          component: SessionComponent.lab,
          present: 6,
          absent: 4,
        ),
      ];

      // Add 2 Lab Presents -> Lab becomes 8/12 = 66.67%
      // Average: (90 + 66.667) / 2 = 78.33%
      final hypo = [
        const HypotheticalSession(
          id: 'h1',
          subjectId: 10,
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
        ),
        const HypotheticalSession(
          id: 'h2',
          subjectId: 10,
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
        ),
      ];

      final projection = calculator.calculateProjection(
        semester: testSemesterAvg,
        subjects: [subject1],
        actualSessions: actualSessions,
        hypotheticalSessions: hypo,
      );

      expect(projection.baselineSummary.overallPercentage, equals(75.0));
      expect(
        projection.projectedSummary.overallPercentage,
        closeTo(78.333, 0.01),
      );
      expect(projection.percentageDifference, closeTo(3.333, 0.01));
    });

    test('Both components enabled with only one having sessions remains provisional unless simulated', () {
      // Lecture has sessions (10/10), Lab has 0
      final actualSessions = createSessions(
        subjectId: 10,
        component: SessionComponent.lecture,
        present: 10,
        absent: 0,
      );

      // Baseline: Provisional (Lab has no sessions)
      final baselineProj = calculator.calculateProjection(
        semester: testSemesterAvg,
        subjects: [subject1],
        actualSessions: actualSessions,
        hypotheticalSessions: const [],
      );

      expect(baselineProj.baselineSummary.isProvisional, isTrue);
      expect(baselineProj.baselineSummary.meetsThreshold, isFalse);

      // Add 1 hypothetical Lab session -> Now both components have sessions!
      final hypo = [
        const HypotheticalSession(
          id: 'h1',
          subjectId: 10,
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
        ),
      ];

      final projection = calculator.calculateProjection(
        semester: testSemesterAvg,
        subjects: [subject1],
        actualSessions: actualSessions,
        hypotheticalSessions: hypo,
      );

      // Lecture: 100%, Lab: 1/1 = 100% -> Combined = 100%
      expect(projection.projectedSummary.isAvailable, isTrue);
      expect(projection.projectedSummary.overallPercentage, equals(100.0));
      expect(projection.projectedMeetsThreshold, isTrue);
    });

    test('Both components enabled with one having no sessions (even after simulation) remains provisional', () {
      final actualSessions = createSessions(
        subjectId: 10,
        component: SessionComponent.lecture,
        present: 5,
        absent: 0,
      );

      // Add only more Lecture sessions
      final hypo = [
        const HypotheticalSession(
          id: 'h1',
          subjectId: 10,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        ),
      ];

      final projection = calculator.calculateProjection(
        semester: testSemesterAvg,
        subjects: [subject1],
        actualSessions: actualSessions,
        hypotheticalSessions: hypo,
      );

      expect(projection.projectedSummary.isProvisional, isTrue);
      expect(projection.projectedSummary.isAvailable, isFalse);
      expect(projection.projectedSummary.overallPercentage, equals(100.0));
      expect(projection.projectedMeetsThreshold, isFalse);
    });
  });
}
