import 'package:drift/drift.dart';

import 'semesters_table.dart';

@DataClassName('SubjectRow')
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId => integer()
      .named('semester_id')
      .references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  BoolColumn get lectureEnabled =>
      boolean().named('lecture_enabled').withDefault(const Constant(true))();
  BoolColumn get labEnabled =>
      boolean().named('lab_enabled').withDefault(const Constant(false))();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(name)) > 0)',
    'CHECK (lecture_enabled = 1 OR lab_enabled = 1)',
  ];
}
