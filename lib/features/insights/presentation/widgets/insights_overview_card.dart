import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_theme_colors.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';

class InsightsOverviewCard extends StatelessWidget {
  const InsightsOverviewCard({super.key, required this.summary});

  final SemesterAttendanceSummary summary;

  Color _getStatusColor(AppThemeColors colors) {
    switch (summary.thresholdStatus) {
      case ThresholdStatus.meeting:
        return colors.present;
      case ThresholdStatus.below:
        return colors.absent;
      case ThresholdStatus.notAvailable:
        if (summary.isProvisional) return colors.accentOrange;
        return colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = _getStatusColor(colors);
    final isAvailable = summary.isAvailable;
    final isProvisional = summary.isProvisional;

    final presentPct = summary.totalConducted > 0
        ? (summary.totalPresent / summary.totalConducted) * 100
        : 0.0;
    final absentPct = summary.totalConducted > 0
        ? (summary.totalAbsent / summary.totalConducted) * 100
        : 0.0;

    // Mathematical accuracy: for 50/50 split, ratio comes from overallPercentage if available
    final double? effectiveRatio;
    if (summary.calculationMethod ==
            AttendanceCalculationMethod.componentAverage &&
        summary.overallPercentage != null) {
      effectiveRatio = (summary.overallPercentage! / 100.0).clamp(0.0, 1.0);
    } else if (summary.totalConducted > 0) {
      effectiveRatio =
          (summary.totalPresent / summary.totalConducted).clamp(0.0, 1.0);
    } else {
      effectiveRatio = null;
    }

    final semanticLabel =
        'Attendance Overview: ${summary.formattedPercentage}. '
        'Target: ${(summary.threshold * 100).round()}%. '
        '${summary.totalPresent} present, ${summary.totalAbsent} absent across ${summary.totalConducted} conducted classes.';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: AppleInsetGroup(
        header: 'Attendance Overview',
        margin: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Calculation Policy
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      summary.calculationMethod.displayName,
                      style: AppTypography.caption1.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Main Metrics: Donut Chart with Target Marker & Key Counts
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _AttendanceDistributionPainter(
                      presentRatio: effectiveRatio,
                      isProvisional: isProvisional,
                      threshold: summary.threshold,
                      trackColor: colors.track,
                      presentColor: colors.present,
                      absentColor: colors.absent,
                      provisionalColor: colors.accentOrange,
                      markerColor: colors.textPrimary,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            summary.formattedPercentage,
                            style: AppTypography.itemTitle.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: isAvailable
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                          if (isProvisional)
                            Text(
                              'Provisional',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                                color: colors.accentOrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Metrics & Target
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Target Status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isProvisional
                                  ? 'Provisional'
                                  : (summary.meetsThreshold
                                        ? 'On Target (≥ ${summary.thresholdPercent}%)'
                                        : (summary.isBelowThreshold
                                              ? 'Below Target (< ${summary.thresholdPercent}%)'
                                              : 'Not Available')),
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.subhead.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Present & Absent Breakdown Rows
                      _CountRow(
                        color: colors.present,
                        label: 'Present',
                        count: summary.totalPresent,
                        percentage: presentPct,
                      ),
                      const SizedBox(height: 4),
                      _CountRow(
                        color: colors.absent,
                        label: 'Absent',
                        count: summary.totalAbsent,
                        percentage: absentPct,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Conducted: ${summary.totalConducted} classes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isProvisional)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    AppIcon(
                      AppIcons.alert,
                      size: 14,
                      color: colors.accentOrange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Both lecture and lab required for 50/50 split total.',
                        style: AppTypography.caption1.copyWith(
                          fontSize: 11,
                          color: colors.accentOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.color,
    required this.label,
    required this.count,
    required this.percentage,
  });

  final Color color;
  final String label;
  final int count;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                TextSpan(
                  text: '$count ',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: colors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: '(${percentage.toStringAsFixed(0)}%)',
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AttendanceDistributionPainter extends CustomPainter {
  const _AttendanceDistributionPainter({
    required this.presentRatio,
    required this.isProvisional,
    required this.threshold,
    required this.trackColor,
    required this.presentColor,
    required this.absentColor,
    required this.provisionalColor,
    required this.markerColor,
  });

  final double? presentRatio;
  final bool isProvisional;
  final double threshold;
  final Color trackColor;
  final Color presentColor;
  final Color absentColor;
  final Color provisionalColor;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Draw Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (presentRatio == null && !isProvisional) return;

    const startAngle = -math.pi / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    if (isProvisional) {
      final provSweep = (presentRatio ?? 0.5) * 2 * math.pi;
      final provPaint = Paint()
        ..color = provisionalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(arcRect, startAngle, provSweep, false, provPaint);
    } else if (presentRatio != null) {
      final ratio = presentRatio!.clamp(0.0, 1.0);
      final presentSweep = ratio * 2 * math.pi;
      final absentSweep = (1.0 - ratio) * 2 * math.pi;

      final presentPaint = Paint()
        ..color = presentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      final absentPaint = Paint()
        ..color = absentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      // Draw Present Arc
      if (ratio > 0) {
        canvas.drawArc(arcRect, startAngle, presentSweep, false, presentPaint);
      }

      // Draw Absent Arc
      if (ratio < 1.0) {
        canvas.drawArc(
          arcRect,
          startAngle + presentSweep,
          absentSweep,
          false,
          absentPaint,
        );
      }
    }

    // 2. Draw Target Threshold Marker (radial tick across the ring)
    final thresholdAngle =
        startAngle + (threshold.clamp(0.0, 1.0) * 2 * math.pi);
    final innerR = radius - (strokeWidth / 2) - 2;
    final outerR = radius + (strokeWidth / 2) + 2;

    final p1 = Offset(
      center.dx + innerR * math.cos(thresholdAngle),
      center.dy + innerR * math.sin(thresholdAngle),
    );
    final p2 = Offset(
      center.dx + outerR * math.cos(thresholdAngle),
      center.dy + outerR * math.sin(thresholdAngle),
    );

    final markerPaint = Paint()
      ..color = markerColor.withValues(alpha: 0.75)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _AttendanceDistributionPainter oldDelegate) {
    return oldDelegate.presentRatio != presentRatio ||
        oldDelegate.isProvisional != isProvisional ||
        oldDelegate.threshold != threshold ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.presentColor != presentColor ||
        oldDelegate.absentColor != absentColor ||
        oldDelegate.provisionalColor != provisionalColor ||
        oldDelegate.markerColor != markerColor;
  }
}
