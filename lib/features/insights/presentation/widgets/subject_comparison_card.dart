import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/theme/app_colors.dart';
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

    return AppleInsetGroup(
      header: 'Subject Comparison',
      margin: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Subject Count
              Text(
                '${sortedSubjects.length} Subject${sortedSubjects.length == 1 ? '' : 's'}',
                style: AppTypography.caption1.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),

              // Vertical Bar Comparison Chart
              _VerticalSubjectBarChart(
                subjects: sortedSubjects,
                threshold: threshold,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerticalSubjectBarChart extends StatelessWidget {
  const _VerticalSubjectBarChart({
    required this.subjects,
    required this.threshold,
  });

  final List<SubjectAttendanceSummary> subjects;
  final double threshold;

  static const double _trackHeight = 110.0;
  static const double _topLabelHeight = 22.0;
  static const double _bottomSectionHeight = 42.0;
  static const double _minColWidth = 58.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final neededWidth = subjects.length * _minColWidth;
        final isScrollable = neededWidth > availableWidth;
        final colWidth = isScrollable
            ? _minColWidth
            : (availableWidth / subjects.length);
        final chartWidth = isScrollable ? neededWidth : availableWidth;
        final targetY = _topLabelHeight +
            ((1.0 - threshold.clamp(0.0, 1.0)) * _trackHeight);

        final chartContent = SizedBox(
          width: chartWidth,
          height: _topLabelHeight + _trackHeight + _bottomSectionHeight,
          child: Stack(
            children: [
              // Target dashed line spanning the chart width
              Positioned(
                left: 0,
                right: 0,
                top: targetY,
                child: SizedBox(
                  height: 1,
                  child: CustomPaint(
                    painter: _TargetLinePainter(
                      color: colors.textPrimary.withValues(
                        alpha: colors.isDark ? 0.35 : 0.22,
                      ),
                    ),
                  ),
                ),
              ),

              // The Vertical Bar Columns
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final subject in subjects)
                    SizedBox(
                      width: colWidth,
                      child: _VerticalBarItem(
                        summary: subject,
                        threshold: threshold,
                        trackHeight: _trackHeight,
                        topLabelHeight: _topLabelHeight,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );

        if (isScrollable) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: chartContent,
          );
        }
        return chartContent;
      },
    );
  }
}

class _VerticalBarItem extends StatelessWidget {
  const _VerticalBarItem({
    required this.summary,
    required this.threshold,
    required this.trackHeight,
    required this.topLabelHeight,
  });

  final SubjectAttendanceSummary summary;
  final double threshold;
  final double trackHeight;
  final double topLabelHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAvailable = summary.isAvailable;
    final isProvisional = summary.isProvisional;
    final pct = summary.percentage;

    Color barColor;
    Color valueColor;
    if (summary.meetsThreshold) {
      barColor = colors.accentMint;
      valueColor = colors.accentMint;
    } else if (summary.isBelowThreshold) {
      barColor = colors.accentCoral;
      valueColor = colors.accentCoral;
    } else if (isProvisional) {
      barColor = colors.accentPeach;
      valueColor = colors.accentPeach;
    } else {
      barColor = colors.track;
      valueColor = colors.textSecondary;
    }

    final double fillRatio = pct != null ? (pct / 100.0).clamp(0.0, 1.0) : 0.0;

    final String topLabel = isAvailable && pct != null
        ? '${pct.toStringAsFixed(0)}%'
        : (isProvisional ? 'Prov' : '—');

    final semanticLabel =
        '${summary.subjectName}: ${summary.formattedPercentage}. '
        '${summary.totalPresent} of ${summary.totalConducted} classes attended.';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Tooltip(
        message:
            '${summary.subjectName}\n${summary.formattedPercentage} (${summary.totalPresent}/${summary.totalConducted})',
        child: Column(
          children: [
            // Top Percentage Label
            SizedBox(
              height: topLabelHeight,
              child: Center(
                child: Text(
                  topLabel,
                  style: AppTypography.caption1.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),

            // Vertical Pill Bar
            SizedBox(
              height: trackHeight,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Full Height Track
                      Container(
                        width: 18,
                        height: trackHeight,
                        color: colors.track.withValues(
                          alpha: colors.isDark ? 0.35 : 0.22,
                        ),
                      ),

                      // Animated / Measured Fill Bar
                      if (pct != null && fillRatio > 0)
                        Container(
                          width: 18,
                          height: (fillRatio * trackHeight).clamp(0.0, trackHeight),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Subject Name (max 1 line with ellipsis)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                summary.subjectName,
                style: AppTypography.caption1.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),

            // Attendance Count Ratio
            Text(
              summary.totalConducted > 0
                  ? '${summary.totalPresent}/${summary.totalConducted}'
                  : '—',
              style: AppTypography.caption2.copyWith(
                fontSize: 10,
                color: colors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetLinePainter extends CustomPainter {
  const _TargetLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(math.min(startX + dashWidth, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TargetLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
