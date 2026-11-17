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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.dockClearance - 20),
        child: FloatingActionButton.extended(
          onPressed: () => _openAddSubject(context, activeSemester.id),
          backgroundColor: AppColors.brandViolet,
          foregroundColor: AppColors.pureWhite,
          elevation: 3,
          icon: AppIcon(AppIcons.add, size: 20, color: AppColors.pureWhite),
          label: Text(
            'Add Subject',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Title & Subtitle only
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.screenHorizontal,
                right: AppSpacing.screenHorizontal,
                top: AppSpacing.screenTop,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subjects', style: AppTypography.screenTitle),
                  SizedBox(height: 4),
                  Text(
                    'Enrolled Courses and Attendance',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: AppColors.mutedInk,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Text(
                                  '•',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.mutedInk.withValues(
                                      alpha: 0.35,
                                    ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: Text(
                                '•',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.mutedInk.withValues(
                                    alpha: 0.35,
                                  ),
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
                    child: AppIcon(
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
                    ? _buildExpandedContent(context, hasData, thresholdPercent)
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
        const SizedBox(height: 14),
        Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 14),

        // 1. Clean Metrics Row (Target, Present, Absent, Conducted)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MetricCell(label: 'Target', value: '$thresholdPercent%'),
            _MetricCell(
              label: 'Present',
              value: '${summary?.totalPresent ?? 0}',
              color: AppColors.inkMint,
            ),
            _MetricCell(
              label: 'Absent',
              value: '${summary?.totalAbsent ?? 0}',
              color: AppColors.inkCoral,
            ),
            _MetricCell(
              label: 'Conducted',
              value: '${summary?.totalConducted ?? 0}',
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Component breakdown if Lecture and Lab are both active
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
                color: AppColors.inkViolet,
              ),
              _ComponentChip(
                title: 'Lab',
                present: summary.labSummary?.presentCount ?? 0,
                conducted: summary.labSummary?.conductedCount ?? 0,
                percentage: summary.labSummary?.percentage,
                color: AppColors.inkMint,
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else if (!hasData) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              'No attendance sessions recorded yet.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                color: AppColors.mutedInk,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 3. Action Row: Log Attendance (Primary) + Edit & Delete Icon Buttons
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Log attendance for ${widget.subject.name}',
                child: AppButton(
                  label: 'Log Attendance',
                  icon: AppIcon(
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
            // Edit icon button (no light background)
            Tooltip(
              message: 'Edit Subject',
              child: Semantics(
                button: true,
                label: 'Edit ${widget.subject.name}',
                child: InkWell(
                  onTap: widget.onEdit,
                  borderRadius: AppRadius.pillBorder,
                  child: Container(
                    width: 44,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: AppRadius.pillBorder,
                      border: Border.all(color: AppColors.divider),
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(
                      AppIcons.edit,
                      size: 17,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Delete icon button (no light background)
            Tooltip(
              message: 'Delete Subject',
              child: Semantics(
                button: true,
                label: 'Delete ${widget.subject.name}',
                child: InkWell(
                  onTap: widget.onDelete,
                  borderRadius: AppRadius.pillBorder,
                  child: Container(
                    width: 44,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: AppRadius.pillBorder,
                      border: Border.all(color: AppColors.divider),
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(
                      AppIcons.delete,
                      size: 17,
                      color: AppColors.inkCoral,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTypography.itemTitle.copyWith(
            fontSize: 16,
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
    final pctStr = percentage != null
        ? '${percentage!.toStringAsFixed(0)}%'
        : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$present/$conducted ($pctStr)',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.ink,
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
