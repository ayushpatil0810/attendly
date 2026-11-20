import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/simulator_projection.dart';

class SimulatorProjectionCard extends StatelessWidget {
  const SimulatorProjectionCard({super.key, required this.projection});

  final SimulatorProjection projection;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseline = projection.baselineSummary;
    final projected = projection.projectedSummary;
    final hasSimulated = projection.hasSimulatedSessions;
    final delta = projection.percentageDifference;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Simulation Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Projected Outcome',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle.withValues(
                    alpha: colors.isDark ? 0.6 : 0.8,
                  ),
                  borderRadius: BorderRadius.circular(14),
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
                      AppIcons.insights,
                      size: 13,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Hypothetical',
                      style: AppTypography.caption1.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
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
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    AppIcons.forward,
                    size: 14,
                    color: colors.textSecondary,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: delta > 0.05
                    ? colors.accentMintSoft
                    : (delta < -0.05
                          ? colors.accentCoralSoft
                          : colors.surfaceSubtle),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(
                  color: delta > 0.05
                      ? colors.accentMint.withValues(alpha: 0.3)
                      : (delta < -0.05
                            ? colors.accentCoral.withValues(alpha: 0.3)
                            : colors.border),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  AppIcon(
                    delta >= 0 ? AppIcons.check : AppIcons.alert,
                    size: 16,
                    color: delta > 0.05
                        ? colors.accentMint
                        : (delta < -0.05
                              ? colors.accentCoral
                              : colors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getDeltaMessage(projection, delta),
                      style: AppTypography.subhead.copyWith(
                        color: delta > 0.05
                            ? colors.accentMintInk
                            : (delta < -0.05
                                  ? colors.accentCoralInk
                                  : colors.textPrimary),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Calculation Policy Note
          Text(
            '${baseline.calculationMethod.displayName}. ${baseline.calculationMethod.description} Target: ${baseline.thresholdPercent}%.',
            style: AppTypography.caption1.copyWith(
              color: colors.textSecondary,
              fontSize: 11.5,
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
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? colors.surfaceElevated
            : colors.surfaceSubtle.withValues(alpha: colors.isDark ? 0.4 : 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? colors.border
              : colors.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.caption1.copyWith(
              color: colors.textSecondary,
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
                fontFeatures: const [FontFeature.tabularFigures()],
                color: meetsTarget ? colors.accentMint : colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$present/$conducted classes',
            style: AppTypography.caption2.copyWith(
              color: colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (isProvisional)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Provisional',
                style: AppTypography.caption2.copyWith(
                  color: colors.accentPeach,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
