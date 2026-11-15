import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/simulator_projection.dart';

class SimulatorProjectionCard extends StatelessWidget {
  const SimulatorProjectionCard({super.key, required this.projection});

  final SimulatorProjection projection;

  @override
  Widget build(BuildContext context) {
    final baseline = projection.baselineSummary;
    final projected = projection.projectedSummary;
    final hasSimulated = projection.hasSimulatedSessions;
    final delta = projection.percentageDifference;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.xlBorder,
        border: Border.all(
          color: hasSimulated
              ? AppColors.brandViolet.withOpacity(0.4)
              : AppColors.border,
          width: hasSimulated ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Simulation Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Projected Outcome', style: AppTypography.itemTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(
                      AppIcons.insights,
                      size: 12,
                      color: AppColors.brandViolet,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Hypothetical',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.brandViolet,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Side-by-side Baseline vs Projected Comparison
          Row(
            children: [
              // Baseline
              Expanded(
                child: _MetricColumn(
                  title: 'Actual Baseline',
                  percentage: baseline.formattedPercentage,
                  present: baseline.totalPresent,
                  conducted: baseline.totalConducted,
                  isProjected: false,
                  meetsTarget: baseline.meetsThreshold,
                  isProvisional: baseline.isProvisional,
                ),
              ),

              // Arrow indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.track,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.mutedInk,
                  ),
                ),
              ),

              // Projected
              Expanded(
                child: _MetricColumn(
                  title: 'Projected',
                  percentage: projected.formattedPercentage,
                  present: projected.totalPresent,
                  conducted: projected.totalConducted,
                  isProjected: true,
                  meetsTarget: projected.meetsThreshold,
                  isProvisional: projected.isProvisional,
                  highlight: hasSimulated,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Delta & Impact Banner
          if (hasSimulated && delta != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: delta > 0.05
                    ? AppColors.softMint
                    : (delta < -0.05
                          ? AppColors.softCoral
                          : AppColors.softLavender),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Row(
                children: [
                  AppIcon(
                    delta >= 0 ? AppIcons.check : AppIcons.alert,
                    size: 16,
                    color: delta > 0.05
                        ? AppColors.brandMint
                        : (delta < -0.05
                              ? AppColors.brandCoral
                              : AppColors.brandViolet),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getDeltaMessage(projection, delta),
                      style: AppTypography.labelSmall.copyWith(
                        color: delta > 0.05
                            ? const Color(0xFF1E826D)
                            : (delta < -0.05
                                  ? const Color(0xFFD63B48)
                                  : AppColors.brandViolet),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Calculation Policy Note
          Text(
            baseline.calculationMethod ==
                    AttendanceCalculationMethod.rawCombined
                ? 'Raw Combined: All sessions carry equal weight. Target: ${baseline.thresholdPercent}%.'
                : 'Component Average: Lecture and Lab are averaged 50/50. Target: ${baseline.thresholdPercent}%.',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.mutedInk,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _getDeltaMessage(SimulatorProjection proj, double delta) {
    final deltaStr = delta > 0
        ? '+${delta.toStringAsFixed(1)}%'
        : '${delta.toStringAsFixed(1)}%';

    if (proj.improvedToThreshold) {
      return '$deltaStr — Reaches your ${proj.baselineSummary.thresholdPercent}% target!';
    } else if (proj.droppedBelowThreshold) {
      return '$deltaStr — Drops below your ${proj.baselineSummary.thresholdPercent}% target!';
    } else if (delta.abs() < 0.05) {
      return 'No net percentage change ($deltaStr).';
    } else if (delta > 0) {
      return '$deltaStr projected attendance improvement.';
    } else {
      return '$deltaStr projected attendance decrease.';
    }
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.title,
    required this.percentage,
    required this.present,
    required this.conducted,
    required this.isProjected,
    required this.meetsTarget,
    required this.isProvisional,
    this.highlight = false,
  });

  final String title;
  final String percentage;
  final int present;
  final int conducted;
  final bool isProjected;
  final bool meetsTarget;
  final bool isProvisional;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.softLavender
            : AppColors.track.withOpacity(0.5),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(
          color: highlight
              ? AppColors.brandViolet.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.mutedInk,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              percentage,
              style: AppTypography.heroNumber.copyWith(
                fontSize: 24,
                color: meetsTarget ? const Color(0xFF1E826D) : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$present/$conducted classes',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.mutedInk,
              fontSize: 10,
            ),
          ),
          if (isProvisional)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Provisional',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.brandPeach,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
