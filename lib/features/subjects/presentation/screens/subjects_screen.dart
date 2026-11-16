import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_empty_state.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_loading_state.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
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
            // Top Bar with Semester context and Add button (matches DashboardHeader)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenHorizontal,
                right: AppSpacing.screenHorizontal,
                top: AppSpacing.screenTop,
                bottom: 12,
              ),
              child: Row(
                children: [
                  // Left: Screen Title
                  Text(
                    'Subjects',
                    style: AppTypography.screenTitle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppColors.brandViolet,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Centre: Active semester switcher
                  Expanded(
                    child: Center(
                      child: Semantics(
                        button: true,
                        label:
                            'Switch active semester, currently ${activeSemester.name}',
                        child: Material(
                          color:
                              AppColors.softLavender.withValues(alpha: 0.6),
                          borderRadius: AppRadius.pillBorder,
                          child: InkWell(
                            onTap: () {
                              showAppBottomSheet(
                                context: context,
                                title: 'Semesters',
                                child: const SemesterSwitcherSheet(),
                              );
                            },
                            borderRadius: AppRadius.pillBorder,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      activeSemester.name,
                                      style: AppTypography.labelMedium
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppColors.ink,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const AppIcon(
                                    AppIcons.arrowDown,
                                    size: 15,
                                    color: AppColors.inkViolet,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Right: Add Subject action button
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

class _SubjectCard extends StatefulWidget {
  const _SubjectCard({
    required this.subject,
    required this.summary,
    required this.threshold,
    required this.onEdit,
    required this.onDelete,
  });

  static const double _ringSize = 46;
  static const double _strokeWidth = 4.0;

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

  Color _getProgressColor() {
    final summary = widget.summary;
    if (summary == null || summary.totalConducted == 0) {
      return AppColors.track;
    }
    if (summary.isProvisional) return AppColors.brandPeach;
    switch (summary.thresholdStatus) {
      case ThresholdStatus.meeting:
        return AppColors.brandMint;
      case ThresholdStatus.below:
        return AppColors.brandCoral;
      case ThresholdStatus.notAvailable:
        return AppColors.track;
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
    final summary = widget.summary;
    final hasData = summary != null && summary.totalConducted > 0;
    final progressColor = _getProgressColor();
    final pctDisplay = _formatPct();
    final pct = summary?.percentage;
    final progress = pct != null ? (pct / 100.0).clamp(0.0, 1.0) : 0.0;
    final thresholdPercent = (widget.threshold * 100).toInt();

    return Material(
      color: AppColors.pureWhite,
      borderRadius: AppRadius.mdBorder,
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: AppRadius.mdBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Card Header (Ring, Title, Inline metadata, Chevron)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Prominent Mini Donut Ring (46x46)
                  SizedBox(
                    width: _SubjectCard._ringSize,
                    height: _SubjectCard._ringSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size.square(_SubjectCard._ringSize),
                          painter: _MiniRingPainter(
                            progress: progress,
                            progressColor: progressColor,
                            trackColor: AppColors.track,
                            hasData: hasData,
                            strokeWidth: _SubjectCard._strokeWidth,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              pctDisplay,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: AppColors.ink,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),

                  // Middle Column: Title & Metadata (Clean, NO badges!)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.subject.name,
                          style: AppTypography.itemTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),

                        // Line 2: Components & Attendance count (clean typography)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (widget.subject.lectureEnabled)
                              Text(
                                'Lecture',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.brandViolet,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (widget.subject.lectureEnabled &&
                                widget.subject.labEnabled)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  '•',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.mutedInk
                                        .withValues(alpha: 0.35),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            if (widget.subject.labEnabled)
                              Text(
                                'Lab',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.inkMint,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Text(
                                '•',
                                style: AppTypography.labelSmall.copyWith(
                                  color:
                                      AppColors.mutedInk.withValues(alpha: 0.35),
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
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.mutedInk,
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
                  const SizedBox(width: 6),

                  // Trailing Expand / Collapse Chevron
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: const AppIcon(
                      AppIcons.arrowDown,
                      size: 16,
                      color: AppColors.mutedInk,
                    ),
                  ),
                ],
              ),

              // Expandable Content Section (Direct in-card details, no drawer needed)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
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
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    bool hasData,
    int thresholdPercent,
  ) {
    final summary = widget.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 12),

        // 1. Quick Metrics Strip (Target, Present, Absent, Conducted)
        // Clean open layout with subtle vertical divider ticks
        Row(
          children: [
            Expanded(
              child: _MetricCell(
                label: 'Target',
                value: '$thresholdPercent%',
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _MetricCell(
                label: 'Present',
                value: '${summary?.totalPresent ?? 0}',
                color: AppColors.inkMint,
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _MetricCell(
                label: 'Absent',
                value: '${summary?.totalAbsent ?? 0}',
                color: AppColors.inkCoral,
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _MetricCell(
                label: 'Conducted',
                value: '${summary?.totalConducted ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Standing & Target Status Banner
        if (hasData && summary != null) ...[
          if (widget.subject.lectureEnabled && widget.subject.labEnabled) ...[
            _ComponentBreakdownStrip(summary: summary),
            const SizedBox(height: 10),
          ],
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.softLavender.withValues(alpha: 0.5),
              borderRadius: AppRadius.smBorder,
            ),
            child: Row(
              children: [
                const AppIcon(
                  AppIcons.info,
                  size: 15,
                  color: AppColors.inkViolet,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No attendance sessions have been logged for this course yet.',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // 4. Action Row: Log Attendance (Primary) + Edit & Delete Icon Buttons
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
                    size: 15,
                    color: AppColors.pureWhite,
                  ),
                  size: AppButtonSize.small,
                  onPressed: () {
                    showQuickLogSheet(
                      context: context,
                      initialSubjectId: widget.subject.id,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Edit icon button
            Tooltip(
              message: 'Edit',
              child: Semantics(
                button: true,
                label: 'Edit ${widget.subject.name}',
                child: Material(
                  color: AppColors.softLavender.withValues(alpha: 0.7),
                  borderRadius: AppRadius.smBorder,
                  child: InkWell(
                    onTap: widget.onEdit,
                    borderRadius: AppRadius.smBorder,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.smBorder,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const AppIcon(
                        AppIcons.edit,
                        size: 16,
                        color: AppColors.inkViolet,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Delete icon button
            Tooltip(
              message: 'Delete',
              child: Semantics(
                button: true,
                label: 'Delete ${widget.subject.name}',
                child: Material(
                  color: AppColors.softCoral.withValues(alpha: 0.6),
                  borderRadius: AppRadius.smBorder,
                  child: InkWell(
                    onTap: widget.onDelete,
                    borderRadius: AppRadius.smBorder,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.smBorder,
                        border: Border.all(
                          color: AppColors.brandCoral.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const AppIcon(
                        AppIcons.delete,
                        size: 16,
                        color: AppColors.inkCoral,
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
  const _MetricCell({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.itemTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: color ?? AppColors.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedInk,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: AppColors.divider,
    );
  }
}

class _ComponentBreakdownStrip extends StatelessWidget {
  const _ComponentBreakdownStrip({required this.summary});

  final SubjectAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final lecture = summary.lectureSummary;
    final lab = summary.labSummary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.softLavender.withValues(alpha: 0.4),
        borderRadius: AppRadius.smBorder,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Lecture section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lecture',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.inkViolet,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${lecture?.presentCount ?? 0}/${lecture?.conductedCount ?? 0} attended',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11,
                        color: AppColors.mutedInk,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (lecture?.percentage != null)
                      Text(
                        '${lecture!.percentage!.toStringAsFixed(1)}%',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.divider,
          ),

          // Lab section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lab',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.inkMint,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${lab?.presentCount ?? 0}/${lab?.conductedCount ?? 0} attended',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11,
                        color: AppColors.mutedInk,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (lab?.percentage != null)
                      Text(
                        '${lab!.percentage!.toStringAsFixed(1)}%',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  const _MiniRingPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.hasData,
    required this.strokeWidth,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;
  final bool hasData;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, trackPaint);

    if (hasData && progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.hasData != hasData ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
