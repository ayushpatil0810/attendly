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
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.xlBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withAlpha(6),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.softLavender,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const AppIcon(
              AppIcons.calendar,
              size: 28,
              color: AppColors.brandViolet,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasSubjects ? 'No Classes Recorded Yet' : 'Start Semester Setup',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasSubjects
                ? 'Your attendance summary, safe absence allowances, and recovery targets will calculate automatically once classes are logged.'
                : 'Add your enrolled courses to this semester so you can start logging attendance.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedInk),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (hasSubjects)
            AppButton(
              label: 'Quick Log Session',
              icon: const AppIcon(
                AppIcons.add,
                size: 18,
                color: AppColors.pureWhite,
              ),
              onPressed: () {
                showQuickLogSheet(context: context);
              },
            )
          else
            AppButton(
              label: 'Add First Subject',
              icon: const AppIcon(
                AppIcons.add,
                size: 18,
                color: AppColors.pureWhite,
              ),
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
