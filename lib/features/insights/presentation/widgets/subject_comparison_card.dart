import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';

class SubjectComparisonCard extends StatelessWidget {
  const SubjectComparisonCard({
    super.key,
    required this.subjectSummaries,
    required this.threshold,
  });

  final List<SubjectAttendanceSummary> subjectSummaries;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    if (subjectSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort: available subjects sorted by percentage descending; unavailable at the end
    final sortedSubjects = [...subjectSummaries]
      ..sort((a, b) {
        if (a.percentage != null && b.percentage != null) {
          return b.percentage!.compareTo(a.percentage!);
        } else if (a.percentage != null) {
          return -1;
        } else if (b.percentage != null) {
          return 1;
        }
        return a.subjectName.compareTo(b.subjectName);
      });

    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Comparison',
          style: AppTypography.sectionTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
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
              // Legend row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${subjectSummaries.length} Subject${subjectSummaries.length == 1 ? '' : 's'}',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 2,
                        height: 10,
                        color: colors.textPrimary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(threshold * 100).round()}% Target',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Subject comparison items
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedSubjects.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final subject = sortedSubjects[index];
                  return _SubjectComparisonRow(
                    summary: subject,
                    threshold: threshold,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubjectComparisonRow extends StatelessWidget {
  const _SubjectComparisonRow({required this.summary, required this.threshold});

  final SubjectAttendanceSummary summary;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAvailable = summary.isAvailable;
    final isProvisional = summary.isProvisional;
    final pct = summary.percentage;

    Color barColor;
    if (summary.meetsThreshold) {
      barColor = colors.accentMint;
    } else if (summary.isBelowThreshold) {
      barColor = colors.accentCoral;
    } else if (isProvisional) {
      barColor = colors.accentPeach;
    } else {
      barColor = colors.track;
    }

    final double fillRatio = pct != null ? (pct / 100.0).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name, Counts & Percentage Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      summary.subjectName,
                      style: AppTypography.itemTitle.copyWith(
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (summary.totalConducted > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${summary.totalPresent}/${summary.totalConducted}',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Percentage badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isAvailable
                    ? (summary.meetsThreshold
                          ? colors.accentMintSoft
                          : colors.accentCoralSoft)
                    : (isProvisional ? colors.accentPeachSoft : colors.track),
                borderRadius: AppRadius.pillBorder,
              ),
              child: Text(
                isAvailable
                    ? summary.formattedPercentage
                    : (isProvisional ? 'Provisional' : 'Not available'),
                style: AppTypography.labelSmall.copyWith(
                  color: isAvailable
                      ? (summary.meetsThreshold
                            ? colors.accentMintInk
                            : colors.accentCoralInk)
                      : (isProvisional
                            ? colors.accentPeachInk
                            : colors.textSecondary),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Horizontal Comparison Bar with Threshold Line
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final thresholdX = (threshold * barWidth).clamp(0.0, barWidth);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Track
                Container(
                  height: 8,
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: colors.track,
                    borderRadius: AppRadius.pillBorder,
                  ),
                ),

                // Fill bar
                if (pct != null && fillRatio > 0)
                  Container(
                    height: 8,
                    width: barWidth * fillRatio,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: AppRadius.pillBorder,
                    ),
                  ),

                // Threshold marker line
                Positioned(
                  left: thresholdX - 1,
                  top: -2,
                  child: Container(
                    width: 2,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.textPrimary.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
