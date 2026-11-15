import 'attendance_session.dart';
import 'session_component.dart';

enum DateRangeType {
  allTime('All Time'),
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days'),
  custom('Custom');

  const DateRangeType(this.label);
  final String label;
}

class InsightsFilter {
  const InsightsFilter({
    this.dateRangeType = DateRangeType.allTime,
    this.customStartDate,
    this.customEndDate,
    this.subjectId,
    this.component,
  });

  final DateRangeType dateRangeType;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final int? subjectId;
  final SessionComponent? component;

  bool get isDefault =>
      dateRangeType == DateRangeType.allTime &&
      subjectId == null &&
      component == null;

  InsightsFilter copyWith({
    DateRangeType? dateRangeType,
    DateTime? customStartDate,
    DateTime? customEndDate,
    int? Function()? subjectId,
    SessionComponent? Function()? component,
  }) {
    return InsightsFilter(
      dateRangeType: dateRangeType ?? this.dateRangeType,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      subjectId: subjectId != null ? subjectId() : this.subjectId,
      component: component != null ? component() : this.component,
    );
  }

  /// Determines whether a session satisfies this filter.
  bool matches(AttendanceSession session, {DateTime? now}) {
    // Subject filter
    if (subjectId != null && session.subjectId != subjectId) {
      return false;
    }

    // Component filter
    if (component != null && session.component != component) {
      return false;
    }

    // Date range filter
    if (dateRangeType == DateRangeType.allTime) {
      return true;
    }

    final sessionDate = _parseDateStr(session.sessionDate);
    final referenceDate = now ?? DateTime.now();
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );

    switch (dateRangeType) {
      case DateRangeType.allTime:
        return true;
      case DateRangeType.last7Days:
        final sevenDaysAgo = today.subtract(const Duration(days: 6));
        return !sessionDate.isBefore(sevenDaysAgo) &&
            !sessionDate.isAfter(today);
      case DateRangeType.last30Days:
        final thirtyDaysAgo = today.subtract(const Duration(days: 29));
        return !sessionDate.isBefore(thirtyDaysAgo) &&
            !sessionDate.isAfter(today);
      case DateRangeType.custom:
        if (customStartDate != null) {
          final start = DateTime(
            customStartDate!.year,
            customStartDate!.month,
            customStartDate!.day,
          );
          if (sessionDate.isBefore(start)) return false;
        }
        if (customEndDate != null) {
          final end = DateTime(
            customEndDate!.year,
            customEndDate!.month,
            customEndDate!.day,
          );
          if (sessionDate.isAfter(end)) return false;
        }
        return true;
    }
  }

  /// Filters a list of attendance sessions according to this filter.
  List<AttendanceSession> filterSessions(
    List<AttendanceSession> sessions, {
    DateTime? now,
  }) {
    if (isDefault) return sessions;
    return sessions.where((s) => matches(s, now: now)).toList();
  }

  static DateTime _parseDateStr(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightsFilter &&
          runtimeType == other.runtimeType &&
          dateRangeType == other.dateRangeType &&
          customStartDate == other.customStartDate &&
          customEndDate == other.customEndDate &&
          subjectId == other.subjectId &&
          component == other.component;

  @override
  int get hashCode => Object.hash(
    dateRangeType,
    customStartDate,
    customEndDate,
    subjectId,
    component,
  );
}
