import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/insights_filter.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';

void main() {
  final now = DateTime(2026, 11, 15);

  final session1 = AttendanceSession(
    id: 1,
    subjectId: 10,
    sessionDate: '2026-11-14', // yesterday (within 7 days)
    component: SessionComponent.lecture,
    status: AttendanceStatus.present,
    createdAt: DateTime(2026, 11, 14),
    updatedAt: DateTime(2026, 11, 14),
  );

  final session2 = AttendanceSession(
    id: 2,
    subjectId: 10,
    sessionDate: '2026-11-01', // 14 days ago (within 30 days, not 7 days)
    component: SessionComponent.lab,
    status: AttendanceStatus.present,
    createdAt: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 11, 1),
  );

  final session3 = AttendanceSession(
    id: 3,
    subjectId: 20,
    sessionDate: '2026-09-01', // 75 days ago (outside 30 days)
    component: SessionComponent.lecture,
    status: AttendanceStatus.absent,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  final allSessions = [session1, session2, session3];

  group('InsightsFilter', () {
    test('Default filter matches all sessions', () {
      const filter = InsightsFilter();
      expect(filter.isDefault, isTrue);

      final filtered = filter.filterSessions(allSessions, now: now);
      expect(filtered.length, equals(3));
    });

    test('Subject filter matches only target subject', () {
      final filter = const InsightsFilter().copyWith(subjectId: () => 10);
      expect(filter.isDefault, isFalse);

      final filtered = filter.filterSessions(allSessions, now: now);
      expect(filtered.length, equals(2));
      expect(filtered.every((s) => s.subjectId == 10), isTrue);
    });

    test('Component filter matches only target component', () {
      final filter = const InsightsFilter().copyWith(
        component: () => SessionComponent.lab,
      );

      final filtered = filter.filterSessions(allSessions, now: now);
      expect(filtered.length, equals(1));
      expect(filtered.first.component, equals(SessionComponent.lab));
    });

    test('Last 7 Days filter selects only sessions within 7 days', () {
      final filter = const InsightsFilter(
        dateRangeType: DateRangeType.last7Days,
      );

      final filtered = filter.filterSessions(allSessions, now: now);
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals(1));
    });

    test('Last 30 Days filter selects only sessions within 30 days', () {
      final filter = const InsightsFilter(
        dateRangeType: DateRangeType.last30Days,
      );

      final filtered = filter.filterSessions(allSessions, now: now);
      expect(filtered.length, equals(2));
      expect(filtered.map((s) => s.id), containsAll([1, 2]));
    });

    test('Custom Date Range selects sessions strictly within range', () {
      final filter = InsightsFilter(
        dateRangeType: DateRangeType.custom,
        customStartDate: DateTime(2026, 10, 15),
        customEndDate: DateTime(2026, 11, 10),
      );

      final filtered = filter.filterSessions(allSessions, now: now);
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals(2)); // Nov 1 is within Oct 15 - Nov 10
    });
  });
}
