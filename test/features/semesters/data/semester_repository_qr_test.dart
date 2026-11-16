import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/semesters/domain/entities/semester_qr_payload.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

void main() {
  late AppDatabase db;
  late SemesterRepositoryImpl semRepo;
  late SubjectRepositoryImpl subjRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    semRepo = SemesterRepositoryImpl(db);
    subjRepo = SubjectRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SemesterRepository QR Export & Import Tests', () {
    test('exportSemesterPayload retrieves semester metadata and all associated subjects', () async {
      final semId = await semRepo.createSemester(
        name: 'Spring 2026',
        attendanceThreshold: 0.80,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      await subjRepo.createSubject(
        semesterId: semId,
        name: 'Algorithms',
        lectureEnabled: true,
        labEnabled: true,
        sortOrder: 0,
      );
      await subjRepo.createSubject(
        semesterId: semId,
        name: 'Ethics in Tech',
        lectureEnabled: true,
        labEnabled: false,
        sortOrder: 1,
      );

      final payload = await semRepo.exportSemesterPayload(semId);

      expect(payload.semesterName, equals('Spring 2026'));
      expect(payload.attendanceThreshold, equals(0.80));
      expect(payload.calculationMethod, equals(AttendanceCalculationMethod.componentAverage));
      expect(payload.subjects.length, equals(2));
      expect(payload.subjects[0].name, equals('Algorithms'));
      expect(payload.subjects[0].lectureEnabled, isTrue);
      expect(payload.subjects[0].labEnabled, isTrue);
      expect(payload.subjects[1].name, equals('Ethics in Tech'));
      expect(payload.subjects[1].labEnabled, isFalse);
    });

    test('importSemesterPayload inserts semester and creates all subjects in SQLite', () async {
      const payload = SemesterQrPayload(
        semesterName: 'Fall 2026',
        attendanceThreshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
        subjects: [
          SubjectQrPayload(name: 'Database Systems', lectureEnabled: true, labEnabled: true),
          SubjectQrPayload(name: 'Web Engineering', lectureEnabled: true, labEnabled: false),
        ],
      );

      final importedId = await semRepo.importSemesterPayload(payload);
      expect(importedId, greaterThan(0));

      final importedSem = await semRepo.getSemesterById(importedId);
      expect(importedSem, isNotNull);
      expect(importedSem!.name, equals('Fall 2026'));
      expect(importedSem.attendanceThreshold, equals(0.75));
      expect(importedSem.calculationMethod, equals(AttendanceCalculationMethod.rawCombined));

      final subjects = await subjRepo.getSubjectsForSemester(importedId);
      expect(subjects.length, equals(2));
      expect(subjects[0].name, equals('Database Systems'));
      expect(subjects[0].hasBothComponents, isTrue);
      expect(subjects[1].name, equals('Web Engineering'));
      expect(subjects[1].labEnabled, isFalse);
    });

    test('importSemesterPayload resolves duplicate name by appending (Imported)', () async {
      await semRepo.createSemester(name: 'Fall 2026');

      const payload = SemesterQrPayload(
        semesterName: 'Fall 2026',
        attendanceThreshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
        subjects: [
          SubjectQrPayload(name: 'Networks', lectureEnabled: true, labEnabled: false),
        ],
      );

      final importedId = await semRepo.importSemesterPayload(payload, replaceExisting: false);
      final importedSem = await semRepo.getSemesterById(importedId);

      expect(importedSem!.name, equals('Fall 2026 (Imported)'));

      // If imported again, appends counter
      final secondImportId = await semRepo.importSemesterPayload(payload, replaceExisting: false);
      final secondSem = await semRepo.getSemesterById(secondImportId);
      expect(secondSem!.name, equals('Fall 2026 (Imported 2)'));
    });

    test('importSemesterPayload replaces existing semester when replaceExisting is true', () async {
      final initialId = await semRepo.createSemester(name: 'Fall 2026', attendanceThreshold: 0.75);
      await subjRepo.createSubject(semesterId: initialId, name: 'Old Subject');

      const payload = SemesterQrPayload(
        semesterName: 'Fall 2026',
        attendanceThreshold: 0.85,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
        subjects: [
          SubjectQrPayload(name: 'New Subject', lectureEnabled: true, labEnabled: true),
        ],
      );

      final replacedId = await semRepo.importSemesterPayload(payload, replaceExisting: true);

      // Old semester was deleted
      expect(await semRepo.getSemesterById(initialId), isNull);

      final replacedSem = await semRepo.getSemesterById(replacedId);
      expect(replacedSem!.name, equals('Fall 2026'));
      expect(replacedSem.attendanceThreshold, equals(0.85));

      final subjects = await subjRepo.getSubjectsForSemester(replacedId);
      expect(subjects.length, equals(1));
      expect(subjects.first.name, equals('New Subject'));
    });

    test('importSemesterPayload honors customName when provided', () async {
      const payload = SemesterQrPayload(
        semesterName: 'Fall 2026',
        attendanceThreshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
        subjects: [
          SubjectQrPayload(name: 'Math', lectureEnabled: true, labEnabled: false),
        ],
      );

      final importedId = await semRepo.importSemesterPayload(payload, customName: 'My Custom Term');
      final importedSem = await semRepo.getSemesterById(importedId);

      expect(importedSem!.name, equals('My Custom Term'));
    });
  });
}
