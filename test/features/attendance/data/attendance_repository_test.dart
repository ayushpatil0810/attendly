import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

void main() {
  late AppDatabase db;
  late AttendanceRepositoryImpl repo;
  late int semesterId;
  late int subjectBothId;
  late int subjectLectureOnlyId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AttendanceRepositoryImpl(db);

    final semRepo = SemesterRepositoryImpl(db);
    semesterId = await semRepo.createSemester(name: 'Fall 2026');

    final subjRepo = SubjectRepositoryImpl(db);
    subjectBothId = await subjRepo.createSubject(
      semesterId: semesterId,
      name: 'Computer Networks',
      lectureEnabled: true,
      labEnabled: true,
    );

    subjectLectureOnlyId = await subjRepo.createSubject(
      semesterId: semesterId,
      name: 'Mathematics',
      lectureEnabled: true,
      labEnabled: false,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AttendanceRepository - Create Session', () {
    test('creates a Present session successfully', () async {
      final id = await repo.createSession(
        subjectId: subjectBothId,
        sessionDate: '2026-03-10',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
        note: 'Introductory class',
      );

      expect(id, greaterThan(0));

      final session = await repo.getSessionById(id);
      expect(session, isNotNull);
      expect(session!.subjectId, equals(subjectBothId));
      expect(session.sessionDate, equals('2026-03-10'));
      expect(session.component, equals(SessionComponent.lecture));
      expect(session.status, equals(AttendanceStatus.present));
      expect(session.note, equals('Introductory class'));
      expect(session.isPresent, isTrue);
      expect(session.isAbsent, isFalse);
    });

    test('creates an Absent session successfully', () async {
      final id = await repo.createSession(
        subjectId: subjectBothId,
        sessionDate: '2026-03-11',
        component: SessionComponent.lab,
        status: AttendanceStatus.absent,
      );

      expect(id, greaterThan(0));

      final session = await repo.getSessionById(id);
      expect(session, isNotNull);
      expect(session!.component, equals(SessionComponent.lab));
      expect(session.status, equals(AttendanceStatus.absent));
      expect(session.isPresent, isFalse);
      expect(session.isAbsent, isTrue);
    });

    test(
      'allows another lecture for the same subject on the same date',
      () async {
        final firstId = await repo.createSession(
          subjectId: subjectBothId,
          sessionDate: '2026-03-10',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        final secondId = await repo.createSession(
          subjectId: subjectBothId,
          sessionDate: '2026-03-10',
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );

        expect(secondId, isNot(equals(firstId)));
        final sessions = await repo.getSessionsForSubject(subjectBothId);
        final sameDay = sessions.where(
          (session) =>
              session.sessionDate == '2026-03-10' &&
              session.component == SessionComponent.lecture,
        );
        expect(sameDay.length, equals(2));
      },
    );

    test(
      'allows different component on the same date for the same subject',
      () async {
        final lecId = await repo.createSession(
          subjectId: subjectBothId,
          sessionDate: '2026-03-10',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        final labId = await repo.createSession(
          subjectId: subjectBothId,
          sessionDate: '2026-03-10',
          component: SessionComponent.lab,
          status: AttendanceStatus.absent,
        );

        expect(lecId, greaterThan(0));
        expect(labId, greaterThan(0));
        expect(lecId, isNot(equals(labId)));
      },
    );

    test('rejects session with future date', () async {
      final futureDate = DateTime.now().add(const Duration(days: 2));
      final futureDateStr =
          '${futureDate.year.toString().padLeft(4, '0')}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';

      expect(
        () async => await repo.createSession(
          subjectId: subjectBothId,
          sessionDate: futureDateStr,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (e) => e.message,
            'message',
            contains('future dates'),
          ),
        ),
      );
    });

    test('rejects session when component is disabled on subject', () async {
      expect(
        () async => await repo.createSession(
          subjectId: subjectLectureOnlyId,
          sessionDate: '2026-03-10',
          component: SessionComponent.lab,
          status: AttendanceStatus.present,
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (e) => e.message,
            'message',
            contains('not enabled'),
          ),
        ),
      );
    });

    test('rejects session for non-existent subject', () async {
      expect(
        () async => await repo.createSession(
          subjectId: 99999,
          sessionDate: '2026-03-10',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('AttendanceRepository - Read Queries', () {
    setUp(() async {
      await repo.createSession(
        subjectId: subjectBothId,
        sessionDate: '2026-03-10',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );
      await repo.createSession(
        subjectId: subjectBothId,
        sessionDate: '2026-03-10',
        component: SessionComponent.lab,
        status: AttendanceStatus.absent,
      );
      await repo.createSession(
        subjectId: subjectLectureOnlyId,
        sessionDate: '2026-03-15',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );
    });

    test('retrieves sessions by date', () async {
      final sessions = await repo.getSessionsForDate(semesterId, '2026-03-10');
      expect(sessions.length, equals(2));

      final emptyDate = await repo.getSessionsForDate(semesterId, '2026-03-11');
      expect(emptyDate, isEmpty);
    });

    test('retrieves sessions by subject', () async {
      final sessions = await repo.getSessionsForSubject(subjectBothId);
      expect(sessions.length, equals(2));

      final mathSessions = await repo.getSessionsForSubject(
        subjectLectureOnlyId,
      );
      expect(mathSessions.length, equals(1));
    });

    test('watches sessions for month', () async {
      final monthStream = repo.watchSessionsForMonth(semesterId, 2026, 3);
      final list = await monthStream.first;
      expect(list.length, equals(3));
    });
  });

  group('AttendanceRepository - Update & Delete', () {
    test('updates session status from Absent to Present', () async {
      final id = await repo.createSession(
        subjectId: subjectBothId,
        sessionDate: '2026-03-10',
        component: SessionComponent.lecture,
        status: AttendanceStatus.absent,
      );

      final original = (await repo.getSessionById(id))!;
      expect(original.status, equals(AttendanceStatus.absent));

      final updated = original.copyWith(status: AttendanceStatus.present);
      await repo.updateSession(updated);

      final fetched = (await repo.getSessionById(id))!;
      expect(fetched.status, equals(AttendanceStatus.present));
    });

    test('updates session date to another valid past date', () async {
      final id = await repo.createSession(
        subjectId: subjectBothId,
        sessionDate: '2026-03-10',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      final original = (await repo.getSessionById(id))!;
      final updated = original.copyWith(sessionDate: '2026-03-09');
      await repo.updateSession(updated);

      final fetched = (await repo.getSessionById(id))!;
      expect(fetched.sessionDate, equals('2026-03-09'));
    });

    test(
      'allows an update onto a day that already has that component',
      () async {
        await repo.createSession(
          subjectId: subjectBothId,
          sessionDate: '2026-03-10',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        final id2 = await repo.createSession(
          subjectId: subjectBothId,
          sessionDate: '2026-03-11',
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );

        final session2 = (await repo.getSessionById(id2))!;
        final moved = session2.copyWith(sessionDate: '2026-03-10');
        await repo.updateSession(moved);

        final fetched = (await repo.getSessionById(id2))!;
        expect(fetched.sessionDate, equals('2026-03-10'));
      },
    );

    test('deletes a session and confirms it is removed', () async {
      final id = await repo.createSession(
        subjectId: subjectBothId,
        sessionDate: '2026-03-10',
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      expect(await repo.getSessionById(id), isNotNull);

      await repo.deleteSession(id);
      expect(await repo.getSessionById(id), isNull);

      final remaining = await repo.getSessionsForDate(semesterId, '2026-03-10');
      expect(remaining, isEmpty);
    });
  });
}
