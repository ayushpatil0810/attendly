import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/presentation/widgets/quick_log_sheet.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/subjects/presentation/widgets/subject_form_sheet.dart';

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.semester,
    required this.hasSubjects,
  });

  final Semester semester;
  final bool hasSubjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clean, unboxed icon (no colored bubble container)
          const AppIcon(
            AppIcons.calendar,
            size: 32,
            color: AppColors.brandViolet,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasSubjects ? 'No Classes Recorded Yet' : 'Start Semester Setup',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            hasSubjects
                ? 'Log your first class session to calculate safe absences and track progress.'
                : 'Add your courses to this semester to begin tracking attendance.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.mutedInk,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasSubjects)
            AppButton(
              label: 'Quick Log Session',
              icon: const AppIcon(
                AppIcons.add,
                size: 16,
                color: AppColors.pureWhite,
              ),
              size: AppButtonSize.small,
              onPressed: () {
                showQuickLogSheet(context: context);
              },
            )
          else
            AppButton(
              label: 'Add First Subject',
              icon: const AppIcon(
                AppIcons.add,
                size: 16,
                color: AppColors.pureWhite,
              ),
              size: AppButtonSize.small,
              onPressed: () {
                showAppBottomSheet(
                  context: context,
                  title: 'Add Subject',
                  child: SubjectFormSheet(semesterId: semester.id),
                );
              },
            ),
        ],
      ),
    );
  }
}
