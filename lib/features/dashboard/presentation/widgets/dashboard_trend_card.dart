import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendance Trend', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: trendPoints.length < 2
              ? _buildEmptyState()
              : _buildTrendChart(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.softLavender,
            shape: BoxShape.circle,
          ),
          child: const AppIcon(
            AppIcons.insights,
            size: 20,
            color: AppColors.brandViolet,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('More Data Needed', style: AppTypography.itemTitle),
              const SizedBox(height: 2),
              Text(
                'Trend visualization appears after sessions across at least two dates are logged.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutedInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    final firstDate = trendPoints.first.date;
    final lastDate = trendPoints.last.date;
    final dateFormat = DateFormat('MMM d');
    final rangeText =
        '${dateFormat.format(firstDate)} – ${dateFormat.format(lastDate)}';
    final currentPct = trendPoints.last.cumulativePercentage;

    return Column(
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
                color: AppColors.mutedInk,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Latest: ',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mutedInk,
                  ),
                ),
                Text(
                  '${currentPct.toStringAsFixed(1)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: currentPct >= threshold * 100 - 1e-9
                        ? const Color(0xFF1E826D)
                        : const Color(0xFFD63B48),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Custom Sparkline Painter
        SizedBox(
          height: 90,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendLinePainter(
              points: trendPoints,
              threshold: threshold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Target guide legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 12,
              height: 2,
              color: AppColors.ink.withAlpha(128),
            ),
            const SizedBox(width: 6),
            Text(
              '${(threshold * 100).round()}% Target',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mutedInk,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({required this.points, required this.threshold});

  final List<AttendanceTrendPoint> points;
  final double threshold;

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

    // Threshold dashed line
    final thresholdY = getY(threshold * 100);
    final dashPaint = Paint()
      ..color = AppColors.divider
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
          AppColors.brandViolet.withAlpha(50),
          AppColors.brandViolet.withAlpha(0),
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
      ..color = AppColors.brandViolet
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Draw dots at each point
    final dotBorderPaint = Paint()
      ..color = AppColors.pureWhite
      ..style = PaintingStyle.fill;

    for (final coord in coordinates) {
      canvas.drawCircle(coord, 4.0, dotBorderPaint);

      final dotPaint = Paint()
        ..color = AppColors.brandViolet
        ..style = PaintingStyle.fill;
      canvas.drawCircle(coord, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.threshold != threshold;
  }
}
