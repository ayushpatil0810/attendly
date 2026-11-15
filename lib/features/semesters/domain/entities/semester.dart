import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';

class Semester {
  const Semester({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.attendanceThreshold = 0.75,
    this.calculationMethod = AttendanceCalculationMethod.rawCombined,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final double attendanceThreshold; // e.g. 0.75
  final AttendanceCalculationMethod calculationMethod;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get thresholdPercent => (attendanceThreshold * 100).round();

  Semester copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    double? attendanceThreshold,
    AttendanceCalculationMethod? calculationMethod,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Semester(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      attendanceThreshold: attendanceThreshold ?? this.attendanceThreshold,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Semester &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          attendanceThreshold == other.attendanceThreshold &&
          calculationMethod == other.calculationMethod &&
          isArchived == other.isArchived;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      attendanceThreshold.hashCode ^
      calculationMethod.hashCode ^
      isArchived.hashCode;
}
