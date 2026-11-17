import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
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

    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Observations',
          style: AppTypography.sectionTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: observations.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final obs = observations[index];
            return _ObservationTile(observation: obs);
          },
        ),
      ],
    );
  }
}

class _ObservationTile extends StatelessWidget {
  const _ObservationTile({required this.observation});

  final InsightObservation observation;

  Color _accentColor(dynamic colors) {
    switch (observation.type) {
      case InsightObservationType.positive:
        return colors.accentMintInk as Color;
      case InsightObservationType.warning:
        return colors.accentCoralInk as Color;
      case InsightObservationType.info:
        return colors.brandPrimaryInk as Color;
      case InsightObservationType.neutral:
        return colors.accentPeachInk as Color;
    }
  }

  Color _bgColor(dynamic colors) {
    switch (observation.type) {
      case InsightObservationType.positive:
        return colors.accentMintSoft as Color;
      case InsightObservationType.warning:
        return colors.accentCoralSoft as Color;
      case InsightObservationType.info:
        return colors.brandPrimarySoft as Color;
      case InsightObservationType.neutral:
        return colors.accentPeachSoft as Color;
    }
  }

  dynamic get _icon {
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
    final bg = _bgColor(colors);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(
              alpha: colors.isDark ? 0.12 : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.smBorder,
            ),
            child: AppIcon(_icon, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        observation.title,
                        style: AppTypography.itemTitle.copyWith(
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (observation.badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: Text(
                          observation.badgeText!,
                          style: AppTypography.labelSmall.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  observation.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
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
