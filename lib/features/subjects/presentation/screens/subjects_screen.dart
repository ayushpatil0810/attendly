import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_empty_state.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_loading_state.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/attendance/presentation/widgets/quick_log_sheet.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_switcher_sheet.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Subject?',
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${subject.name}"? All its attendance records will be permanently removed.',
          style: AppTypography.body.copyWith(
            color: colors.textSecondary,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.headline.copyWith(
                color: colors.textSecondary,
                fontSize: 15,
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
    final colors = context.colors;
    final activeSemestersAsync = ref.watch(activeSemestersStreamProvider);
    final activeSemester = ref.watch(activeSemesterProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final summaryAsync = ref.watch(semesterAttendanceSummaryProvider);

    if (activeSemestersAsync.isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: AppLoadingState()),
      );
    }

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
        backgroundColor: colors.background,
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
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Apple Large Title & Subtitle with circular Add button
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
                        Text(
                          'Subjects',
                          style: AppTypography.title1.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enrolled Courses and Attendance',
                          style: AppTypography.footnote.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Add Subject',
                    child: Tooltip(
                      message: 'Add Subject',
                      child: Material(
                        color: colors.surfaceSubtle.withValues(
                          alpha: colors.isDark ? 0.6 : 0.8,
                        ),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _openAddSubject(context, activeSemester.id);
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.border.withValues(
                                  alpha: colors.isDark ? 0.4 : 0.6,
                                ),
                                width: 0.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: AppIcon(
                              AppIcons.add,
                              size: 19,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: subjectsAsync.when(
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return AppEmptyState(
                      title: 'No Subjects Added',
                      description: 'Add your enrolled courses to begin tracking lectures and labs.',
                      icon: AppIcon(
                        AppIcons.subjects,
                        size: 32,
                        color: colors.textSecondary,
                      ),
                      actionLabel: 'Add Subject',
                      onAction: () =>
                          _openAddSubject(context, activeSemester.id),
                    );
                  }

                  // Calculate high-level course health counts for the Apple Overview Bento Strip
                  var meetingCount = 0;
                  var belowCount = 0;
                  for (final subj in subjects) {
                    final sum = subjectSummariesMap[subj.id];
                    if (sum != null && sum.totalConducted > 0) {
                      if (sum.thresholdStatus == ThresholdStatus.meeting) {
                        meetingCount++;
                      } else if (sum.thresholdStatus == ThresholdStatus.below) {
                        belowCount++;
                      }
                    }
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(
                      left: AppSpacing.screenHorizontal,
                      right: AppSpacing.screenHorizontal,
                      top: 4,
                      bottom: AppSpacing.dockClearance,
                    ),
                    itemCount:
                        subjects.length + 1, // +1 for the top summary pill
                    separatorBuilder: (_, index) =>
                        SizedBox(height: index == 0 ? 14 : 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _SubjectsOverviewStrip(
                          totalCount: subjects.length,
                          meetingCount: meetingCount,
                          belowCount: belowCount,
                        );
                      }

                      final subject = subjects[index - 1];
                      final summary = subjectSummariesMap[subject.id];

                      return _SubjectCard(
                        subject: subject,
                        summary: summary,
                        threshold: activeSemester.attendanceThreshold,
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

/// Apple HIG Overview Bento Strip displaying high-level course attendance health
class _SubjectsOverviewStrip extends StatelessWidget {
  const _SubjectsOverviewStrip({
    required this.totalCount,
    required this.meetingCount,
    required this.belowCount,
  });

  final int totalCount;
  final int meetingCount;
  final int belowCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle.withValues(
          alpha: colors.isDark ? 0.45 : 0.65,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border.withValues(alpha: colors.isDark ? 0.4 : 0.6),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Total Courses
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Courses: ',
                  style: AppTypography.caption1.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$totalCount',
                  style: AppTypography.caption1.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          // Vertical divider
          Container(
            height: 14,
            width: 0.5,
            color: colors.divider.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          // Meeting Target
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: colors.accentMint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Meeting: ',
                style: AppTypography.caption1.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$meetingCount',
                style: AppTypography.caption1.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Vertical divider
          Container(
            height: 14,
            width: 0.5,
            color: colors.divider.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          // Below Target
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: colors.accentCoral,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Below: ',
                style: AppTypography.caption1.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$belowCount',
                style: AppTypography.caption1.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatefulWidget {
  const _SubjectCard({
    required this.subject,
    required this.summary,
    required this.threshold,
    required this.onEdit,
    required this.onDelete,
  });

  final Subject subject;
  final SubjectAttendanceSummary? summary;
  final double threshold;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _isExpanded = false;

  Color _getProgressColor(BuildContext context) {
    final colors = context.colors;
    final summary = widget.summary;
    if (summary == null || summary.totalConducted == 0) {
      return colors.track;
    }
    if (summary.isProvisional) return colors.accentPeach;
    switch (summary.thresholdStatus) {
      case ThresholdStatus.meeting:
        return colors.accentMint;
      case ThresholdStatus.below:
        return colors.accentCoral;
      case ThresholdStatus.notAvailable:
        return colors.track;
    }
  }

  String _formatPct() {
    final pct = widget.summary?.percentage;
    if (pct == null || widget.summary?.isNotAvailable == true) {
      return 'N/A';
    }
    final pctStr = pct == pct.roundToDouble()
        ? '${pct.toInt()}%'
        : '${pct.toStringAsFixed(1)}%';

    if (widget.summary?.isProvisional == true) {
      return '$pctStr*';
    }
    return pctStr;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final summary = widget.summary;
    final hasData = summary != null && summary.totalConducted > 0;
    final progressColor = _getProgressColor(context);
    final pctDisplay = _formatPct();
    final thresholdPercent = (widget.threshold * 100).toInt();

    return AppleInsetGroup(
      margin: const EdgeInsets.only(bottom: 12),
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Column: Course Name & Attendance Subtitles
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.subject.name,
                              style: AppTypography.headline.copyWith(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Component tags and session count
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (widget.subject.lectureEnabled)
                                  Text(
                                    'Lecture',
                                    style: AppTypography.caption1.copyWith(
                                      color: colors.brandPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (widget.subject.lectureEnabled &&
                                    widget.subject.labEnabled)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    child: Text(
                                      '•',
                                      style: AppTypography.caption1.copyWith(
                                        color: colors.textTertiary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                if (widget.subject.labEnabled)
                                  Text(
                                    'Lab',
                                    style: AppTypography.caption1.copyWith(
                                      color: colors.accentMint,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  child: Text(
                                    '•',
                                    style: AppTypography.caption1.copyWith(
                                      color: colors.textTertiary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    hasData
                                        ? '${summary.totalPresent} of ${summary.totalConducted} sessions attended'
                                        : 'No sessions recorded yet',
                                    style: AppTypography.caption1.copyWith(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Right: Clean tabular percentage with status color
                      if (hasData) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pctDisplay,
                              style: AppTypography.headline.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: progressColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              'Target $thresholdPercent%',
                              style: AppTypography.caption2.copyWith(
                                color: colors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          '—',
                          style: AppTypography.headline.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),

                      // Trailing Expand / Collapse Chevron
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: AppIcon(
                          AppIcons.arrowDown,
                          size: 14,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),

                  // Expandable Content Section
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _isExpanded
                        ? _buildExpandedContent(
                            context,
                            hasData,
                            thresholdPercent,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    bool hasData,
    int thresholdPercent,
  ) {
    final summary = widget.summary;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Divider(
          height: 0.5,
          thickness: 0.5,
          color: colors.divider.withValues(alpha: colors.isDark ? 0.4 : 0.7),
        ),
        const SizedBox(height: 14),

        // 1. Structured Metrics Inset Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: colors.surfaceSubtle.withValues(
              alpha: colors.isDark ? 0.5 : 0.7,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.border.withValues(alpha: colors.isDark ? 0.4 : 0.5),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricCell(label: 'Target', value: '$thresholdPercent%'),
              _MetricCell(
                label: 'Present',
                value: '${summary?.totalPresent ?? 0}',
                color: colors.accentMint,
              ),
              _MetricCell(
                label: 'Absent',
                value: '${summary?.totalAbsent ?? 0}',
                color: colors.accentCoral,
              ),
              _MetricCell(
                label: 'Conducted',
                value: '${summary?.totalConducted ?? 0}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Component breakdown chips
        if (hasData &&
            summary != null &&
            widget.subject.lectureEnabled &&
            widget.subject.labEnabled) ...[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ComponentChip(
                title: 'Lecture',
                present: summary.lectureSummary?.presentCount ?? 0,
                conducted: summary.lectureSummary?.conductedCount ?? 0,
                percentage: summary.lectureSummary?.percentage,
                color: colors.brandPrimary,
              ),
              _ComponentChip(
                title: 'Lab',
                present: summary.labSummary?.presentCount ?? 0,
                conducted: summary.labSummary?.conductedCount ?? 0,
                percentage: summary.labSummary?.percentage,
                color: colors.accentMint,
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else if (!hasData) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              'No attendance sessions recorded yet.',
              style: AppTypography.footnote.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 3. Action Row: Log Attendance (AppButton) + Edit & Delete
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Log attendance for ${widget.subject.name}',
                child: AppButton(
                  label: 'Log Attendance',
                  icon: const AppIcon(
                    AppIcons.add,
                    size: 14,
                    color: Colors.white,
                  ),
                  size: AppButtonSize.small,
                  onPressed: () {
                    showQuickLogSheet(
                      context: context,
                      onlySubjectId: widget.subject.id,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Edit icon button
            Tooltip(
              message: 'Edit Subject',
              child: Semantics(
                button: true,
                label: 'Edit ${widget.subject.name}',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onEdit();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surfaceSubtle.withValues(
                          alpha: colors.isDark ? 0.6 : 0.8,
                        ),
                        border: Border.all(
                          color: colors.border.withValues(
                            alpha: colors.isDark ? 0.4 : 0.6,
                          ),
                          width: 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: AppIcon(
                        AppIcons.edit,
                        size: 16,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Delete icon button
            Tooltip(
              message: 'Delete Subject',
              child: Semantics(
                button: true,
                label: 'Delete ${widget.subject.name}',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onDelete();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.accentCoralSoft.withValues(
                          alpha: colors.isDark ? 0.25 : 0.5,
                        ),
                        border: Border.all(
                          color: colors.accentCoral.withValues(
                            alpha: colors.isDark ? 0.3 : 0.4,
                          ),
                          width: 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: AppIcon(
                        AppIcons.delete,
                        size: 16,
                        color: colors.accentCoral,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTypography.headline.copyWith(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: color ?? colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption1.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ComponentChip extends StatelessWidget {
  const _ComponentChip({
    required this.title,
    required this.present,
    required this.conducted,
    this.percentage,
    required this.color,
  });

  final String title;
  final int present;
  final int conducted;
  final double? percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pctStr = percentage != null
        ? '${percentage!.toStringAsFixed(0)}%'
        : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: colors.isDark ? 0.5 : 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.border.withValues(alpha: colors.isDark ? 0.3 : 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTypography.caption1.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$present/$conducted ($pctStr)',
            style: AppTypography.caption1.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
