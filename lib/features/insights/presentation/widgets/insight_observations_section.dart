import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_theme_colors.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/insight_observation.dart';

class InsightObservationsSection extends StatelessWidget {
  const InsightObservationsSection({super.key, required this.observations});

  final List<InsightObservation> observations;

  @override
  Widget build(BuildContext context) {
    if (observations.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limit to the most prominent observations to avoid clutter and card-soup
    final displayObservations = observations.take(3).toList();

    return AppleInsetGroup(
      header: 'Key Observations',
      margin: EdgeInsets.zero,
      children: [
        for (final observation in displayObservations)
          _ObservationTile(observation: observation),
      ],
    );
  }
}

class _ObservationTile extends StatelessWidget {
  const _ObservationTile({required this.observation});

  final InsightObservation observation;

  Color _accentColor(AppThemeColors colors) {
    switch (observation.type) {
      case InsightObservationType.positive:
        return colors.present;
      case InsightObservationType.warning:
        return colors.absent;
      case InsightObservationType.info:
        return colors.brandPrimary;
      case InsightObservationType.neutral:
        return colors.accentOrange;
    }
  }

  IconData get _icon {
    switch (observation.type) {
      case InsightObservationType.positive:
        return AppIcons.check;
      case InsightObservationType.warning:
        return AppIcons.alert;
      case InsightObservationType.info:
        return AppIcons.insights;
      case InsightObservationType.neutral:
        return AppIcons.lecture;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _accentColor(colors);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AppIcon(_icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        observation.title,
                        style: AppTypography.itemTitle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (observation.badgeText != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        observation.badgeText!,
                        style: AppTypography.caption1.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  observation.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
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
