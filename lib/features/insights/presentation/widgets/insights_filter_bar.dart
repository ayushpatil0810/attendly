import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_motion.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/insights_filter.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/insights/presentation/providers/insights_providers.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

class InsightsFilterBar extends ConsumerWidget {
  const InsightsFilterBar({super.key});

  Future<void> _showCustomDateRangePicker(
    BuildContext context,
    WidgetRef ref,
    InsightsFilter currentFilter,
  ) async {
    final now = DateTime.now();
    final colors = context.colors;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
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
            colorScheme: colors.isDark
                ? ColorScheme.dark(
                    primary: colors.brandPrimary,
                    onPrimary: colors.background,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: colors.brandPrimary,
                    onPrimary: Colors.white,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
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
    final colors = context.colors;
    final filter = ref.watch(insightsFilterProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final subjects = subjectsAsync.asData?.value ?? <Subject>[];

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
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surfaceSubtle.withValues(
                          alpha: colors.isDark ? 0.6 : 0.8,
                        ),
                        borderRadius: AppRadius.pillBorder,
                        border: Border.all(
                          color: colors.border.withValues(
                            alpha: colors.isDark ? 0.4 : 0.6,
                          ),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            AppIcons.close,
                            size: 13,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: AppTypography.caption1.copyWith(
                              color: colors.textSecondary,
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
        _FilterChip(
          label: _scopeLabel(filter, subjects),
          isSelected: filter.subjectId != null || filter.component != null,
          onTap: () {
            showAppBottomSheet(
              context: context,
              title: 'Narrow insights',
              child: const _InsightsScopeSheet(),
            );
          },
        ),
      ],
    );
  }
}

String _scopeLabel(InsightsFilter filter, List<Subject> subjects) {
  String? subjectName;
  for (final subject in subjects) {
    if (subject.id == filter.subjectId) {
      subjectName = subject.name;
      break;
    }
  }
  final componentName = switch (filter.component) {
    SessionComponent.lecture => 'Lectures',
    SessionComponent.lab => 'Labs',
    null => null,
  };
  if (subjectName == null && componentName == null) return 'All classes';
  if (subjectName != null && componentName != null) {
    return '$subjectName · $componentName';
  }
  return subjectName ?? componentName!;
}

class _InsightsScopeSheet extends ConsumerWidget {
  const _InsightsScopeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final filter = ref.watch(insightsFilterProvider);
    final subjects =
        ref.watch(activeSemesterSubjectsProvider).asData?.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (subjects.length > 1) ...[
          Text(
            'Subject',
            style: AppTypography.labelMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _SecondaryFilterChip(
                label: 'All subjects',
                isSelected: filter.subjectId == null,
                onTap: () =>
                    ref.read(insightsFilterProvider.notifier).setSubject(null),
              ),
              ...subjects.map(
                (subject) => _SecondaryFilterChip(
                  label: subject.name,
                  isSelected: filter.subjectId == subject.id,
                  onTap: () => ref
                      .read(insightsFilterProvider.notifier)
                      .setSubject(subject.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          'Class type',
          style: AppTypography.labelMedium.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _SecondaryFilterChip(
              label: 'Lectures and labs',
              isSelected: filter.component == null,
              onTap: () =>
                  ref.read(insightsFilterProvider.notifier).setComponent(null),
            ),
            _SecondaryFilterChip(
              label: 'Lectures',
              isSelected: filter.component == SessionComponent.lecture,
              onTap: () => ref
                  .read(insightsFilterProvider.notifier)
                  .setComponent(SessionComponent.lecture),
            ),
            _SecondaryFilterChip(
              label: 'Labs',
              isSelected: filter.component == SessionComponent.lab,
              onTap: () => ref
                  .read(insightsFilterProvider.notifier)
                  .setComponent(SessionComponent.lab),
            ),
          ],
        ),
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
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.duration(
          context,
          const Duration(milliseconds: 150),
        ),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.brandPrimary : colors.surface,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: isSelected
                ? colors.brandPrimary
                : colors.border.withValues(alpha: colors.isDark ? 0.35 : 0.6),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? (colors.isDark ? colors.background : Colors.white)
                : colors.textPrimary,
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
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.brandPrimarySoft : Colors.transparent,
          borderRadius: AppRadius.smBorder,
          border: Border.all(
            color: isSelected ? colors.brandPrimary : colors.border,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 11,
            color: isSelected ? colors.brandPrimary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
