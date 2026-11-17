import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_theme_colors.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_trend_point.dart';

class DashboardTrendCard extends StatelessWidget {
  const DashboardTrendCard({
    super.key,
    required this.trendPoints,
    required this.threshold,
  });

  final List<AttendanceTrendPoint> trendPoints;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Trend',
          style: AppTypography.sectionTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.mdBorder,
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
          child: trendPoints.length < 2
              ? _buildEmptyState()
              : _buildTrendChart(colors),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Semantics(
      container: true,
      label: 'Attendance Trend: More Data Needed. Trend visualization appears after sessions across at least two dates are logged.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.brandViolet,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('More Data Needed', style: AppTypography.itemTitle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Trend visualization appears after sessions across at least two dates are logged.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.mutedInk),
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
                          ? colors.accentMintInk
                          : colors.accentCoralInk,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Sparkline Painter
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendLinePainter(
                points: trendPoints,
                threshold: threshold,
                lineColor: colors.brandPrimary,
                dividerColor: colors.divider,
                dotBorderColor: colors.surface,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Target guide legend matching the dashed line
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 12,
                height: 2,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 6),
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
  });

  final List<AttendanceTrendPoint> points;
  final double threshold;
  final Color lineColor;
  final Color dividerColor;
  final Color dotBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const topPadding = 6.0;
    const bottomPadding = 6.0;
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
        oldDelegate.dotBorderColor != dotBorderColor;
  }
}
