import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/features/attendance/data/repositories/day_note_repository_impl.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DayNoteRepositoryImpl repo;
  late int semesterId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DayNoteRepositoryImpl(db);

    final semRepo = SemesterRepositoryImpl(db);
    semesterId = await semRepo.createSemester(name: 'Fall 2026');
  });

  tearDown(() async {
    await db.close();
  });

  group('DayNoteRepository Tests', () {
    test('saves and retrieves a day note', () async {
      await repo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-10',
        content: 'Sports Day - all lectures cancelled',
      );

      final note = await repo.getNoteForDate(semesterId, '2026-03-10');
      expect(note, isNotNull);
      expect(note!.semesterId, equals(semesterId));
      expect(note.date, equals('2026-03-10'));
      expect(note.content, equals('Sports Day - all lectures cancelled'));
    });

    test('updates existing day note when saved again for same date', () async {
      await repo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-10',
        content: 'Initial note',
      );

      await repo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-10',
        content: 'Updated: College fest day 1',
      );

      final note = await repo.getNoteForDate(semesterId, '2026-03-10');
      expect(note, isNotNull);
      expect(note!.content, equals('Updated: College fest day 1'));
    });

    test('deletes day note when content is empty or whitespace', () async {
      await repo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-10',
        content: 'Temporary note',
      );

      expect(await repo.getNoteForDate(semesterId, '2026-03-10'), isNotNull);

      // Save empty
      await repo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-10',
        content: '   ',
      );

      expect(await repo.getNoteForDate(semesterId, '2026-03-10'), isNull);
    });

    test('deletes day note explicitly via deleteNoteForDate', () async {
      await repo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-10',
        content: 'Medical leave',
      );

      expect(await repo.getNoteForDate(semesterId, '2026-03-10'), isNotNull);

      await repo.deleteNoteForDate(semesterId: semesterId, date: '2026-03-10');

      expect(await repo.getNoteForDate(semesterId, '2026-03-10'), isNull);
    });

    test('watches day notes for a month', () async {
      await repo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-05',
        content: 'Rain holiday',
      );
      await repo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-20',
        content: 'Workshop',
      );
      await repo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-04-01',
        content: 'Next month note',
      );

      final notesList = await repo
          .watchNotesForMonth(semesterId, '2026-03')
          .first;

      expect(notesList.length, equals(2));
      final notesMap = {for (final n in notesList) n.date: n.content};
      expect(notesMap['2026-03-05'], equals('Rain holiday'));
      expect(notesMap['2026-03-20'], equals('Workshop'));
      expect(notesMap.containsKey('2026-04-01'), isFalse);
    });

    test('watches day note for a specific date reactively', () async {
      final stream = repo.watchNoteForDate(semesterId, '2026-03-15');

      expect(await stream.first, isNull);

      await repo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-15',
        content: 'Guest lecture',
      );

      final updated = await stream.first;
      expect(updated, isNotNull);
      expect(updated!.content, equals('Guest lecture'));
    });

    test('throws ValidationFailure when setting a note for a future date', () async {
      expect(
        () => repo.setNoteForDate(
          semesterId: semesterId,
          date: '2099-01-01',
          content: 'Cannot take notes for future',
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
