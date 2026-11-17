import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';

void main() {
  late AppDatabase db;
  late SemesterRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SemesterRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SemesterRepository', () {
    test('creates and retrieves semester', () async {
      final id = await repo.createSemester(
        name: 'Semester 1',
        attendanceThreshold: 0.8,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      final semester = await repo.getSemesterById(id);
      expect(semester, isNotNull);
      expect(semester!.name, equals('Semester 1'));
      expect(semester.attendanceThreshold, equals(0.8));
      expect(
        semester.calculationMethod,
        equals(AttendanceCalculationMethod.componentAverage),
      );
      expect(semester.isArchived, isFalse);
    });

    test('validates blank name on create and update', () async {
      expect(
        () => repo.createSemester(name: '   '),
        throwsA(isA<ValidationFailure>()),
      );

      final id = await repo.createSemester(name: 'Valid');
      final sem = (await repo.getSemesterById(id))!;

      expect(
        () => repo.updateSemester(sem.copyWith(name: '   ')),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('validates threshold boundaries', () async {
      expect(
        () => repo.createSemester(name: 'Sem', attendanceThreshold: 0.0),
        throwsA(isA<ValidationFailure>()),
      );

      expect(
        () => repo.createSemester(name: 'Sem', attendanceThreshold: 1.1),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('validates start date after end date', () async {
      expect(
        () => repo.createSemester(
          name: 'Sem',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 5, 1),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('archives and unarchives semester', () async {
      final id = await repo.createSemester(name: 'Sem Archive');

      await repo.archiveSemester(id, isArchived: true);
      var sem = await repo.getSemesterById(id);
      expect(sem!.isArchived, isTrue);

      var active = await repo.getSemesters(includeArchived: false);
      expect(active, isEmpty);

      var all = await repo.getSemesters(includeArchived: true);
      expect(all.length, equals(1));

      await repo.archiveSemester(id, isArchived: false);
      sem = await repo.getSemesterById(id);
      expect(sem!.isArchived, isFalse);
    });

    test('deletes semester', () async {
      final id = await repo.createSemester(name: 'To Delete');
      await repo.deleteSemester(id);

      final sem = await repo.getSemesterById(id);
      expect(sem, isNull);
    });

    test(
      'clears start and end dates via copyWith and updates successfully',
      () async {
        final id = await repo.createSemester(
          name: 'Dated Semester',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 5, 30),
        );

        var sem = (await repo.getSemesterById(id))!;
        expect(sem.startDate, isNotNull);
        expect(sem.endDate, isNotNull);

        // Clear both dates using clearStartDate and clearEndDate
        final cleared = sem.copyWith(clearStartDate: true, clearEndDate: true);
        expect(cleared.startDate, isNull);
        expect(cleared.endDate, isNull);

        await repo.updateSemester(cleared);

        final updated = (await repo.getSemesterById(id))!;
        expect(updated.startDate, isNull);
        expect(updated.endDate, isNull);
      },
    );

    test('clears start and end dates via copyWith and updates successfully', () async {
      final id = await repo.createSemester(
        name: 'Dated Semester',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 5, 30),
      );

      var sem = (await repo.getSemesterById(id))!;
      expect(sem.startDate, isNotNull);
      expect(sem.endDate, isNotNull);

      // Clear both dates using clearStartDate and clearEndDate
      final cleared = sem.copyWith(clearStartDate: true, clearEndDate: true);
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, isNull);

      await repo.updateSemester(cleared);

      final updated = (await repo.getSemesterById(id))!;
      expect(updated.startDate, isNull);
      expect(updated.endDate, isNull);
    });
  });
}
