import 'package:drift/drift.dart';

import 'semesters_table.dart';

@DataClassName('DayNoteRow')
class DayNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId => integer()
      .named('semester_id')
      .references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text().named('date')(); // ISO YYYY-MM-DD
  TextColumn get content => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  List<String> get customConstraints => [
    'UNIQUE(semester_id, date)',
    'CHECK (length(date) = 10)',
    'CHECK (length(trim(content)) > 0)',
  ];
}
