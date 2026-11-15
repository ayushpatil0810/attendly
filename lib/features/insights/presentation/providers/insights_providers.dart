import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/features/attendance/domain/entities/insight_observation.dart';
import 'package:attendly/features/attendance/domain/entities/insights_filter.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/services/insight_observation_generator.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

class InsightsFilterNotifier extends Notifier<InsightsFilter> {
  @override
  InsightsFilter build() => const InsightsFilter();

  void setDateRange(
    DateRangeType type, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    state = state.copyWith(
      dateRangeType: type,
      customStartDate: customStart,
      customEndDate: customEnd,
    );
  }

  void setSubject(int? subjectId) {
    state = state.copyWith(subjectId: () => subjectId);
  }

  void setComponent(SessionComponent? component) {
    state = state.copyWith(component: () => component);
  }

  void reset() {
    state = const InsightsFilter();
  }
}

final insightsFilterProvider =
    NotifierProvider<InsightsFilterNotifier, InsightsFilter>(
      InsightsFilterNotifier.new,
    );

final insightObservationGeneratorProvider =
    Provider<InsightObservationGenerator>((ref) {
      return const InsightObservationGenerator();
    });

/// Reactive provider yielding the filtered attendance summary for Insights.
///
/// Applies date-range, subject, and component filters consistently to all analytics.
final filteredSemesterAttendanceSummaryProvider =
    Provider<AsyncValue<SemesterAttendanceSummary?>>((ref) {
      final activeSemester = ref.watch(activeSemesterProvider);
      if (activeSemester == null) {
        return const AsyncData(null);
      }

      final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
      final sessionsAsync = ref.watch(activeSemesterSessionsStreamProvider);
      final filter = ref.watch(insightsFilterProvider);

      if (subjectsAsync.isLoading || sessionsAsync.isLoading) {
        return const AsyncLoading();
      }

      if (subjectsAsync.hasError) {
        return AsyncError(
          subjectsAsync.error!,
          subjectsAsync.stackTrace ?? StackTrace.current,
        );
      }

      if (sessionsAsync.hasError) {
        return AsyncError(
          sessionsAsync.error!,
          sessionsAsync.stackTrace ?? StackTrace.current,
        );
      }

      final allSubjects = subjectsAsync.value ?? [];
      final allSessions = sessionsAsync.value ?? [];
      final calculator = ref.watch(attendanceCalculatorProvider);

      // Apply filter to sessions
      final filteredSessions = filter.filterSessions(allSessions);

      // If a specific subject is selected, filter subjects list accordingly
      final subjectsToCalculate = filter.subjectId != null
          ? allSubjects.where((s) => s.id == filter.subjectId).toList()
          : allSubjects;

      final summary = calculator.calculateSemester(
        semester: activeSemester,
        subjects: subjectsToCalculate,
        sessions: filteredSessions,
      );

      return AsyncData(summary);
    });

/// Reactive provider that derives factual observations from the current filtered summary.
final insightObservationsProvider = Provider<List<InsightObservation>>((ref) {
  final summaryAsync = ref.watch(filteredSemesterAttendanceSummaryProvider);
  final summary = summaryAsync.asData?.value;
  if (summary == null) return const [];

  final generator = ref.watch(insightObservationGeneratorProvider);
  return generator.generateObservations(summary);
});
