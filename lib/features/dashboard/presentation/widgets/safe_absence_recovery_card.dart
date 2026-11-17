import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
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
      return const SizedBox.shrink();
    }

    if (summary.calculationMethod ==
        AttendanceCalculationMethod.componentAverage) {
      return const SizedBox.shrink();
    }

    // Raw Combined
    final isAtOrAbove = summary.thresholdStatus == ThresholdStatus.meeting;

    if (isAtOrAbove) {
      final safe = summary.safeAbsenceResult.safeAbsences ?? 0;
      final unit = safe == 1 ? 'class' : 'classes';
      final title = safe > 0
          ? '$safe Safe Absence${safe == 1 ? '' : 's'}'
          : 'At Target Threshold';

      final bodyText = safe > 0
          ? 'You can miss up to $safe $unit while maintaining your ${summary.thresholdPercent}% target.'
          : 'Any additional absence will drop your attendance below ${summary.thresholdPercent}%.';

      return Semantics(
        container: true,
        label: '$title: $bodyText',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.brandMint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.itemTitle.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                bodyText,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutedInk,
                ),
              ),
            ],
          ),
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

      return Semantics(
        container: true,
        label: '$title: $message',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.brandCoral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.itemTitle.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutedInk,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
