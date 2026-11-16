import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/subjects/presentation/widgets/subject_form_sheet.dart';

class DashboardSubjectPreview extends StatefulWidget {
  const DashboardSubjectPreview({
    super.key,
    required this.semesterId,
    required this.subjects,
    required this.threshold,
    required this.onNavigateToSubjects,
  });

  final int semesterId;
  final List<SubjectAttendanceSummary> subjects;
  final double threshold;
  final VoidCallback onNavigateToSubjects;

  @override
  State<DashboardSubjectPreview> createState() =>
      _DashboardSubjectPreviewState();
}

class _DashboardSubjectPreviewState extends State<DashboardSubjectPreview> {
  @override
  Widget build(BuildContext context) {
    // Option 1: Action-oriented At-Risk / Attention filter
    // Identifies subjects that need immediate attention:
    // 1. Below target threshold
    // 2. Provisional calculation
    // 3. On the edge (0 or 1 safe absence remaining)
    // 4. No sessions recorded yet
    final attentionSubjects = widget.subjects.where((s) {
      if (s.totalConducted == 0) return true;
      if (s.thresholdStatus == ThresholdStatus.below) return true;
      if (s.isProvisional) return true;
      final safe = s.safeAbsenceResult.safeAbsences;
      if (safe != null && safe <= 1) return true;
      return false;
    }).toList();

    final String sectionTitle;
    if (widget.subjects.isEmpty) {
      sectionTitle = 'Your Courses';
    } else if (attentionSubjects.isNotEmpty) {
      sectionTitle = 'Needs Attention';
    } else {
      sectionTitle = 'Your Courses';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row (Matches Attendance Trend section title)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                sectionTitle,
                style: AppTypography.sectionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.subjects.isNotEmpty)
              Semantics(
                button: true,
                label: 'View all subjects',
                child: TextButton(
                  onPressed: widget.onNavigateToSubjects,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    minimumSize: const Size(48, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.inkViolet,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Subject list or empty / all-on-track state
        if (widget.subjects.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const AppIcon(
                  AppIcons.subjects,
                  size: 32,
                  color: AppColors.brandViolet,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No subjects added yet',
                  style: AppTypography.itemTitle,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Add Subject',
                  icon: const AppIcon(
                    AppIcons.add,
                    size: 16,
                    color: AppColors.pureWhite,
                  ),
                  size: AppButtonSize.small,
                  onPressed: () {
                    showAppBottomSheet(
                      context: context,
                      title: 'Add Subject',
                      child: SubjectFormSheet(semesterId: widget.semesterId),
                    );
                  },
                ),
              ],
            ),
          )
        else if (attentionSubjects.isEmpty)
          // All subjects are safely on track
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadius.mdBorder,
              child: InkWell(
                onTap: widget.onNavigateToSubjects,
                borderRadius: AppRadius.mdBorder,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.softMint,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: AppIcon(
                            AppIcons.check,
                            size: 20,
                            color: AppColors.brandMint,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Subjects On Track',
                              style: AppTypography.itemTitle.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'All ${widget.subjects.length} courses are meeting or exceeding your ${(widget.threshold * 100).toInt()}% target.',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const AppIcon(
                        AppIcons.forward,
                        size: 16,
                        color: AppColors.mutedInk,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          // Render prioritized focus subjects (up to 4)
          Container(
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ...attentionSubjects.take(4).map((subject) {
                  final isLast =
                      subject == attentionSubjects.take(4).last &&
                      attentionSubjects.length <= 4;
                  return Column(
                    children: [
                      InkWell(
                        onTap: widget.onNavigateToSubjects,
                        borderRadius: isLast
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              )
                            : (subject == attentionSubjects.first
                                  ? const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    )
                                  : BorderRadius.zero),
                        child: _SubjectPreviewRow(
                          subject: subject,
                          threshold: widget.threshold,
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.divider,
                        ),
                    ],
                  );
                }),
                if (attentionSubjects.length > 4) ...[
                  const Divider(height: 1, color: AppColors.divider),
                  Semantics(
                    button: true,
                    label:
                        'View ${attentionSubjects.length - 4} more subjects to watch',
                    child: InkWell(
                      onTap: widget.onNavigateToSubjects,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            '+ ${attentionSubjects.length - 4} more subjects to review',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.inkViolet,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Mini Donut Ring Subject Row
class _SubjectPreviewRow extends StatelessWidget {
  const _SubjectPreviewRow({
    required this.subject,
    required this.threshold,
  });

  static const double _ringSize = 46;
  static const double _strokeWidth = 4.0;

  final SubjectAttendanceSummary subject;
  final double threshold;

  Color _getRingColor() {
    if (subject.isProvisional) {
      return AppColors.brandPeach;
    }
    switch (subject.thresholdStatus) {
      case ThresholdStatus.meeting:
        return AppColors.brandMint;
      case ThresholdStatus.below:
        return AppColors.brandCoral;
      case ThresholdStatus.notAvailable:
        return AppColors.track;
    }
  }

  String _formatPct() {
    if (subject.isNotAvailable || subject.percentage == null) {
      return 'N/A';
    }
    final pct = subject.percentage!;
    final pctStr = pct == pct.roundToDouble()
        ? '${pct.toInt()}%'
        : '${pct.toStringAsFixed(1)}%';

    if (subject.isProvisional) {
      return '$pctStr*';
    }
    return pctStr;
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _getRingColor();
    final progress = subject.percentage != null
        ? (subject.percentage! / 100.0).clamp(0.0, 1.0)
        : 0.0;
    final formattedPct = _formatPct();

    final componentsText = [
      if (subject.lectureEnabled) 'Lecture',
      if (subject.labEnabled) 'Lab',
    ].join(' • ');

    final countText = subject.totalConducted > 0
        ? '${subject.totalPresent}/${subject.totalConducted} attended'
        : 'No sessions yet';

    final safe = subject.safeAbsenceResult.safeAbsences;
    final String statusNote;
    Color statusColor = AppColors.mutedInk;
    FontWeight statusWeight = FontWeight.w400;

    if (subject.totalConducted == 0) {
      statusNote = componentsText.isNotEmpty ? componentsText : 'Not available';
    } else if (subject.thresholdStatus == ThresholdStatus.below) {
      final needed = subject.recoveryResult.requiredConsecutivePresents;
      if (needed != null && needed > 0) {
        final unit = needed == 1 ? 'class' : 'classes';
        statusNote = 'Needs $needed $unit to recover';
        statusColor = AppColors.inkCoral;
        statusWeight = FontWeight.w600;
      } else {
        statusNote =
            componentsText.isNotEmpty ? componentsText : 'Action needed';
        if (componentsText.isEmpty) {
          statusColor = AppColors.inkCoral;
          statusWeight = FontWeight.w600;
        }
      }
    } else if (safe != null && safe == 0) {
      statusNote = '0 safe absences left';
      statusColor = AppColors.inkPeach;
      statusWeight = FontWeight.w600;
    } else if (safe != null && safe == 1) {
      statusNote = '1 safe absence left';
      statusColor = AppColors.inkPeach;
      statusWeight = FontWeight.w600;
    } else if (subject.isProvisional) {
      statusNote = 'Provisional calculation';
      statusColor = AppColors.inkPeach;
      statusWeight = FontWeight.w500;
    } else {
      statusNote = componentsText.isNotEmpty ? componentsText : 'Meeting target';
    }

    return Semantics(
      button: true,
      label:
          '${subject.subjectName}, $formattedPct, $statusNote. ${subject.totalConducted > 0 ? "${subject.totalPresent} of ${subject.totalConducted} attended" : "No sessions recorded yet"}',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Prominent Mini Donut Ring (46x46)
            SizedBox(
              width: _ringSize,
              height: _ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(_ringSize),
                    painter: _MiniRingPainter(
                      progress: progress,
                      progressColor: ringColor,
                      trackColor: AppColors.track,
                      hasData:
                          !subject.isNotAvailable && subject.percentage != null,
                      strokeWidth: _strokeWidth,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        formattedPct,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),

            // Middle Column: Subject Title & Status Note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subject.subjectName,
                    style: AppTypography.itemTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusNote,
                    style: AppTypography.labelSmall.copyWith(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: statusWeight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Right Side: Attended count + forward icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  countText,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mutedInk,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                const AppIcon(
                  AppIcons.forward,
                  size: 14,
                  color: AppColors.mutedInk,
                ),
              ],
            ),
          ],
        ),
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
