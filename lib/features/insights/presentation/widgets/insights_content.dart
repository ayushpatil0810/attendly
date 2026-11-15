import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_empty_state.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_loading_state.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/presentation/widgets/quick_log_sheet.dart';
import 'package:attendly/features/insights/presentation/providers/insights_providers.dart';

import 'advanced_trend_card.dart';
import 'insight_observations_section.dart';
import 'insights_filter_bar.dart';
import 'insights_overview_card.dart';
import 'lecture_lab_comparison_card.dart';
import 'subject_comparison_card.dart';

class InsightsContent extends ConsumerWidget {
  const InsightsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(filteredSemesterAttendanceSummaryProvider);
    final observations = ref.watch(insightObservationsProvider);

    return summaryAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: AppLoadingState(message: 'Calculating insights...'),
        ),
      ),
      error: (e, _) => AppErrorState(
        message: 'Insights could not load.',
        onRetry: () =>
            ref.invalidate(filteredSemesterAttendanceSummaryProvider),
      ),
      data: (summary) {
        if (summary == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No active semester selected.'),
            ),
          );
        }

        // If no sessions have been conducted yet
        if (summary.totalConducted == 0) {
          final filter = ref.watch(insightsFilterProvider);
          if (!filter.isDefault) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InsightsFilterBar(),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(
                          AppIcons.calendar,
                          size: 32,
                          color: AppColors.mutedInk,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Records in Selected Filter',
                          style: AppTypography.itemTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No attendance sessions match the selected date range or subject filter.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.mutedInk,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () =>
                              ref.read(insightsFilterProvider.notifier).reset(),
                          child: Text(
                            'Clear Filter',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.inkViolet,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return AppEmptyState(
            title: 'No Attendance Data Yet',
            description: 'Log your first class session to start seeing deep analytics, lecture vs. lab comparisons, and attendance trends.',
            icon: const AppIcon(
              AppIcons.insights,
              size: 32,
              color: AppColors.brandViolet,
            ),
            actionLabel: 'Log First Class',
            onAction: () => showQuickLogSheet(context: context),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            const InsightsFilterBar(),
            const SizedBox(height: AppSpacing.md),

            // Overview Card with Donut Chart
            InsightsOverviewCard(summary: summary),
            const SizedBox(height: AppSpacing.lg),

            // Factual Observations Section
            if (observations.isNotEmpty) ...[
              InsightObservationsSection(observations: observations),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Subject Comparison
            SubjectComparisonCard(
              subjectSummaries: summary.subjectSummaries,
              threshold: summary.threshold,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Lecture vs Lab Comparison
            LectureLabComparisonCard(
              subjectSummaries: summary.subjectSummaries,
              threshold: summary.threshold,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Advanced Chronological Trend
            AdvancedTrendCard(
              trendPoints: summary.trendPoints,
              threshold: summary.threshold,
            ),
          ],
        );
      },
    );
  }
}
