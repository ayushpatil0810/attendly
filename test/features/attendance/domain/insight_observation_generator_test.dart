import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/insight_observation.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/services/attendance_calculator.dart';
import 'package:attendly/features/attendance/domain/services/insight_observation_generator.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';

void main() {
  const generator = InsightObservationGenerator();
  const calculator = AttendanceCalculator();

  final semester = Semester(
    id: 1,
    name: 'Fall 2026',
    attendanceThreshold: 0.75,
    calculationMethod: AttendanceCalculationMethod.rawCombined,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
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

  group('InsightObservationGenerator', () {
    test('Returns empty observations when fewer than 3 sessions conducted', () {
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
      ];

      final summary = calculator.calculateSemester(
        semester: semester,
        subjects: [subject1],
        sessions: sessions,
      );

      final observations = generator.generateObservations(summary);
      expect(observations, isEmpty);
    });

    test(
      'Generates positive target and safe absence observation when on track',
      () {
        // 8 Present / 10 Conducted = 80% (meets 75% target, 6 safe absences in 80/100, but in 8/10: 8/0.75 - 10 = 0.66 -> 0 safe absences. Let's do 9/10: 9/0.75 - 10 = 2 safe absences)
        final sessions = <AttendanceSession>[];
        for (var i = 0; i < 9; i++) {
          sessions.add(
            AttendanceSession(
              id: i + 1,
              subjectId: 10,
              sessionDate: '2026-09-0${(i % 5) + 1}',
              component: SessionComponent.lecture,
              status: AttendanceStatus.present,
              createdAt: DateTime(2026, 9, 1),
              updatedAt: DateTime(2026, 9, 1),
            ),
          );
        }
        sessions.add(
          AttendanceSession(
            id: 10,
            subjectId: 10,
            sessionDate: '2026-09-05',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            createdAt: DateTime(2026, 9, 5),
            updatedAt: DateTime(2026, 9, 5),
          ),
        );

        final summary = calculator.calculateSemester(
          semester: semester,
          subjects: [subject1],
          sessions: sessions,
        );

        final observations = generator.generateObservations(summary);
        expect(observations, isNotEmpty);
        expect(
          observations.any(
            (o) =>
                o.title == 'Meeting Attendance Target' &&
                o.type == InsightObservationType.positive,
          ),
          isTrue,
        );
        expect(
          observations.any(
            (o) =>
                o.title == 'Safe Absence Allowance' &&
                o.type == InsightObservationType.info,
          ),
          isTrue,
        );
      },
    );

    test('Generates below target warning and recovery observation', () {
      // 6 Present / 10 Conducted = 60%
      final sessions = <AttendanceSession>[];
      for (var i = 0; i < 6; i++) {
        sessions.add(
          AttendanceSession(
            id: i + 1,
            subjectId: 10,
            sessionDate: '2026-09-0${(i % 5) + 1}',
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
            createdAt: DateTime(2026, 9, 1),
            updatedAt: DateTime(2026, 9, 1),
          ),
        );
      }
      for (var i = 0; i < 4; i++) {
        sessions.add(
          AttendanceSession(
            id: i + 7,
            subjectId: 10,
            sessionDate: '2026-09-0${(i % 5) + 1}',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            createdAt: DateTime(2026, 9, 2),
            updatedAt: DateTime(2026, 9, 2),
          ),
        );
      }

      final summary = calculator.calculateSemester(
        semester: semester,
        subjects: [subject1],
        sessions: sessions,
      );

      final observations = generator.generateObservations(summary);
      expect(
        observations.any(
          (o) =>
              o.title == 'Below Attendance Target' &&
              o.type == InsightObservationType.warning,
        ),
        isTrue,
      );
      expect(
        observations.any(
          (o) =>
              o.title == 'Recovery Requirement' &&
              o.type == InsightObservationType.warning,
        ),
        isTrue,
      );
      expect(
        observations.any((o) => o.title == 'Subject Below Threshold'),
        isTrue,
      );
    });

    test(
      'Generates component imbalance observation for Lecture vs Lab gap',
      () {
        // Networks: Lecture 2/4 = 50%, Lab 4/4 = 100% -> Difference = 50%
        final sessions = [
          // 2 Present, 2 Absent Lecture
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
            component: SessionComponent.lecture,
            status: AttendanceStatus.present,
            createdAt: DateTime(2026, 9, 2),
            updatedAt: DateTime(2026, 9, 2),
          ),
          AttendanceSession(
            id: 3,
            subjectId: 10,
            sessionDate: '2026-09-03',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            createdAt: DateTime(2026, 9, 3),
            updatedAt: DateTime(2026, 9, 3),
          ),
          AttendanceSession(
            id: 4,
            subjectId: 10,
            sessionDate: '2026-09-04',
            component: SessionComponent.lecture,
            status: AttendanceStatus.absent,
            createdAt: DateTime(2026, 9, 4),
            updatedAt: DateTime(2026, 9, 4),
          ),
          // 4 Present Lab
          AttendanceSession(
            id: 5,
            subjectId: 10,
            sessionDate: '2026-09-05',
            component: SessionComponent.lab,
            status: AttendanceStatus.present,
            createdAt: DateTime(2026, 9, 5),
            updatedAt: DateTime(2026, 9, 5),
          ),
          AttendanceSession(
            id: 6,
            subjectId: 10,
            sessionDate: '2026-09-06',
            component: SessionComponent.lab,
            status: AttendanceStatus.present,
            createdAt: DateTime(2026, 9, 6),
            updatedAt: DateTime(2026, 9, 6),
          ),
          AttendanceSession(
            id: 7,
            subjectId: 10,
            sessionDate: '2026-09-07',
            component: SessionComponent.lab,
            status: AttendanceStatus.present,
            createdAt: DateTime(2026, 9, 7),
            updatedAt: DateTime(2026, 9, 7),
          ),
          AttendanceSession(
            id: 8,
            subjectId: 10,
            sessionDate: '2026-09-08',
            component: SessionComponent.lab,
            status: AttendanceStatus.present,
            createdAt: DateTime(2026, 9, 8),
            updatedAt: DateTime(2026, 9, 8),
          ),
        ];

        final summary = calculator.calculateSemester(
          semester: semester,
          subjects: [subject1],
          sessions: sessions,
        );

        final observations = generator.generateObservations(summary);
        expect(
          observations.any(
            (o) =>
                o.title.contains('Component Imbalance in Networks') &&
                o.type == InsightObservationType.neutral,
          ),
          isTrue,
        );
      },
    );
  });
}
