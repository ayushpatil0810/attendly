import 'package:drift/drift.dart';

@DataClassName('SemesterRow')
class Semesters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get startDate => text().named('start_date').nullable()();
  TextColumn get endDate => text().named('end_date').nullable()();
  RealColumn get attendanceThreshold =>
      real().named('attendance_threshold').withDefault(const Constant(0.75))();
  TextColumn get calculationMethod => text()
      .named('calculation_method')
      .withDefault(const Constant('raw_combined'))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  BoolColumn get isArchived =>
      boolean().named('is_archived').withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(name)) > 0)',
    'CHECK (attendance_threshold > 0.0 AND attendance_threshold <= 1.0)',
    "CHECK (calculation_method IN ('raw_combined', 'component_average'))",
    'CHECK (is_archived IN (0, 1))',
  ];
}
