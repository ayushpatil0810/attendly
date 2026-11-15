import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Primary Session Counts Row
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Conducted',
                  value: summary.totalConducted.toString(),
                  color: AppColors.ink,
                  icon: AppIcons.calendar,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              Expanded(
                child: _StatColumn(
                  label: 'Present',
                  value: summary.totalPresent.toString(),
                  color: AppColors.brandMint,
                  icon: AppIcons.check,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              Expanded(
                child: _StatColumn(
                  label: 'Absent',
                  value: summary.totalAbsent.toString(),
                  color: AppColors.brandCoral,
                  icon: AppIcons.close,
                ),
              ),
            ],
          ),

          // Component Breakdown Row (if both Lecture and Lab exist)
          if (hasBothComponents) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                _ComponentBadge(
                  label: 'Lecture',
                  present: summary.lecturePresent,
                  conducted: summary.lectureConducted,
                  pct: summary.lecturePercentage,
                  icon: AppIcons.lecture,
                ),
                _ComponentBadge(
                  label: 'Lab',
                  present: summary.labPresent,
                  conducted: summary.labConducted,
                  pct: summary.labPercentage,
                  icon: AppIcons.lab,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final dynamic icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon,
                size: 14,
                color: color == AppColors.brandMint
                    ? const Color(0xFF1E826D)
                    : (color == AppColors.brandCoral
                          ? const Color(0xFFD63B48)
                          : AppColors.mutedInk),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTypography.metricLarge.copyWith(
              color: color == AppColors.brandMint
                  ? const Color(0xFF1E826D)
                  : (color == AppColors.brandCoral
                        ? const Color(0xFFD63B48)
                        : color),
              fontSize: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _ComponentBadge extends StatelessWidget {
  const _ComponentBadge({
    required this.label,
    required this.present,
    required this.conducted,
    required this.pct,
    required this.icon,
  });

  final String label;
  final int present;
  final int conducted;
  final double? pct;
  final dynamic icon;

  @override
  Widget build(BuildContext context) {
    final pctStr = pct != null
        ? (pct == pct!.roundToDouble()
              ? '${pct!.toInt()}%'
              : '${pct!.toStringAsFixed(1)}%')
        : '—';

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 16, color: AppColors.brandViolet),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$present/$conducted ($pctStr)',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.mutedInk,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
