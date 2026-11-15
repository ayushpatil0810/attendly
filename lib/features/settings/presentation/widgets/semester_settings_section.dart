import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_segmented_control.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_form_sheet.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_switcher_sheet.dart';

class SemesterSettingsSection extends ConsumerWidget {
  const SemesterSettingsSection({super.key, required this.activeSemester});

  final Semester? activeSemester;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (activeSemester == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No active semester selected.',
              style: AppTypography.itemTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Select an existing semester or create a new one to manage threshold and calculation policies.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mutedInk,
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Manage Semesters',
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              onPressed: () {
                showAppBottomSheet(
                  context: context,
                  title: 'Semesters',
                  child: const SemesterSwitcherSheet(),
                );
              },
            ),
          ],
        ),
      );
    }

    final semester = activeSemester!;
    final thresholdPercent = (semester.attendanceThreshold * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Semester Header & Switcher Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE SEMESTER',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.brandViolet,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      semester.name,
                      style: AppTypography.screenTitle.copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Switch',
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                icon: const AppIcon(
                  AppIcons.settings,
                  size: 16,
                  color: AppColors.brandViolet,
                ),
                onPressed: () {
                  showAppBottomSheet(
                    context: context,
                    title: 'Semesters',
                    child: const SemesterSwitcherSheet(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Attendance Threshold
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Threshold', style: AppTypography.itemTitle),
                  const SizedBox(height: 2),
                  Text(
                    'Required attendance target',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.mutedInk,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Text(
                  '$thresholdPercent%',
                  style: AppTypography.metricMedium.copyWith(
                    fontSize: 15,
                    color: AppColors.brandViolet,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Threshold Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.brandViolet,
              inactiveTrackColor: AppColors.track,
              thumbColor: AppColors.brandViolet,
              overlayColor: AppColors.brandViolet.withOpacity(0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: semester.attendanceThreshold,
              min: 0.50,
              max: 0.95,
              divisions: 45,
              onChanged: (newVal) async {
                final rounded = (newVal * 100).round() / 100.0;
                if (rounded != semester.attendanceThreshold) {
                  final updated = semester.copyWith(
                    attendanceThreshold: rounded,
                  );
                  await ref
                      .read(semesterControllerProvider.notifier)
                      .updateSemester(updated);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Calculation Method Configuration
          Text('Calculation Method', style: AppTypography.itemTitle),
          const SizedBox(height: 2),
          Text(
            'Defines how lecture and lab attendance are calculated',
            style: AppTypography.labelSmall.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: 12),

          AppSegmentedControl<AttendanceCalculationMethod>(
            selectedValue: semester.calculationMethod,
            items: [
              SegmentItem(
                value: AttendanceCalculationMethod.rawCombined,
                label: 'Raw Combined',
                icon: const AppIcon(AppIcons.lecture, size: 16),
              ),
              SegmentItem(
                value: AttendanceCalculationMethod.componentAverage,
                label: '50/50 Average',
                icon: const AppIcon(AppIcons.lab, size: 16),
              ),
            ],
            onChanged: (newMethod) async {
              if (newMethod != semester.calculationMethod) {
                final updated = semester.copyWith(calculationMethod: newMethod);
                await ref
                    .read(semesterControllerProvider.notifier)
                    .updateSemester(updated);
              }
            },
          ),
          const SizedBox(height: 14),

          // Edit Semester full details link
          Center(
            child: AppButton(
              label: 'Edit Semester Name & Dates',
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              onPressed: () {
                showAppBottomSheet(
                  context: context,
                  title: 'Edit Semester',
                  child: SemesterFormSheet(initialSemester: semester),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
