import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/insights_filter.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/insights/presentation/providers/insights_providers.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

class InsightsFilterBar extends ConsumerWidget {
  const InsightsFilterBar({super.key});

  Future<void> _showCustomDateRangePicker(
    BuildContext context,
    WidgetRef ref,
    InsightsFilter currentFilter,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange:
          currentFilter.customStartDate != null &&
              currentFilter.customEndDate != null
          ? DateTimeRange(
              start: currentFilter.customStartDate!,
              end: currentFilter.customEndDate!,
            )
          : DateTimeRange(
              start: now.subtract(const Duration(days: 14)),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandViolet,
              onPrimary: AppColors.pureWhite,
              surface: AppColors.pureWhite,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(insightsFilterProvider.notifier)
          .setDateRange(
            DateRangeType.custom,
            customStart: picked.start,
            customEnd: picked.end,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(insightsFilterProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final subjects = subjectsAsync.asData?.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Range Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              ...DateRangeType.values.map((type) {
                final isSelected = filter.dateRangeType == type;
                String label = type.label;
                if (type == DateRangeType.custom &&
                    filter.customStartDate != null &&
                    filter.customEndDate != null) {
                  final df = DateFormat('MMM d');
                  label =
                      '${df.format(filter.customStartDate!)} - ${df.format(filter.customEndDate!)}';
                }

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _FilterChip(
                    label: label,
                    isSelected: isSelected,
                    onTap: () {
                      if (type == DateRangeType.custom) {
                        _showCustomDateRangePicker(context, ref, filter);
                      } else {
                        ref
                            .read(insightsFilterProvider.notifier)
                            .setDateRange(type);
                      }
                    },
                  ),
                );
              }),
              if (!filter.isDefault)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(insightsFilterProvider.notifier).reset(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softCoral,
                        borderRadius: AppRadius.pillBorder,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIcon(
                            AppIcons.close,
                            size: 14,
                            color: AppColors.brandCoral,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFFD63B48),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Secondary Filters: Subject & Component Filter Row
        if (subjects.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _SecondaryFilterChip(
                  label: 'All Subjects',
                  isSelected: filter.subjectId == null,
                  onTap: () => ref
                      .read(insightsFilterProvider.notifier)
                      .setSubject(null),
                ),
                ...subjects.map((s) {
                  final isSelected = filter.subjectId == s.id;
                  return Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xxs),
                    child: _SecondaryFilterChip(
                      label: s.name,
                      isSelected: isSelected,
                      onTap: () => ref
                          .read(insightsFilterProvider.notifier)
                          .setSubject(s.id),
                    ),
                  );
                }),
                const SizedBox(width: AppSpacing.sm),
                // Component chips
                _SecondaryFilterChip(
                  label: 'All Components',
                  isSelected: filter.component == null,
                  onTap: () => ref
                      .read(insightsFilterProvider.notifier)
                      .setComponent(null),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xxs),
                  child: _SecondaryFilterChip(
                    label: 'Lectures',
                    isSelected: filter.component == SessionComponent.lecture,
                    onTap: () => ref
                        .read(insightsFilterProvider.notifier)
                        .setComponent(SessionComponent.lecture),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xxs),
                  child: _SecondaryFilterChip(
                    label: 'Labs',
                    isSelected: filter.component == SessionComponent.lab,
                    onTap: () => ref
                        .read(insightsFilterProvider.notifier)
                        .setComponent(SessionComponent.lab),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandViolet : AppColors.pureWhite,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: isSelected ? AppColors.brandViolet : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandViolet.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.pureWhite : AppColors.ink,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SecondaryFilterChip extends StatelessWidget {
  const _SecondaryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softLavender : Colors.transparent,
          borderRadius: AppRadius.smBorder,
          border: Border.all(
            color: isSelected ? AppColors.brandViolet : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 11,
            color: isSelected ? AppColors.brandViolet : AppColors.mutedInk,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
