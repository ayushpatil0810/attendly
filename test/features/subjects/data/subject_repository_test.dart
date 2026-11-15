import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

void main() {
  late AppDatabase db;
  late SemesterRepositoryImpl semesterRepo;
  late SubjectRepositoryImpl subjectRepo;
  late int semesterId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    semesterRepo = SemesterRepositoryImpl(db);
    subjectRepo = SubjectRepositoryImpl(db);
    semesterId = await semesterRepo.createSemester(name: 'Active Semester');
  });

  tearDown(() async {
    await db.close();
  });

  group('SubjectRepository', () {
    test('creates and retrieves subjects for semester', () async {
      final sub1 = await subjectRepo.createSubject(
        semesterId: semesterId,
        name: 'Operating Systems',
        lectureEnabled: true,
        labEnabled: true,
      );

      final sub2 = await subjectRepo.createSubject(
        semesterId: semesterId,
        name: 'Mathematics',
        lectureEnabled: true,
        labEnabled: false,
      );

      final list = await subjectRepo.getSubjectsForSemester(semesterId);
      expect(list.length, equals(2));
      expect(list.any((s) => s.id == sub1 && s.hasBothComponents), isTrue);
      expect(list.any((s) => s.id == sub2 && !s.labEnabled), isTrue);
    });

    test('rejects subject with blank name', () async {
      expect(
        () => subjectRepo.createSubject(semesterId: semesterId, name: '   '),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects subject with both components disabled', () async {
      expect(
        () => subjectRepo.createSubject(
          semesterId: semesterId,
          name: 'Invalid Subject',
          lectureEnabled: false,
          labEnabled: false,
        ),
        throwsA(isA<ValidationFailure>()),
      );

      final id = await subjectRepo.createSubject(
        semesterId: semesterId,
        name: 'Valid Subject',
      );

      final subject = (await subjectRepo.getSubjectById(id))!;
      expect(
        () => subjectRepo.updateSubject(
          subject.copyWith(lectureEnabled: false, labEnabled: false),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('updates and deletes subject', () async {
      final id = await subjectRepo.createSubject(
        semesterId: semesterId,
        name: 'Original Name',
      );

      var subject = (await subjectRepo.getSubjectById(id))!;
      await subjectRepo.updateSubject(
        subject.copyWith(name: 'Updated Name', labEnabled: true),
      );

      subject = (await subjectRepo.getSubjectById(id))!;
      expect(subject.name, equals('Updated Name'));
      expect(subject.labEnabled, isTrue);

      await subjectRepo.deleteSubject(id);
      expect(await subjectRepo.getSubjectById(id), isNull);
    });
  });
}
