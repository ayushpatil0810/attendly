import 'package:drift/drift.dart';

import 'subjects_table.dart';

@DataClassName('AttendanceSessionRow')
class AttendanceSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer()
      .named('subject_id')
      .references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get sessionDate =>
      text().named('session_date')(); // ISO YYYY-MM-DD
  TextColumn get component => text()(); // 'lecture' or 'lab'
  TextColumn get status => text()(); // 'present' or 'absent'
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  List<String> get customConstraints => [
    "CHECK (component IN ('lecture', 'lab'))",
    "CHECK (status IN ('present', 'absent'))",
    'CHECK (length(session_date) = 10)',
  ];
}
