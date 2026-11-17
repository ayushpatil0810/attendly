import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/preferences_service.dart';
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
import 'package:attendly/features/semesters/presentation/widgets/share_semester_qr_sheet.dart';

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
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No active semester selected.',
              style: AppTypography.itemTitle,
            ),
            const SizedBox(height: 6),
            Text(
              'Select an existing semester or create a new one to manage threshold and calculation policies.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mutedInk,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Manage Semesters',
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              onPressed: () {
                AppHaptics.selectionClick(ref);
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
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Semester Header & Switcher Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  AppIcons.subjects,
                  size: 18,
                  color: AppColors.inkViolet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            semester.name,
                            style: AppTypography.sectionTitle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softMint,
                            borderRadius: AppRadius.pillBorder,
                          ),
                          child: Text(
                            'Active',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.inkMint,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: AppIcon(
                  AppIcons.qrCode,
                  size: 18,
                  color: AppColors.brandViolet,
                ),
                tooltip: 'Share Semester via QR',
                onPressed: () {
                  AppHaptics.selectionClick(ref);
                  showShareSemesterQrSheet(
                    context: context,
                    semester: semester,
                  );
                },
              ),
              const SizedBox(width: 4),
              AppButton(
                label: 'Switch',
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                icon: AppIcon(
                  AppIcons.forward,
                  size: 14,
                  color: AppColors.brandViolet,
                ),
                onPressed: () {
                  AppHaptics.selectionClick(ref);
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
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Attendance Threshold Title & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Threshold',
                    style: AppTypography.itemTitle,
                  ),
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
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(
                    color: AppColors.brandViolet.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '$thresholdPercent%',
                  style: AppTypography.metricMedium.copyWith(
                    fontSize: 15,
                    color: AppColors.inkViolet,
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
              activeTrackColor: AppColors.inkViolet,
              inactiveTrackColor: AppColors.track,
              thumbColor: AppColors.inkViolet,
              overlayColor: AppColors.inkViolet.withValues(alpha: 0.12),
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
          const SizedBox(height: 4),

          // Quick Preset Chips (75%, 80%, 85%)
          Row(
            children: [
              Text(
                'Presets:',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              _ThresholdPresetChip(
                label: '75% (Standard)',
                value: 0.75,
                isSelected: (semester.attendanceThreshold - 0.75).abs() < 0.005,
                onTap: () async {
                  AppHaptics.selectionClick(ref);
                  final updated = semester.copyWith(attendanceThreshold: 0.75);
                  await ref
                      .read(semesterControllerProvider.notifier)
                      .updateSemester(updated);
                },
              ),
              const SizedBox(width: 6),
              _ThresholdPresetChip(
                label: '80%',
                value: 0.80,
                isSelected: (semester.attendanceThreshold - 0.80).abs() < 0.005,
                onTap: () async {
                  AppHaptics.selectionClick(ref);
                  final updated = semester.copyWith(attendanceThreshold: 0.80);
                  await ref
                      .read(semesterControllerProvider.notifier)
                      .updateSemester(updated);
                },
              ),
              const SizedBox(width: 6),
              _ThresholdPresetChip(
                label: '85%',
                value: 0.85,
                isSelected: (semester.attendanceThreshold - 0.85).abs() < 0.005,
                onTap: () async {
                  AppHaptics.selectionClick(ref);
                  final updated = semester.copyWith(attendanceThreshold: 0.85);
                  await ref
                      .read(semesterControllerProvider.notifier)
                      .updateSemester(updated);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Calculation Method Configuration
          const Text('Calculation Method', style: AppTypography.itemTitle),
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
                label: AttendanceCalculationMethod.rawCombined.displayName,
                icon: const AppIcon(AppIcons.lecture, size: 16),
              ),
              SegmentItem(
                value: AttendanceCalculationMethod.componentAverage,
                label: AttendanceCalculationMethod.componentAverage.displayName,
                icon: const AppIcon(AppIcons.lab, size: 16),
              ),
            ],
            onChanged: (newMethod) async {
              AppHaptics.selectionClick(ref);
              if (newMethod != semester.calculationMethod) {
                final updated = semester.copyWith(calculationMethod: newMethod);
                await ref
                    .read(semesterControllerProvider.notifier)
                    .updateSemester(updated);
              }
            },
          ),
          const SizedBox(height: 8),

          // Method explanation note
          Text(
            semester.calculationMethod ==
                    AttendanceCalculationMethod.rawCombined
                ? 'Every conducted class hour carries equal weight (1 session = 1 class).'
                : 'Theory Lecture and Practical Lab are averaged separately (50/50).',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.mutedInk,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Edit Semester full details link
          Center(
            child: AppButton(
              label: 'Edit Semester Name & Dates',
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              icon: AppIcon(
                AppIcons.edit,
                size: 14,
                color: AppColors.inkViolet,
              ),
              onPressed: () {
                AppHaptics.selectionClick(ref);
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

class _ThresholdPresetChip extends StatelessWidget {
  const _ThresholdPresetChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final double value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softLavender : AppColors.warmWhite,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: isSelected ? AppColors.inkViolet : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.inkViolet : AppColors.mutedInk,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
