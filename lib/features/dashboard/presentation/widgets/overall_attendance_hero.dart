import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_motion.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';

class OverallAttendanceHero extends StatelessWidget {
  const OverallAttendanceHero({super.key, required this.summary});

  static const double _ringSize = 164;
  static const double _strokeWidth = 11;

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
    final formattedPct = _formatPercentage();
    final progress = summary.overallPercentage != null
        ? (summary.overallPercentage! / 100.0).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      container: true,
      label:
          'Overall attendance: $formattedPct. Status: $statusText. Target is ${summary.thresholdPercent} percent.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Calculation Method & Status Badge
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
                  summary.calculationMethod.displayName,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.inkViolet,
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
                              ? AppColors.inkMint
                              : (statusColor == AppColors.brandCoral
                                    ? AppColors.inkCoral
                                    : (statusColor == AppColors.brandPeach
                                          ? AppColors.inkPeach
                                          : AppColors.mutedInk)),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Center(
            child: SizedBox(
              width: _ringSize,
              height: _ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: progress),
                    duration: AppMotion.duration(
                      context,
                      const Duration(milliseconds: 650),
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedProgress, _) {
                      return CustomPaint(
                        size: const Size.square(_ringSize),
                        painter: _DonutProgressPainter(
                          progress: animatedProgress,
                          progressColor: isAvailable || isProvisional
                              ? statusColor
                              : AppColors.track,
                          trackColor: AppColors.track,
                          threshold: summary.threshold,
                          hasData: isAvailable || isProvisional,
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(_strokeWidth + 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formattedPct,
                        style: AppTypography.heroNumber.copyWith(
                          color: isAvailable
                              ? AppColors.ink
                              : AppColors.mutedInk,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
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
                        ? AppColors.inkMint
                        : AppColors.inkCoral,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          if (isProvisional)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Combined available when both components have sessions.',
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.inkPeach,
                ),
              ),
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
    const strokeWidth = OverallAttendanceHero._strokeWidth;
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
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    final thresholdAngle = -math.pi / 2 + (2 * math.pi * threshold);
    final tickPaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final inner = radius - strokeWidth * 0.2;
    final outer = radius + strokeWidth * 0.45;
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
  bool shouldRepaint(covariant _DonutProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.threshold != threshold ||
        oldDelegate.hasData != hasData;
  }
}
