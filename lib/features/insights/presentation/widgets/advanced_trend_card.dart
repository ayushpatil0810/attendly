import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_theme_colors.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_trend_point.dart';

class AdvancedTrendCard extends StatelessWidget {
  const AdvancedTrendCard({
    super.key,
    required this.trendPoints,
    required this.threshold,
  });

  final List<AttendanceTrendPoint> trendPoints;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppleInsetGroup(
      header: 'Attendance History & Trend',
      margin: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: trendPoints.length < 2
              ? _buildEmptyState(colors)
              : _buildTrendChart(colors),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeColors colors) {
    return Row(
      children: [
        AppIcon(
          AppIcons.insights,
          size: 24,
          color: colors.textSecondary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'More Data Needed',
                style: AppTypography.itemTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Attendance trend requires sessions recorded across at least two different dates.',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart(AppThemeColors colors) {
    final firstDate = trendPoints.first.date;
    final lastDate = trendPoints.last.date;
    final dateFormat = DateFormat('MMM d');
    final rangeText =
        '${dateFormat.format(firstDate)} – ${dateFormat.format(lastDate)}';
    final latestPct = trendPoints.last.cumulativePercentage;
    final meetsTarget = latestPct >= (threshold * 100.0 - 1e-9);

    final semanticLabel =
        'Attendance History & Trend: $rangeText across ${trendPoints.length} recording dates. '
        'Latest cumulative attendance: ${latestPct.toStringAsFixed(1)} percent against ${(threshold * 100).round()} percent target.';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range and current cumulative attendance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rangeText,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${trendPoints.length} active recording dates',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Latest  ',
                      style: AppTypography.caption1.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '${latestPct.toStringAsFixed(1)}%',
                      style: AppTypography.subhead.copyWith(
                        color: meetsTarget
                            ? colors.accentMint
                            : colors.accentCoral,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Trend Sparkline Painter
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _AdvancedTrendLinePainter(
                points: trendPoints,
                threshold: threshold,
                lineColor: colors.brandPrimary,
                dividerColor: colors.divider,
                dotBorderColor: colors.surface,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Target guide legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Chronological cumulative attendance',
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 2,
                    color: colors.textPrimary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(threshold * 100).round()}% Target',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdvancedTrendLinePainter extends CustomPainter {
  const _AdvancedTrendLinePainter({
    required this.points,
    required this.threshold,
    required this.lineColor,
    required this.dividerColor,
    required this.dotBorderColor,
  });

  final List<AttendanceTrendPoint> points;
  final double threshold;
  final Color lineColor;
  final Color dividerColor;
  final Color dotBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const topPadding = 10.0;
    const bottomPadding = 10.0;
    final chartHeight = size.height - topPadding - bottomPadding;

    double getY(double pct) {
      final ratio = (pct / 100.0).clamp(0.0, 1.0);
      return size.height - bottomPadding - (ratio * chartHeight);
    }

    // Threshold dashed line
    final thresholdY = getY(threshold * 100);
    final dashPaint = Paint()
      ..color = dividerColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

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

    // Defensive check: if points.length <= 1, no line can be interpolated
    if (points.length <= 1) {
      final y = getY(points.first.cumulativePercentage);
      final singleDot = Offset(size.width / 2, y);
      canvas.drawCircle(
        singleDot,
        4.0,
        Paint()..color = dotBorderColor,
      );
      canvas.drawCircle(
        singleDot,
        2.5,
        Paint()..color = lineColor,
      );
      return;
    }

    // Coordinates of trend points
    final coordinates = <Offset>[];
    final stepX = size.width / (points.length - 1);

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = getY(points[i].cumulativePercentage);
      coordinates.add(Offset(x, y));
    }

    // Gradient fill under the line
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
          lineColor.withValues(alpha: 0.20),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

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
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Draw dots at each point
    final dotBorderPaint = Paint()
      ..color = dotBorderColor
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (final coord in coordinates) {
      canvas.drawCircle(coord, 4.0, dotBorderPaint);
      canvas.drawCircle(coord, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AdvancedTrendLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.threshold != threshold ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.dividerColor != dividerColor ||
        oldDelegate.dotBorderColor != dotBorderColor;
  }
}
