import 'package:flutter/material.dart';
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
import 'package:attendly/features/attendance/domain/entities/component_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/attendance/domain/services/attendance_action_helper.dart';
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
        surfaceTintColor: Colors.transparent,
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
            icon: AppIcon(
              AppIcons.calendar,
              size: 28,
              color: colors.textSecondary,
            ),
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
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      final isNarrow = MediaQuery.sizeOf(context).width < 340;
                      final addLabel = isNarrow ? 'Subject' : 'Add Subject';

                      return Semantics(
                        button: true,
                        label: 'Add Subject',
                        child: Material(
                          color: colors.surfaceSubtle.withValues(
                            alpha: colors.isDark ? 0.65 : 0.9,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () {
                              _openAddSubject(context, activeSemester.id);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
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
                                    AppIcons.add,
                                    size: 15,
                                    color: colors.brandPrimary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    addLabel,
                                    style: AppTypography.footnote.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
                      actionIcon: const AppIcon(AppIcons.add, size: 18),
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
                      if (sum.thresholdStatus == ThresholdStatus.below ||
                          sum.hasComponentBelowThreshold) {
                        belowCount++;
                      } else if (sum.thresholdStatus == ThresholdStatus.meeting) {
                        meetingCount++;
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
                      bottom: AppSpacing.safeDockClearance,
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
                        key: ValueKey(subject.id),
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
                  color: colors.present,
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
                  color: colors.absent,
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
    super.key,
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
    if (summary.isProvisional) return colors.accentOrange;
    if (summary.thresholdStatus == ThresholdStatus.below ||
        summary.hasComponentBelowThreshold) {
      return colors.absent;
    }
    switch (summary.thresholdStatus) {
      case ThresholdStatus.meeting:
        return colors.present;
      case ThresholdStatus.below:
        return colors.absent;
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

    return AppleInsetGroup(
      margin: const EdgeInsets.only(bottom: 12),
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
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
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
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
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                // When collapsed, show concise attended/conducted summary.
                                // When expanded with data, hide it to avoid duplicating expanded stats.
                                if (!_isExpanded || !hasData) ...[
                                  if (widget.subject.lectureEnabled ||
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
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Right: Clean tabular percentage with status color
                      if (hasData) ...[
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
  ) {
    final summary = widget.summary;
    final colors = context.colors;

    final actionable = hasData
        ? AttendanceActionHelper.calculateActionableInsight(
            present: summary!.totalPresent,
            conducted: summary.totalConducted,
            threshold: widget.threshold,
          )
        : null;

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

        // 1. Structured Metrics Inset Box: Actionable Insight, Present, Absent, Conducted
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
              if (actionable != null)
                Tooltip(
                  message: actionable.headlineText,
                  child: _MetricCell(
                    label: actionable.isAboveOrAtTarget ? 'Can Miss' : 'Need',
                    value: '${actionable.count}',
                    color: actionable.isAboveOrAtTarget
                        ? colors.present
                        : colors.absent,
                  ),
                )
              else
                _MetricCell(
                  label: 'Status',
                  value: '—',
                  color: colors.textTertiary,
                ),
              _MetricCell(
                label: 'Present',
                value: '${summary?.totalPresent ?? 0}',
              ),
              _MetricCell(
                label: 'Absent',
                value: '${summary?.totalAbsent ?? 0}',
              ),
              _MetricCell(
                label: 'Conducted',
                value: '${summary?.totalConducted ?? 0}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Component breakdown rows (Lecture & Lab)
        if (hasData &&
            summary != null &&
            widget.subject.lectureEnabled &&
            widget.subject.labEnabled) ...[
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceSubtle.withValues(
                alpha: colors.isDark ? 0.5 : 0.7,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.4 : 0.5,
                ),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                _ComponentRow(
                  title: 'Lecture',
                  summary: summary.lectureSummary,
                  threshold: widget.threshold,
                ),
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: 14,
                  endIndent: 14,
                  color: colors.divider.withValues(
                    alpha: colors.isDark ? 0.4 : 0.7,
                  ),
                ),
                _ComponentRow(
                  title: 'Lab',
                  summary: summary.labSummary,
                  threshold: widget.threshold,
                ),
              ],
            ),
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
                      widget.onEdit();
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
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
            ),
            const SizedBox(width: 4),
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
                      widget.onDelete();
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
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
                          AppIcons.delete,
                          size: 16,
                          color: colors.absent,
                        ),
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

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({
    required this.title,
    required this.summary,
    required this.threshold,
  });

  final String title;
  final ComponentAttendanceSummary? summary;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final conducted = summary?.conductedCount ?? 0;
    final present = summary?.presentCount ?? 0;
    final pct = summary?.percentage;
    final hasSessions = conducted > 0;
    final isBelow = summary?.isBelowThreshold ?? false;

    final actionable = hasSessions
        ? AttendanceActionHelper.calculateActionableInsight(
            present: present,
            conducted: conducted,
            threshold: threshold,
          )
        : null;

    final String pctStr = pct != null ? '${pct.toStringAsFixed(0)}%' : '—';

    final String statusText;
    final Color statusColor;

    if (!hasSessions || actionable == null) {
      statusText = '—';
      statusColor = colors.textTertiary;
    } else if (isBelow) {
      statusText = actionable.count > 0
          ? 'Need ${actionable.count}'
          : actionable.headlineText;
      statusColor = colors.absent;
    } else if (actionable.count > 0) {
      statusText = 'Can miss ${actionable.count}';
      statusColor = colors.present;
    } else {
      statusText = 'On target';
      statusColor = colors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.subhead.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            hasSessions ? '$present/$conducted · $pctStr' : '0/0 · —',
            style: AppTypography.footnote.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Text(
            statusText,
            style: AppTypography.footnote.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
