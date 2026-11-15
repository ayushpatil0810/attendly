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

class OverallAttendanceHero extends StatelessWidget {
  const OverallAttendanceHero({super.key, required this.summary});

  final SemesterAttendanceSummary summary;

  Color _getStatusColor() {
    switch (summary.thresholdStatus) {
      case ThresholdStatus.meeting:
        return AppColors.brandMint;
      case ThresholdStatus.below:
        return AppColors.brandCoral;
      case ThresholdStatus.notAvailable:
        if (summary.availability.isProvisional) {
          return AppColors.brandPeach;
        }
        return AppColors.mutedInk;
    }
  }

  Color _getBadgeBackgroundColor() {
    switch (summary.thresholdStatus) {
      case ThresholdStatus.meeting:
        return AppColors.softMint;
      case ThresholdStatus.below:
        return AppColors.softCoral;
      case ThresholdStatus.notAvailable:
        if (summary.availability.isProvisional) {
          return AppColors.softPeach;
        }
        return AppColors.softLavender;
    }
  }

  String _getStatusText() {
    if (summary.availability.isProvisional) {
      if (summary.lectureConducted > 0) {
        return 'Provisional: Lecture only';
      } else if (summary.labConducted > 0) {
        return 'Provisional: Lab only';
      }
      return 'Provisional';
    }

    switch (summary.thresholdStatus) {
      case ThresholdStatus.meeting:
        final diff = summary.differenceFromThreshold ?? 0;
        if (diff.abs() < 0.05) {
          return 'On Target';
        }
        return 'Above Target';
      case ThresholdStatus.below:
        return 'Below Target';
      case ThresholdStatus.notAvailable:
        return 'Not Available';
    }
  }

  String _formatPercentage() {
    if (summary.availability.isNotAvailable ||
        summary.overallPercentage == null) {
      return '—';
    }
    final pct = summary.overallPercentage!;
    // Display with 1 decimal if not whole, or integer if exact
    if (pct == pct.roundToDouble()) {
      return '${pct.toInt()}%';
    }
    return '${pct.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final badgeBg = _getBadgeBackgroundColor();
    final statusText = _getStatusText();
    final isAvailable = summary.isAvailable;
    final isProvisional = summary.isProvisional;
    final progress = summary.overallPercentage != null
        ? (summary.overallPercentage! / 100.0).clamp(0.0, 1.0)
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
          // Top Row: Calculation Method & Status Badge (Wrap ensures narrow screens do not overflow)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
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
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
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
                        statusText,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: statusColor == AppColors.brandMint
                              ? const Color(0xFF1E826D)
                              : (statusColor == AppColors.brandCoral
                                    ? const Color(0xFFD63B48)
                                    : statusColor),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Hero Row: Percentage & Donut Progress Ring
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut Progress Ring with animated transition
              SizedBox(
                width: 88,
                height: 88,
                child: CustomPaint(
                  painter: _DonutProgressPainter(
                    progress: progress,
                    progressColor: isAvailable || isProvisional
                        ? statusColor
                        : AppColors.track,
                    trackColor: AppColors.track,
                    threshold: summary.threshold,
                    hasData: isAvailable || isProvisional,
                  ),
                  child: Center(
                    child: AppIcon(
                      isAvailable
                          ? (summary.thresholdStatus == ThresholdStatus.meeting
                                ? AppIcons.check
                                : AppIcons.alert)
                          : AppIcons.calendar,
                      size: 26,
                      color: isAvailable ? statusColor : AppColors.mutedInk,
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatPercentage(),
                        style: AppTypography.heroNumber.copyWith(
                          fontSize: 40,
                          color: isAvailable
                              ? AppColors.ink
                              : AppColors.mutedInk,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Target: ${summary.thresholdPercent}%',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.mutedInk,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (summary.differenceFromThreshold != null)
                          Text(
                            summary.differenceFromThreshold! >= 0
                                ? '+${summary.differenceFromThreshold!.toStringAsFixed(1)}%'
                                : '${summary.differenceFromThreshold!.toStringAsFixed(1)}%',
                            style: AppTypography.labelSmall.copyWith(
                              color: summary.differenceFromThreshold! >= 0
                                  ? const Color(0xFF1E826D)
                                  : const Color(0xFFD63B48),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    if (isProvisional)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Combined available when both components have sessions.',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.brandPeach,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutProgressPainter extends CustomPainter {
  const _DonutProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.threshold,
    required this.hasData,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double threshold;
  final bool hasData;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (hasData && progress > 0) {
      // Progress Arc
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // Threshold marker dot on track
      final thresholdAngle = -math.pi / 2 + (2 * math.pi * threshold);
      final markerX = center.dx + radius * math.cos(thresholdAngle);
      final markerY = center.dy + radius * math.sin(thresholdAngle);

      final markerPaint = Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(markerX, markerY), 2.5, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.threshold != threshold ||
        oldDelegate.hasData != hasData;
  }
}
