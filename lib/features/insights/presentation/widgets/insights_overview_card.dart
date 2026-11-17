import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';

class InsightsOverviewCard extends StatelessWidget {
  const InsightsOverviewCard({super.key, required this.summary});

  final SemesterAttendanceSummary summary;

  Color _getStatusColor(dynamic colors) {
    switch (summary.thresholdStatus) {
      case ThresholdStatus.meeting:
        return colors.accentMint as Color;
      case ThresholdStatus.below:
        return colors.accentCoral as Color;
      case ThresholdStatus.notAvailable:
        if (summary.isProvisional) return colors.accentPeach as Color;
        return colors.textSecondary as Color;
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.xlBorder,
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(
              alpha: colors.isDark ? 0.12 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Wrap ensures narrow screens do not overflow
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  'Attendance Overview',
                  style: AppTypography.itemTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.brandPrimarySoft,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Text(
                    summary.calculationMethod.displayName,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.brandPrimaryInk,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Main Stats Row: Donut Distribution Chart & Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Distribution Donut Painter
              SizedBox(
                width: 92,
                height: 92,
                child: CustomPaint(
                  painter: _AttendanceDistributionPainter(
                    presentCount: summary.totalPresent,
                    absentCount: summary.totalAbsent,
                    threshold: summary.threshold,
                    trackColor: colors.track,
                    presentColor: colors.accentMint,
                    absentColor: colors.accentCoral,
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
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isAvailable
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                        ),
                        if (isProvisional)
                          Text(
                            'Prov.',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 12,
                              color: colors.accentPeachInk,
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
                    // Target Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: summary.meetsThreshold
                            ? colors.accentMintSoft
                            : (summary.isBelowThreshold
                                  ? colors.accentCoralSoft
                                  : colors.brandPrimarySoft),
                        borderRadius: AppRadius.pillBorder,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
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
                              style: AppTypography.labelSmall.copyWith(
                                color: summary.meetsThreshold
                                    ? colors.accentMintInk
                                    : (summary.isBelowThreshold
                                          ? colors.accentCoralInk
                                          : colors.textSecondary),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Present & Absent Breakdown Rows
                    _CountRow(
                      color: colors.accentMint,
                      label: 'Present',
                      count: summary.totalPresent,
                      percentage: presentPct,
                    ),
                    const SizedBox(height: 4),
                    _CountRow(
                      color: colors.accentCoral,
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
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.accentPeachSoft,
                  borderRadius: AppRadius.smBorder,
                ),
                child: Row(
                  children: [
                    AppIcon(
                      AppIcons.alert,
                      size: 16,
                      color: colors.accentPeachInk,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Both a lecture and a lab need to be logged before the split total can be calculated.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: colors.accentPeachInk,
                        ),
                      ),
                    ),
                  ],
                ),
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
    required this.presentCount,
    required this.absentCount,
    required this.threshold,
    required this.trackColor,
    required this.presentColor,
    required this.absentColor,
  });

  final int presentCount;
  final int absentCount;
  final double threshold;
  final Color trackColor;
  final Color presentColor;
  final Color absentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final total = presentCount + absentCount;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (total == 0) return;

    final presentSweep = (presentCount / total) * 2 * math.pi;
    final absentSweep = (absentCount / total) * 2 * math.pi;

    final presentPaint = Paint()
      ..color = presentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final absentPaint = Paint()
      ..color = absentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const startAngle = -math.pi / 2;

    // Draw Present Arc
    if (presentCount > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        presentSweep,
        false,
        presentPaint,
      );
    }

    // Draw Absent Arc
    if (absentCount > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + presentSweep,
        absentSweep,
        false,
        absentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AttendanceDistributionPainter oldDelegate) {
    return oldDelegate.presentCount != presentCount ||
        oldDelegate.absentCount != absentCount ||
        oldDelegate.threshold != threshold ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.presentColor != presentColor ||
        oldDelegate.absentColor != absentColor;
  }
}
