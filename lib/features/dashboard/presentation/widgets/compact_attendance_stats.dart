import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';

class CompactAttendanceStats extends StatelessWidget {
  const CompactAttendanceStats({super.key, required this.summary});

  final SemesterAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasBothComponents =
        summary.lectureConducted > 0 && summary.labConducted > 0;

    return Semantics(
      container: true,
      label:
          'Attendance session summary: ${summary.totalConducted} conducted, ${summary.totalPresent} present, ${summary.totalAbsent} absent',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            // Primary Session Counts Row — Open, clean, uncluttered
            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'Conducted',
                    value: summary.totalConducted.toString(),
                    valueColor: AppColors.ink,
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.divider),
                Expanded(
                  child: _StatColumn(
                    label: 'Present',
                    value: summary.totalPresent.toString(),
                    valueColor: AppColors.inkMint,
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.divider),
                Expanded(
                  child: _StatColumn(
                    label: 'Absent',
                    value: summary.totalAbsent.toString(),
                    valueColor: AppColors.inkCoral,
                  ),
                ),
              ],
            ),

            // Component Breakdown (when both Lecture and Lab exist)
            if (hasBothComponents) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: AppSpacing.xs + 2),
              Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _ComponentBadge(
                    label: 'Lecture',
                    present: summary.lecturePresent,
                    conducted: summary.lectureConducted,
                    pct: summary.lecturePercentage,
                  ),
                  _ComponentBadge(
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
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentBadge extends StatelessWidget {
  const _ComponentBadge({
    required this.label,
    required this.present,
    required this.conducted,
    required this.pct,
  });

  final String label;
  final int present;
  final int conducted;
  final double? pct;

  @override
  Widget build(BuildContext context) {
    final pctStr = pct != null
        ? (pct == pct!.roundToDouble()
              ? '${pct!.toInt()}%'
              : '${pct!.toStringAsFixed(1)}%')
        : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softLavender,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.inkViolet,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: '$present/$conducted ($pctStr)',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
