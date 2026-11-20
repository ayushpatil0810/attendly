import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_motion.dart';
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

class _DashboardSubjectPreviewState extends State<DashboardSubjectPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardSubjectPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.semesterId != widget.semesterId) {
      _isExpanded = false;
      _expandController.value = 0.0;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _expandController.duration = AppMotion.duration(
        context,
        const Duration(milliseconds: 300),
      );
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

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

    final primarySubjects = attentionSubjects.take(4).toList();
    final remainingSubjects = attentionSubjects.length > 4
        ? attentionSubjects.skip(4).toList()
        : const <SubjectAttendanceSummary>[];

    final String sectionTitle;
    if (widget.subjects.isEmpty) {
      sectionTitle = 'Your Courses';
    } else if (attentionSubjects.isNotEmpty) {
      sectionTitle = 'Needs Attention';
    } else {
      sectionTitle = 'Your Courses';
    }

    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row (Matches Apple Section Header)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                sectionTitle,
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: colors.textPrimary,
                ),
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
                    style: AppTypography.subhead.copyWith(
                      color: colors.isDark
                          ? const Color(0xFF5E81F4)
                          : const Color(0xFF3F5BF6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Subject list or empty / all-on-track state
        if (widget.subjects.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.4 : 0.6,
                ),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: colors.isDark ? 0.25 : 0.03,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                AppIcon(
                  AppIcons.subjects,
                  size: 32,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No subjects added yet',
                  style: AppTypography.headline.copyWith(
                    color: colors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Add Subject',
                  icon: AppIcon(
                    AppIcons.add,
                    size: 16,
                    color: colors.surface,
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
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.4 : 0.6,
                ),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: colors.isDark ? 0.25 : 0.03,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: widget.onNavigateToSubjects,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.accentMintSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: AppIcon(
                            AppIcons.check,
                            size: 20,
                            color: colors.accentMint,
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
                              style: AppTypography.headline.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'All ${widget.subjects.length} courses are meeting or exceeding your ${(widget.threshold * 100).toInt()}% target.',
                              style: AppTypography.footnote.copyWith(
                                color: colors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppIcon(
                        AppIcons.forward,
                        size: 16,
                        color: colors.textTertiary,
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
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.4 : 0.6,
                ),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: colors.isDark ? 0.25 : 0.03,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1. Primary subjects (up to 4)
                ...primarySubjects.map((subject) {
                  final isFirst = subject == primarySubjects.first;
                  final isLast = subject == primarySubjects.last &&
                      attentionSubjects.length <= 4;
                  return Column(
                    children: [
                      InkWell(
                        onTap: widget.onNavigateToSubjects,
                        borderRadius: isFirst
                            ? (isLast
                                ? BorderRadius.circular(18)
                                : const BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ))
                            : (isLast
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(18),
                                  )
                                : BorderRadius.zero),
                        child: _SubjectPreviewRow(
                          subject: subject,
                          threshold: widget.threshold,
                        ),
                      ),
                      if (subject != primarySubjects.last)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 16,
                          endIndent: 16,
                          color: colors.divider.withValues(
                            alpha: colors.isDark ? 0.5 : 0.7,
                          ),
                        ),
                    ],
                  );
                }),

                // 2. Smoothly animated expansion for remaining subjects
                if (remainingSubjects.isNotEmpty) ...[
                  AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      if (_expandAnimation.value == 0.0) {
                        return const SizedBox.shrink();
                      }
                      return ClipRect(
                        child: SizeTransition(
                          sizeFactor: _expandAnimation,
                          axisAlignment: -1.0,
                          child: FadeTransition(
                            opacity: _expandAnimation,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        for (final subject in remainingSubjects) ...[
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16,
                            color: colors.divider.withValues(
                              alpha: colors.isDark ? 0.5 : 0.7,
                            ),
                          ),
                          InkWell(
                            onTap: widget.onNavigateToSubjects,
                            child: _SubjectPreviewRow(
                              subject: subject,
                              threshold: widget.threshold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: colors.divider.withValues(
                      alpha: colors.isDark ? 0.5 : 0.7,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: _isExpanded
                        ? 'Show fewer subjects'
                        : 'Reveal ${remainingSubjects.length} more subjects in this list',
                    child: InkWell(
                      onTap: _toggleExpanded,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isExpanded
                                    ? 'Show less'
                                    : '+ ${remainingSubjects.length} more ${remainingSubjects.length == 1 ? "subject" : "subjects"} to review',
                                style: AppTypography.footnote.copyWith(
                                  color: colors.isDark
                                      ? const Color(0xFF5E81F4)
                                      : const Color(0xFF3F5BF6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0.0,
                                duration: AppMotion.duration(
                                  context,
                                  const Duration(milliseconds: 300),
                                ),
                                curve: Curves.easeInOutCubic,
                                child: AppIcon(
                                  AppIcons.arrowDown,
                                  size: 14,
                                  color: colors.isDark
                                      ? const Color(0xFF5E81F4)
                                      : const Color(0xFF3F5BF6),
                                ),
                              ),
                            ],
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
  const _SubjectPreviewRow({required this.subject, required this.threshold});

  static const double _ringSize = 46;
  static const double _strokeWidth = 4.0;

  final SubjectAttendanceSummary subject;
  final double threshold;

  Color _getRingColor(BuildContext context) {
    final colors = context.colors;
    if (subject.isProvisional) {
      return colors.accentPeach;
    }
    switch (subject.thresholdStatus) {
      case ThresholdStatus.meeting:
        return colors.accentMint;
      case ThresholdStatus.below:
        return colors.accentCoral;
      case ThresholdStatus.notAvailable:
        return colors.track;
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
    final colors = context.colors;
    final ringColor = _getRingColor(context);
    final progress = subject.percentage != null
        ? (subject.percentage! / 100.0).clamp(0.0, 1.0)
        : 0.0;
    final formattedPct = _formatPct();

    final componentsText = [
      if (subject.lectureEnabled) 'Lecture',
      if (subject.labEnabled) 'Lab',
    ].join(' • ');

    final safe = subject.safeAbsenceResult.safeAbsences;
    final String statusNote;
    Color statusColor = colors.textSecondary;
    FontWeight statusWeight = FontWeight.w400;

    if (subject.totalConducted == 0) {
      statusNote = 'No sessions yet';
    } else if (subject.thresholdStatus == ThresholdStatus.below) {
      final needed = subject.recoveryResult.requiredConsecutivePresents;
      if (needed != null && needed > 0) {
        final unit = needed == 1 ? 'class' : 'classes';
        statusNote = 'Needs $needed $unit to recover';
        statusColor = colors.accentCoral;
        statusWeight = FontWeight.w600;
      } else {
        statusNote = componentsText.isNotEmpty
            ? componentsText
            : 'Action needed';
        if (componentsText.isEmpty) {
          statusColor = colors.accentCoral;
          statusWeight = FontWeight.w600;
        }
      }
    } else if (safe != null && safe == 0) {
      statusNote = '0 safe absences left';
      statusColor = colors.accentPeach;
      statusWeight = FontWeight.w600;
    } else if (safe != null && safe == 1) {
      statusNote = '1 safe absence left';
      statusColor = colors.accentPeach;
      statusWeight = FontWeight.w600;
    } else if (subject.isProvisional) {
      statusNote = 'Provisional calculation';
      statusColor = colors.accentPeach;
      statusWeight = FontWeight.w500;
    } else {
      statusNote = componentsText.isNotEmpty
          ? componentsText
          : 'Meeting target';
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
                      trackColor: colors.track,
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
                        style: AppTypography.caption1.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: colors.textPrimary,
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
                    style: AppTypography.headline.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusNote,
                    style: AppTypography.footnote.copyWith(
                      color: statusColor,
                      fontSize: 12.5,
                      fontWeight: statusWeight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Right Side: Navigation caret icon
            AppIcon(
              AppIcons.caretRight,
              size: 15,
              color: colors.textTertiary,
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
