import '../entities/day_note.dart';

abstract class DayNoteRepository {
  Stream<DayNote?> watchNoteForDate(int semesterId, String date);
  Future<DayNote?> getNoteForDate(int semesterId, String date);
  Stream<List<DayNote>> watchNotesForMonth(
    int semesterId,
    String yearMonthPrefix,
  );
  Future<List<DayNote>> getNotesForMonth(
    int semesterId,
    String yearMonthPrefix,
  );
  Future<void> setNoteForDate({
    required int semesterId,
    required String date,
    required String content,
  });
  Future<void> deleteNoteForDate({
    required int semesterId,
    required String date,
  });
}
