import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';

class SafeAbsenceRecoveryCard extends StatelessWidget {
  const SafeAbsenceRecoveryCard({super.key, required this.summary});

  final SemesterAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.totalConducted == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.softLavender,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.pureWhite,
                shape: BoxShape.circle,
              ),
              child: const AppIcon(
                AppIcons.info,
                size: 20,
                color: AppColors.brandViolet,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Insights',
                    style: AppTypography.itemTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Safe absence and recovery insights will appear once classes are recorded.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (summary.calculationMethod ==
        AttendanceCalculationMethod.componentAverage) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.softLavender,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.pureWhite,
                shape: BoxShape.circle,
              ),
              child: const AppIcon(
                AppIcons.info,
                size: 20,
                color: AppColors.brandViolet,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Component Average Policy',
                    style: AppTypography.itemTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Under 50/50 weighting, safe absences and recovery depend on future Lecture and Lab mix.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Raw Combined
    final isAtOrAbove = summary.thresholdStatus == ThresholdStatus.meeting;

    if (isAtOrAbove) {
      final safe = summary.safeAbsenceResult.safeAbsences ?? 0;
      final unit = safe == 1 ? 'class' : 'classes';
      final title = safe > 0
          ? '$safe Safe Absence${safe == 1 ? '' : 's'}'
          : 'At Target Threshold';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.softMint,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: const Color(0xFFC7EFE6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.pureWhite,
                shape: BoxShape.circle,
              ),
              child: const AppIcon(
                AppIcons.check,
                size: 20,
                color: Color(0xFF1E826D),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.itemTitle.copyWith(
                      color: const Color(0xFF135B4C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    safe > 0
                        ? 'You can miss up to $safe $unit while maintaining your ${summary.thresholdPercent}% target.'
                        : 'Any additional absence will drop your attendance below ${summary.thresholdPercent}%.',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF1E826D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Below threshold -> Recovery required
      final recovery = summary.recoveryResult;
      final isImpossible = recovery.isImpossible;
      final needed = recovery.requiredConsecutivePresents ?? 0;
      final unit = needed == 1 ? 'class' : 'classes';

      final title = isImpossible
          ? 'Cannot Reach 100%'
          : 'Needs $needed Consecutive Present${needed == 1 ? '' : 's'}';

      final message = isImpossible
          ? 'At 100% threshold, past absences make it mathematically impossible to reach 100% through attendance alone.'
          : 'Attend the next $needed $unit with zero absences to reach ${summary.thresholdPercent}% attendance.';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.softCoral,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: const Color(0xFFFFD4D8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.pureWhite,
                shape: BoxShape.circle,
              ),
              child: const AppIcon(
                AppIcons.alert,
                size: 20,
                color: Color(0xFFD63B48),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.itemTitle.copyWith(
                      color: const Color(0xFF8C1D26),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFFD63B48),
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
}
