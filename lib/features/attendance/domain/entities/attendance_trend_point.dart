class AttendanceTrendPoint {
  const AttendanceTrendPoint({
    required this.date,
    required this.dateStr,
    required this.presentOnDate,
    required this.conductedOnDate,
    required this.cumulativePresent,
    required this.cumulativeConducted,
    required this.cumulativePercentage,
  });

  final DateTime date;
  final String dateStr;
  final int presentOnDate;
  final int conductedOnDate;
  final int cumulativePresent;
  final int cumulativeConducted;
  final double cumulativePercentage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceTrendPoint &&
          runtimeType == other.runtimeType &&
          dateStr == other.dateStr &&
          presentOnDate == other.presentOnDate &&
          conductedOnDate == other.conductedOnDate &&
          cumulativePresent == other.cumulativePresent &&
          cumulativeConducted == other.cumulativeConducted &&
          cumulativePercentage == other.cumulativePercentage;

  @override
  int get hashCode =>
      dateStr.hashCode ^
      presentOnDate.hashCode ^
      conductedOnDate.hashCode ^
      cumulativePresent.hashCode ^
      cumulativeConducted.hashCode ^
      cumulativePercentage.hashCode;
}
