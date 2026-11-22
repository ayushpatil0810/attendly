import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';

/// Compact session summary row styled after Apple HIG structured stat cards.
class CompactAttendanceStats extends StatelessWidget {
  const CompactAttendanceStats({super.key, required this.summary});

  final SemesterAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasBothComponents =
        summary.lectureConducted > 0 && summary.labConducted > 0;

    return Semantics(
      container: true,
      label:
          'Attendance session summary: ${summary.totalConducted} conducted, ${summary.totalPresent} present, ${summary.totalAbsent} absent',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.border.withValues(
              alpha: colors.isDark ? 0.4 : 0.6,
            ),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: colors.isDark ? 0.25 : 0.03,
              ),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Primary Session Counts Row (Conducted, Present)
            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'Conducted',
                    value: summary.totalConducted.toString(),
                    valueColor: colors.textPrimary,
                  ),
                ),
                Container(
                  width: 0.5,
                  height: 28,
                  color: colors.divider.withValues(
                    alpha: colors.isDark ? 0.5 : 0.7,
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'Present',
                    value: summary.totalPresent.toString(),
                    valueColor: colors.textPrimary,
                  ),
                ),
              ],
            ),

            // Component Breakdown (when both Lecture and Lab exist)
            if (hasBothComponents) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 0.5,
                color: colors.divider.withValues(
                  alpha: colors.isDark ? 0.5 : 0.7,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  _ComponentTag(
                    label: 'Lecture',
                    present: summary.lecturePresent,
                    conducted: summary.lectureConducted,
                    pct: summary.lecturePercentage,
                  ),
                  _ComponentTag(
                    label: 'Lab',
                    present: summary.labPresent,
                    conducted: summary.labConducted,
                    pct: summary.labPercentage,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      label: '$label: $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.metricLarge.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentTag extends StatelessWidget {
  const _ComponentTag({
    required this.label,
    required this.present,
    required this.conducted,
    this.pct,
  });

  final String label;
  final int present;
  final int conducted;
  final double? pct;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pctText = pct != null
        ? ' • ${pct == pct!.roundToDouble() ? pct!.toInt() : pct!.toStringAsFixed(1)}%'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle.withValues(
          alpha: colors.isDark ? 0.6 : 0.8,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $present/$conducted$pctText',
        style: AppTypography.caption2.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
