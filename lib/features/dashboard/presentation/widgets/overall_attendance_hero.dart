import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_motion.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/attendance/domain/services/attendance_action_helper.dart';
import 'package:attendly/features/dashboard/presentation/providers/dashboard_scope_provider.dart';

class OverallAttendanceHero extends StatelessWidget {
  const OverallAttendanceHero({
    super.key,
    required this.summary,
    this.scope = DashboardAttendanceScope.overall,
  });

  static const double _chartSize = 196;
  static const double _strokeWidth = 13;

  final SemesterAttendanceSummary summary;
  final DashboardAttendanceScope scope;

  Color _getStatusColor(BuildContext context) {
    final colors = context.colors;
    switch (summary.thresholdStatus) {
      case ThresholdStatus.meeting:
        return colors.present;
      case ThresholdStatus.below:
        return colors.absent;
      case ThresholdStatus.notAvailable:
        if (summary.availability.isProvisional) {
          return colors.accentOrange;
        }
        return colors.textSecondary;
    }
  }

  String _formatPercentage() {
    if (summary.availability.isNotAvailable ||
        summary.overallPercentage == null) {
      return '—';
    }
    final pct = summary.overallPercentage!;
    if (pct == pct.roundToDouble()) {
      return '${pct.toInt()}%';
    }
    return '${pct.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = _getStatusColor(context);
    final isAvailable = summary.isAvailable;
    final isProvisional = summary.isProvisional;
    final formattedPct = _formatPercentage();
    final progress = summary.overallPercentage != null
        ? (summary.overallPercentage! / 100.0).clamp(0.0, 1.0)
        : 0.0;
    final monthName = DateFormat('MMMM').format(DateTime.now());
    final labelText = scope == DashboardAttendanceScope.thisMonth
        ? '$monthName Attendance'
        : 'Total Percentage';

    return Semantics(
      container: true,
      label:
          'Overall attendance: $formattedPct. Target is ${summary.thresholdPercent} percent.',
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Centered Circular Progress Chart
            Center(
              child: RepaintBoundary(
                child: SizedBox(
                  width: _chartSize,
                  height: _chartSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Custom Circular Progress Painter
                      Positioned.fill(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: progress),
                          duration: AppMotion.duration(
                            context,
                            const Duration(milliseconds: 650),
                          ),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedProgress, _) {
                            return CustomPaint(
                              size: const Size.square(_chartSize),
                              painter: _CircularGaugePainter(
                                progress: animatedProgress,
                                progressColor: isAvailable || isProvisional
                                    ? statusColor
                                    : colors.track,
                                trackColor: colors.track,
                                threshold: summary.threshold,
                                hasData: isAvailable || isProvisional,
                                strokeWidth: _strokeWidth,
                                markerColor: colors.textPrimary,
                              ),
                            );
                          },
                        ),
                      ),
                      // Centered content inside the circle: Percentage + "Total Percentage" label
                      Padding(
                        padding: const EdgeInsets.all(_strokeWidth + 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formattedPct,
                                textAlign: TextAlign.center,
                                style: AppTypography.heroNumber.copyWith(
                                  fontSize: 38,
                                  height: 1.0,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.0,
                                  color: isAvailable
                                      ? colors.textPrimary
                                      : colors.textSecondary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labelText,
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Target line, delta comparison, and calculation info
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Target: ${summary.thresholdPercent}%',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  if (summary.differenceFromThreshold != null)
                    Text(
                      summary.differenceFromThreshold! >= 0
                          ? '+${summary.differenceFromThreshold!.toStringAsFixed(1)}%'
                          : '${summary.differenceFromThreshold!.toStringAsFixed(1)}%',
                      style: AppTypography.labelLarge.copyWith(
                        color: summary.differenceFromThreshold! >= 0
                          ? colors.present
                          : colors.absent,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  Tooltip(
                    message: summary.calculationMethod ==
                            AttendanceCalculationMethod.componentAverage
                        ? 'Calculated using 50/50 Lecture & Lab split'
                        : 'Calculated using raw Present / Conducted ratio (equal weight)',
                    triggerMode: TooltipTriggerMode.tap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: AppTypography.caption1.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: AppIcon(
                        AppIcons.info,
                        size: 16,
                        color: colors.textTertiary,
                        semanticLabel: 'Calculation method information',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actionable "Can Miss / Must Attend" class counts
            () {
              final actionable = AttendanceActionHelper.calculateActionableInsight(
                present: summary.totalPresent,
                conducted: summary.totalConducted,
                threshold: summary.threshold,
              );
              if (actionable != null && (isAvailable || isProvisional)) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle.withValues(
                        alpha: colors.isDark ? 0.6 : 0.8,
                      ),
                      borderRadius: BorderRadius.circular(16),
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
                          actionable.isAboveOrAtTarget
                              ? AppIcons.checkCircle
                              : AppIcons.alert,
                          size: 14,
                          color: actionable.isAboveOrAtTarget
                              ? colors.present
                              : colors.absent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          actionable.headlineText,
                          style: AppTypography.caption1.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }(),

            // Provisional note (if applicable)
            if (isProvisional)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Combined available when both components have sessions.',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.accentOrange,
                    fontSize: 11.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  const _CircularGaugePainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.threshold,
    required this.hasData,
    required this.strokeWidth,
    required this.markerColor,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double threshold;
  final bool hasData;
  final double strokeWidth;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Full 360-degree background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc sweeping clockwise from top (-pi / 2)
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

    // Target threshold marker tick
    final thresholdAngle =
        -math.pi / 2 + (2 * math.pi * threshold.clamp(0.0, 1.0));
    final tickPaint = Paint()
      ..color = markerColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final inner = radius - strokeWidth * 0.55;
    final outer = radius + strokeWidth * 0.55;

    canvas.drawLine(
      Offset(
        center.dx + inner * math.cos(thresholdAngle),
        center.dy + inner * math.sin(thresholdAngle),
      ),
      Offset(
        center.dx + outer * math.cos(thresholdAngle),
        center.dy + outer * math.sin(thresholdAngle),
      ),
      tickPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.threshold != threshold ||
        oldDelegate.hasData != hasData ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.markerColor != markerColor;
  }
}
