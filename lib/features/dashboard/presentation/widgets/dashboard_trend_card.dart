import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_theme_colors.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_trend_point.dart';

class DashboardTrendCard extends StatelessWidget {
  const DashboardTrendCard({
    super.key,
    required this.trendPoints,
    required this.threshold,
    this.header = 'Attendance Trend',
  });

  final List<AttendanceTrendPoint> trendPoints;
  final double threshold;
  final String? header;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppleInsetGroup(
      header: header,
      margin: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: trendPoints.length < 2
              ? _buildEmptyState(colors)
              : _buildTrendChart(colors),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeColors colors) {
    return Semantics(
      container: true,
      label:
          'Attendance Trend: More Data Needed. Trend visualization appears after sessions across at least two dates are logged.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More Data Needed',
            style: AppTypography.itemTitle.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Trend visualization appears after sessions across at least two dates are logged.',
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(AppThemeColors colors) {
    final firstDate = trendPoints.first.date;
    final lastDate = trendPoints.last.date;
    final dateFormat = DateFormat('MMM d');
    final rangeText =
        '${dateFormat.format(firstDate)} – ${dateFormat.format(lastDate)}';
    final currentPct = trendPoints.last.cumulativePercentage;

    return Semantics(
      container: true,
      label:
          'Attendance Trend: $rangeText. Latest attendance: ${currentPct.toStringAsFixed(1)} percent against ${(threshold * 100).round()} percent target.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range and current cumulative attendance
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              Text(
                rangeText,
                style: AppTypography.labelSmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Latest: ',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    '${currentPct.toStringAsFixed(1)}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: currentPct >= threshold * 100 - 1e-9
                          ? colors.present
                          : colors.absent,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trend Chart with Y-axis labels & Target Line Pill
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtle Y-axis percentage labels
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '100%',
                        style: AppTypography.caption2.copyWith(
                          color: colors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '50%',
                        style: AppTypography.caption2.copyWith(
                          color: colors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '0%',
                        style: AppTypography.caption2.copyWith(
                          color: colors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Chart Canvas with Dashed Target Line and Target Pill
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const topPad = 8.0;
                      const bottomPad = 8.0;
                      final chartHeight = constraints.maxHeight;
                      final innerHeight = chartHeight - topPad - bottomPad;
                      final targetRatio = threshold.clamp(0.0, 1.0);
                      final targetY =
                          chartHeight - bottomPad - (targetRatio * innerHeight);

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _TrendLinePainter(
                                  points: trendPoints,
                                  threshold: threshold,
                                  lineColor: colors.brandPrimary,
                                  dividerColor: colors.divider,
                                  dotBorderColor: colors.surface,
                                  topPadding: topPad,
                                  bottomPadding: bottomPad,
                                ),
                              ),
                            ),
                          ),
                          // Small pill on the dashed target threshold line
                          Positioned(
                            right: 0,
                            top: (targetY - 10).clamp(0.0, chartHeight - 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: colors.border.withValues(
                                    alpha: colors.isDark ? 0.4 : 0.6,
                                  ),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: colors.isDark ? 0.25 : 0.05,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${(threshold * 100).round()}% Target',
                                style: AppTypography.caption2.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({
    required this.points,
    required this.threshold,
    required this.lineColor,
    required this.dividerColor,
    required this.dotBorderColor,
    this.topPadding = 8.0,
    this.bottomPadding = 8.0,
  });

  final List<AttendanceTrendPoint> points;
  final double threshold;
  final Color lineColor;
  final Color dividerColor;
  final Color dotBorderColor;
  final double topPadding;
  final double bottomPadding;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartHeight = size.height - topPadding - bottomPadding;

    // Y mapping: 0% is at bottom, 100% is at top
    double getY(double pct) {
      final ratio = (pct / 100.0).clamp(0.0, 1.0);
      return size.height - bottomPadding - (ratio * chartHeight);
    }

    // Target threshold reference line
    final thresholdY = getY(threshold * 100);
    final dashPaint = Paint()
      ..color = dividerColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, thresholdY),
        Offset(startX + dashWidth, thresholdY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Coordinates of trend points
    final coordinates = <Offset>[];
    final stepX = size.width / (points.length - 1);

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = getY(points[i].cumulativePercentage);
      coordinates.add(Offset(x, y));
    }

    // Path for gradient fill under the line
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(coordinates.first.dx, coordinates.first.dy);

    for (var i = 1; i < coordinates.length; i++) {
      fillPath.lineTo(coordinates[i].dx, coordinates[i].dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.22),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..isAntiAlias = true;

    canvas.drawPath(fillPath, fillPaint);

    // Line Path
    final linePath = Path();
    linePath.moveTo(coordinates.first.dx, coordinates.first.dy);
    for (var i = 1; i < coordinates.length; i++) {
      linePath.lineTo(coordinates[i].dx, coordinates[i].dy);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(linePath, linePaint);

    // Draw dots at each point
    final dotBorderPaint = Paint()
      ..color = dotBorderColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final coord in coordinates) {
      canvas.drawCircle(coord, 4.0, dotBorderPaint);
      canvas.drawCircle(coord, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.threshold != threshold ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.dividerColor != dividerColor ||
        oldDelegate.dotBorderColor != dotBorderColor ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.bottomPadding != bottomPadding;
  }
}
