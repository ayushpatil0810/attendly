import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';

class InsightsOverviewCard extends StatelessWidget {
  const InsightsOverviewCard({super.key, required this.summary});

  final SemesterAttendanceSummary summary;

  Color _getStatusColor() {
    switch (summary.thresholdStatus) {
      case ThresholdStatus.meeting:
        return AppColors.brandMint;
      case ThresholdStatus.below:
        return AppColors.brandCoral;
      case ThresholdStatus.notAvailable:
        if (summary.isProvisional) return AppColors.brandPeach;
        return AppColors.mutedInk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
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
        color: AppColors.pureWhite,
        borderRadius: AppRadius.xlBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Attendance Overview', style: AppTypography.itemTitle),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Text(
                  summary.calculationMethod ==
                          AttendanceCalculationMethod.rawCombined
                      ? 'Raw Combined'
                      : 'Component Average (50/50)',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.brandViolet,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
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
                            color: isAvailable
                                ? AppColors.ink
                                : AppColors.mutedInk,
                          ),
                        ),
                        if (isProvisional)
                          Text(
                            'Prov.',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 9,
                              color: AppColors.brandPeach,
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
                            ? AppColors.softMint
                            : (summary.isBelowThreshold
                                  ? AppColors.softCoral
                                  : AppColors.softLavender),
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
                                    ? const Color(0xFF1E826D)
                                    : (summary.isBelowThreshold
                                          ? const Color(0xFFD63B48)
                                          : AppColors.mutedInk),
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
                      color: AppColors.brandMint,
                      label: 'Present',
                      count: summary.totalPresent,
                      percentage: presentPct,
                    ),
                    const SizedBox(height: 4),
                    _CountRow(
                      color: AppColors.brandCoral,
                      label: 'Absent',
                      count: summary.totalAbsent,
                      percentage: absentPct,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Conducted: ${summary.totalConducted} classes',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.mutedInk,
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
                  color: AppColors.softPeach,
                  borderRadius: AppRadius.smBorder,
                ),
                child: Row(
                  children: [
                    const AppIcon(
                      AppIcons.alert,
                      size: 16,
                      color: AppColors.brandPeach,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Component Average requires sessions in both Lecture and Lab to form a final combined percentage.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF9E5742),
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
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.mutedInk,
            fontSize: 12,
          ),
        ),
        Text(
          '$count',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${percentage.toStringAsFixed(0)}%)',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.mutedInk,
            fontSize: 11,
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
  });

  final int presentCount;
  final int absentCount;
  final double threshold;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final total = presentCount + absentCount;

    // Track
    final trackPaint = Paint()
      ..color = AppColors.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (total == 0) return;

    final presentSweep = (presentCount / total) * 2 * math.pi;
    final absentSweep = (absentCount / total) * 2 * math.pi;

    final presentPaint = Paint()
      ..color = AppColors.brandMint
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final absentPaint = Paint()
      ..color = AppColors.brandCoral
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
        oldDelegate.threshold != threshold;
  }
}
