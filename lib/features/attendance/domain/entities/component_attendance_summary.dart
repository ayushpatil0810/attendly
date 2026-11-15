import 'attendance_availability.dart';
import 'session_component.dart';

class ComponentAttendanceSummary {
  const ComponentAttendanceSummary({
    required this.component,
    required this.presentCount,
    required this.absentCount,
    required this.conductedCount,
    this.percentage,
    required this.availability,
    required this.isEnabled,
  });

  final SessionComponent component;
  final int presentCount;
  final int absentCount;
  final int conductedCount;
  final double? percentage;
  final AttendanceAvailability availability;
  final bool isEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentAttendanceSummary &&
          runtimeType == other.runtimeType &&
          component == other.component &&
          presentCount == other.presentCount &&
          absentCount == other.absentCount &&
          conductedCount == other.conductedCount &&
          percentage == other.percentage &&
          availability == other.availability &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode =>
      component.hashCode ^
      presentCount.hashCode ^
      absentCount.hashCode ^
      conductedCount.hashCode ^
      percentage.hashCode ^
      availability.hashCode ^
      isEnabled.hashCode;
}
