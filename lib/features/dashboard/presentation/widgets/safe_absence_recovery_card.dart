import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/app/router/route_names.dart';
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
      return Semantics(
        container: true,
        label: 'Attendance Insights: Safe absence and recovery insights will appear once classes are recorded.',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.softLavender,
            borderRadius: AppRadius.lgBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: AppIcon(
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
        ),
      );
    }

    if (summary.calculationMethod ==
        AttendanceCalculationMethod.componentAverage) {
      return Semantics(
        container: true,
        label:
            'Depends on the next classes. Lecture and lab each count for half, so how many you can miss depends on whether those classes are lectures or labs.',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.softLavender,
            borderRadius: AppRadius.lgBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: AppIcon(
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
                      'Depends on the next classes',
                      style: AppTypography.itemTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lecture and lab each count for half, so how many you can miss depends on whether those classes are lectures or labs.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: 'Open Attendance Simulator',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push(RouteNames.simulatorPath),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Open Simulator',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.inkViolet,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const AppIcon(
                                  AppIcons.forward,
                                  size: 14,
                                  color: AppColors.brandViolet,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            color: AppColors.softMint,
            borderRadius: AppRadius.lgBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: AppIcon(
                  AppIcons.check,
                  size: 20,
                  color: AppColors.inkMint,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bodyText,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkMint,
                      ),
                    ),
                  ],
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
            color: AppColors.softCoral,
            borderRadius: AppRadius.lgBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: AppIcon(
                  AppIcons.alert,
                  size: 20,
                  color: AppColors.inkCoral,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkCoral,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
