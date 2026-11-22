import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/theme/app_colors.dart';
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

    return AppleInsetGroup(
      header: 'Lecture vs. Lab Breakdown',
      margin: EdgeInsets.zero,
      children: [
        for (final subject in multiComponentSubjects)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: _SubjectComponentComparison(
              subject: subject,
              threshold: threshold,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subject.subjectName,
          style: AppTypography.itemTitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        if (lec != null)
          _ComponentBarRow(
            label: 'Lecture',
            summary: lec,
            threshold: threshold,
          ),
        const SizedBox(height: 10),
        if (lab != null)
          _ComponentBarRow(
            label: 'Lab',
            summary: lab,
            threshold: threshold,
          ),
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
        ? (meetsTarget ? colors.present : colors.absent)
        : colors.track;
    final statColor = hasData
        ? (meetsTarget ? colors.present : colors.absent)
        : colors.textSecondary;

    final fillRatio = hasData ? (pct! / 100.0).clamp(0.0, 1.0) : 0.0;

    final semanticLabel = '$label: ${hasData ? "${pct!.toStringAsFixed(1)}%" : "Not available"}. '
        '${summary.presentCount} of ${summary.conductedCount} classes attended.';

    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: semanticLabel,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        hasData
                            ? '(${summary.presentCount}/${summary.conductedCount})'
                            : '(No sessions)',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontFeatures: const [FontFeature.tabularFigures()],
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
                style: AppTypography.subhead.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: statColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Sleek 5px progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return ClipRRect(
                borderRadius: BorderRadius.circular(2.5),
                child: Stack(
                  children: [
                    Container(
                      height: 5,
                      width: width,
                      color: colors.track.withValues(
                        alpha: colors.isDark ? 0.35 : 0.22,
                      ),
                    ),
                    if (hasData && fillRatio > 0)
                      Container(
                        height: 5,
                        width: width * fillRatio,
                        color: barColor,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
}
