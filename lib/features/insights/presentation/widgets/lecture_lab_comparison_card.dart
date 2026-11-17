import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/component_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';

class LectureLabComparisonCard extends StatelessWidget {
  const LectureLabComparisonCard({
    super.key,
    required this.subjectSummaries,
    required this.threshold,
  });

  final List<SubjectAttendanceSummary> subjectSummaries;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    // Only subjects with BOTH components enabled
    final multiComponentSubjects = subjectSummaries
        .where((s) => s.lectureEnabled && s.labEnabled)
        .toList();

    if (multiComponentSubjects.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lecture vs. Lab Breakdown',
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: multiComponentSubjects.length,
            separatorBuilder: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(color: colors.divider, height: 1),
            ),
            itemBuilder: (context, index) {
              final subject = multiComponentSubjects[index];
              return _SubjectComponentComparison(
                subject: subject,
                threshold: threshold,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubjectComponentComparison extends StatelessWidget {
  const _SubjectComponentComparison({
    required this.subject,
    required this.threshold,
  });

  final SubjectAttendanceSummary subject;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lec = subject.lectureSummary;
    final lab = subject.labSummary;

    final lecPct = lec?.percentage;
    final labPct = lab?.percentage;

    String? diffText;
    Color diffBg = colors.brandPrimarySoft;
    Color diffFg = colors.brandPrimaryInk;

    if (lecPct != null && labPct != null) {
      final diff = labPct - lecPct;
      if (diff.abs() < 0.05) {
        diffText = 'Equal (${lecPct.toStringAsFixed(0)}%)';
        diffBg = colors.accentMintSoft;
        diffFg = colors.accentMintInk;
      } else if (diff > 0) {
        diffText = 'Lab +${diff.toStringAsFixed(0)}% vs Lecture';
        diffBg = colors.accentMintSoft;
        diffFg = colors.accentMintInk;
      } else {
        diffText = 'Lecture +${(-diff).toStringAsFixed(0)}% vs Lab';
        diffBg = colors.accentCoralSoft;
        diffFg = colors.accentCoralInk;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject header with variance badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                subject.subjectName,
                style: AppTypography.itemTitle.copyWith(
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (diffText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: diffBg,
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Text(
                  diffText,
                  style: AppTypography.labelSmall.copyWith(
                    color: diffFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Paired component comparison rows
        if (lec != null)
          _ComponentBarRow(
            label: 'Lecture',
            summary: lec,
            threshold: threshold,
          ),
        const SizedBox(height: 8),
        if (lab != null)
          _ComponentBarRow(label: 'Lab', summary: lab, threshold: threshold),
      ],
    );
  }
}

class _ComponentBarRow extends StatelessWidget {
  const _ComponentBarRow({
    required this.label,
    required this.summary,
    required this.threshold,
  });

  final String label;
  final ComponentAttendanceSummary summary;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasData = summary.isAvailable && summary.percentage != null;
    final pct = summary.percentage;
    final meetsTarget = hasData && pct! >= (threshold * 100.0 - 1e-9);

    final barColor = hasData
        ? (meetsTarget ? colors.accentMint : colors.accentCoral)
        : colors.track;

    final fillRatio = hasData ? (pct! / 100.0).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      hasData
                          ? '(${summary.presentCount}P / ${summary.absentCount}A • ${summary.conductedCount} total)'
                          : '(No sessions)',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hasData ? '${pct!.toStringAsFixed(1)}%' : 'Not available',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: hasData
                    ? (meetsTarget
                          ? colors.accentMintInk
                          : colors.accentCoralInk)
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Bar
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Container(
              height: 6,
              width: width,
              decoration: BoxDecoration(
                color: colors.track,
                borderRadius: AppRadius.pillBorder,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 6,
                  width: width * fillRatio,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: AppRadius.pillBorder,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
