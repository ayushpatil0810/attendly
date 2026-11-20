import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/app/router/route_names.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';

/// Card showing safe absences buffer or required recovery count with Apple HIG card styling.
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

    final colors = context.colors;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.accentMint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headline.copyWith(
                        fontSize: 16,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                bodyText,
                style: AppTypography.subhead.copyWith(
                  color: colors.textSecondary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push(RouteNames.simulatorPath);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      AppIcons.insights,
                      size: 14,
                      color: colors.brandPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Simulate What-if',
                      style: AppTypography.caption1.copyWith(
                        color: colors.brandPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    AppIcon(
                      AppIcons.forward,
                      size: 11,
                      color: colors.brandPrimary,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.accentCoral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headline.copyWith(
                        fontSize: 16,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppTypography.subhead.copyWith(
                  color: colors.textSecondary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push(RouteNames.simulatorPath);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      AppIcons.insights,
                      size: 14,
                      color: colors.brandPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Simulate What-if',
                      style: AppTypography.caption1.copyWith(
                        color: colors.brandPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    AppIcon(
                      AppIcons.forward,
                      size: 11,
                      color: colors.brandPrimary,
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
