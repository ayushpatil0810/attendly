import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';

enum DashboardAttendanceScope { overall, thisMonth }

class DashboardAttendanceScopeNotifier
    extends Notifier<DashboardAttendanceScope> {
  @override
  DashboardAttendanceScope build() => DashboardAttendanceScope.overall;

  void setScope(DashboardAttendanceScope scope) => state = scope;
}

final dashboardAttendanceScopeProvider = NotifierProvider<
  DashboardAttendanceScopeNotifier,
  DashboardAttendanceScope
>(DashboardAttendanceScopeNotifier.new);

final activeDashboardAttendanceSummaryProvider =
    Provider<AsyncValue<SemesterAttendanceSummary?>>((ref) {
      final scope = ref.watch(dashboardAttendanceScopeProvider);
      switch (scope) {
        case DashboardAttendanceScope.overall:
          return ref.watch(semesterAttendanceSummaryProvider);
        case DashboardAttendanceScope.thisMonth:
          return ref.watch(currentMonthAttendanceSummaryProvider);
      }
    });
