import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_empty_state.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_loading_state.dart';
import 'package:attendly/core/shared/widgets/app_progress.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_switcher_sheet.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';
import 'package:attendly/features/subjects/presentation/widgets/subject_detail_sheet.dart';
import 'package:attendly/features/subjects/presentation/widgets/subject_form_sheet.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  void _openAddSubject(BuildContext context, int semesterId) {
    showAppBottomSheet(
      context: context,
      title: 'Add Subject',
      child: SubjectFormSheet(semesterId: semesterId),
    );
  }

  void _openEditSubject(BuildContext context, int semesterId, Subject subject) {
    showAppBottomSheet(
      context: context,
      title: 'Edit Subject',
      child: SubjectFormSheet(semesterId: semesterId, initialSubject: subject),
    );
  }

  void _openSubjectDetail(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
    SubjectAttendanceSummary? summary,
    Semester activeSemester,
  ) {
    showSubjectDetailSheet(
      context: context,
      subject: subject,
      summary: summary,
      threshold: activeSemester.attendanceThreshold,
      calculationMethod: activeSemester.calculationMethod,
      onEdit: () => _openEditSubject(context, activeSemester.id, subject),
      onDelete: () => _confirmDelete(context, ref, subject),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: const Text('Delete Subject?'),
        content: Text(
          'Are you sure you want to delete "${subject.name}"? All its attendance records will be removed.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedInk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.mutedInk,
              ),
            ),
          ),
          AppButton(
            label: 'Delete',
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.small,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(subjectControllerProvider.notifier)
            .deleteSubject(subject.id);
        if (context.mounted) {
          AppToast.showSuccess(context, message: 'Subject deleted.');
        }
      } catch (_) {
        if (context.mounted) {
          AppToast.showError(
            context,
            message: 'The subject could not be deleted. Try again.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSemester = ref.watch(activeSemesterProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final summaryAsync = ref.watch(semesterAttendanceSummaryProvider);

    final subjectSummariesMap = <int, SubjectAttendanceSummary>{};
    summaryAsync.whenData((s) {
      if (s != null) {
        for (final item in s.subjectSummaries) {
          subjectSummariesMap[item.subjectId] = item;
        }
      }
    });

    if (activeSemester == null) {
      return Scaffold(
        backgroundColor: AppColors.warmWhite,
        body: SafeArea(
          child: AppEmptyState(
            title: 'No Active Semester',
            description: 'Please select or create a semester first.',
            icon: const AppIcon(AppIcons.home, size: 28),
            actionLabel: 'Select Semester',
            onAction: () {
              showAppBottomSheet(
                context: context,
                title: 'Semesters',
                child: const SemesterSwitcherSheet(),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar with Semester context and Add button
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenHorizontal,
                right: AppSpacing.screenHorizontal,
                top: AppSpacing.screenTop,
                bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subjects', style: AppTypography.screenTitle),
                        const SizedBox(height: 2),
                        Semantics(
                          button: true,
                          label:
                              'Switch active semester, currently ${activeSemester.name}',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                showAppBottomSheet(
                                  context: context,
                                  title: 'Switch Semester',
                                  child: const SemesterSwitcherSheet(),
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        activeSemester.name,
                                        style: AppTypography.labelMedium
                                            .copyWith(
                                              color: AppColors.inkViolet,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const AppIcon(
                                      AppIcons.arrowDown,
                                      size: 14,
                                      color: AppColors.brandViolet,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    label: 'Add Subject',
                    icon: const AppIcon(
                      AppIcons.add,
                      size: 16,
                      color: AppColors.pureWhite,
                    ),
                    size: AppButtonSize.small,
                    onPressed: () =>
                        _openAddSubject(context, activeSemester.id),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // Content
            Expanded(
              child: subjectsAsync.when(
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return AppEmptyState(
                      title: 'No Subjects Added',
                      description: 'Add your enrolled courses to begin tracking lectures and labs.',
                      icon: const AppIcon(
                        AppIcons.subjects,
                        size: 32,
                        color: AppColors.brandViolet,
                      ),
                      actionLabel: 'Add First Subject',
                      onAction: () =>
                          _openAddSubject(context, activeSemester.id),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(
                      left: AppSpacing.screenHorizontal,
                      right: AppSpacing.screenHorizontal,
                      top: 14,
                      bottom: AppSpacing.dockClearance,
                    ),
                    itemCount: subjects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final summary = subjectSummariesMap[subject.id];

                      return _SubjectCard(
                        subject: subject,
                        summary: summary,
                        threshold: activeSemester.attendanceThreshold,
                        onTap: () => _openSubjectDetail(
                          context,
                          ref,
                          subject,
                          summary,
                          activeSemester,
                        ),
                        onEdit: () => _openEditSubject(
                          context,
                          activeSemester.id,
                          subject,
                        ),
                        onDelete: () => _confirmDelete(context, ref, subject),
                      );
                    },
                  );
                },
                loading: () =>
                    const AppLoadingState(message: 'Loading subjects...'),
                error: (e, _) => AppErrorState(
                  message: 'Subjects could not load.',
                  onRetry: () => ref.invalidate(activeSemesterSubjectsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.summary,
    required this.threshold,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Subject subject;
  final SubjectAttendanceSummary? summary;
  final double threshold;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _getProgressColor() {
    if (summary == null || summary!.totalConducted == 0) {
      return AppColors.track;
    }
    if (summary!.isProvisional) return AppColors.brandPeach;
    switch (summary!.thresholdStatus) {
      case ThresholdStatus.meeting:
        return AppColors.brandMint;
      case ThresholdStatus.below:
        return AppColors.brandCoral;
      case ThresholdStatus.notAvailable:
        return AppColors.track;
    }
  }

  Color _getStatusTextColor() {
    if (summary == null || summary!.totalConducted == 0) {
      return AppColors.mutedInk;
    }
    if (summary!.isProvisional) return AppColors.inkPeach;
    switch (summary!.thresholdStatus) {
      case ThresholdStatus.meeting:
        return AppColors.inkMint;
      case ThresholdStatus.below:
        return AppColors.inkCoral;
      case ThresholdStatus.notAvailable:
        return AppColors.mutedInk;
    }
  }

  Color _getStatusBadgeBg() {
    if (summary == null || summary!.totalConducted == 0) {
      return AppColors.track;
    }
    if (summary!.isProvisional) return AppColors.softPeach;
    switch (summary!.thresholdStatus) {
      case ThresholdStatus.meeting:
        return AppColors.softMint;
      case ThresholdStatus.below:
        return AppColors.softCoral;
      case ThresholdStatus.notAvailable:
        return AppColors.track;
    }
  }

  String _getStatusLabel() {
    if (summary == null || summary!.totalConducted == 0) {
      return 'No records yet';
    }
    if (summary!.isProvisional) return 'Provisional';
    switch (summary!.thresholdStatus) {
      case ThresholdStatus.meeting:
        return 'Meeting target';
      case ThresholdStatus.below:
        return 'Below target';
      case ThresholdStatus.notAvailable:
        return 'No records';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = summary != null && summary!.totalConducted > 0;
    final progressColor = _getProgressColor();
    final statusTextColor = _getStatusTextColor();
    final statusBadgeBg = _getStatusBadgeBg();
    final statusLabel = _getStatusLabel();
    final pct = summary?.percentage;

    final pctDisplay = pct != null
        ? (pct == pct.roundToDouble()
              ? '${pct.toInt()}%'
              : '${pct.toStringAsFixed(1)}%')
        : null;

    final semanticText = StringBuffer(subject.name)
      ..write(
        hasData
            ? ', $pctDisplay, $statusLabel. ${summary!.totalPresent} of ${summary!.totalConducted} sessions attended.'
            : ', No sessions recorded yet.',
      )
      ..write(' Components: ')
      ..write(
        [
          if (subject.lectureEnabled) 'Lecture',
          if (subject.labEnabled) 'Lab',
        ].join(' and '),
      );

    return Semantics(
      button: true,
      label: semanticText.toString(),
      child: Material(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgBorder,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgBorder,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withAlpha(6),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Course Name on left; Standing & Actions on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        subject.name,
                        style: AppTypography.itemTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    if (hasData && pctDisplay != null) ...[
                      Text(
                        pctDisplay,
                        style: AppTypography.itemTitle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: statusTextColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusBadgeBg,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: statusTextColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: statusTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Lightweight Overflow Menu
                    PopupMenuButton<String>(
                      tooltip: 'Subject options',
                      icon: const AppIcon(
                        AppIcons.more,
                        size: 18,
                        color: AppColors.mutedInk,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdBorder,
                      ),
                      onSelected: (val) {
                        if (val == 'edit') onEdit();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              AppIcon(AppIcons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Subject'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              AppIcon(
                                AppIcons.delete,
                                size: 16,
                                color: AppColors.inkCoral,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete Subject',
                                style: TextStyle(color: AppColors.inkCoral),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Line 2: Streamlined Progress Bar
                AppProgressBar(
                  progress: pct != null ? (pct / 100.0).clamp(0.0, 1.0) : 0.0,
                  color: progressColor,
                  height: 5,
                ),
                const SizedBox(height: 8),

                // Line 3: Compact Metadata (Component tags & Sessions count)
                Row(
                  children: [
                    if (subject.lectureEnabled) ...[
                      _ComponentBadge(
                        label: 'Lecture',
                        color: AppColors.brandViolet,
                        bg: AppColors.softLavender,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (subject.labEnabled) ...[
                      _ComponentBadge(
                        label: 'Lab',
                        color: AppColors.inkMint,
                        bg: AppColors.softMint,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        hasData
                            ? '${summary!.totalPresent} of ${summary!.totalConducted} sessions attended'
                            : 'No sessions recorded yet',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mutedInk,
                          fontSize: 11,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComponentBadge extends StatelessWidget {
  const _ComponentBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillBorder),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
