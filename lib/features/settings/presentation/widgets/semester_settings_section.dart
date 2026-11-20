import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/shared/widgets/apple/apple_list_tile.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
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
    final colors = context.colors;

    if (activeSemester == null) {
      return AppleInsetGroup(
        header: 'Semester Settings',
        margin: EdgeInsets.zero,
        children: [
          AppleListTile(
            leading: AppleIconTile(
              icon: AppIcons.subjects,
              backgroundColor: colors.brandPrimary,
            ),
            title: 'No Active Semester',
            subtitle: 'Tap to select or create an academic semester',
            showDisclosure: true,
            onTap: () {
              AppHaptics.selectionClick(ref);
              showAppBottomSheet(
                context: context,
                title: 'Semesters',
                child: const SemesterSwitcherSheet(),
              );
            },
          ),
        ],
      );
    }

    final semester = activeSemester!;
    final thresholdPercent = (semester.attendanceThreshold * 100).round();

    return AppleInsetGroup(
      header: 'Semester Settings',
      margin: EdgeInsets.zero,
      children: [
        // 1. Active Semester Name & Switcher Tile
        AppleListTile(
          leading: AppleIconTile(
            icon: AppIcons.subjects,
            backgroundColor: colors.isDark
                ? const Color(0xFF4A6BF7)
                : const Color(0xFF3F5BF6),
          ),
          title: semester.name,
          showDisclosure: true,
          onTap: () {
            AppHaptics.selectionClick(ref);
            showAppBottomSheet(
              context: context,
              title: 'Semesters',
              child: const SemesterSwitcherSheet(),
            );
          },
        ),

        // 2. Attendance Target & Slider Control (no verbose subtitle)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppleIconTile(
                    icon: AppIcons.target,
                    backgroundColor: colors.accentMint,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Attendance Threshold',
                      style: AppTypography.headline.copyWith(
                        fontSize: 16,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.isDark
                          ? colors.brandPrimary.withValues(alpha: 0.16)
                          : colors.brandPrimarySoft,
                      borderRadius: AppRadius.pillBorder,
                    ),
                    child: Text(
                      '$thresholdPercent%',
                      style: AppTypography.labelLarge.copyWith(
                        color: colors.isDark
                            ? colors.brandPrimary
                            : colors.brandPrimaryInk,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: colors.brandPrimary,
                  inactiveTrackColor: colors.track,
                  thumbColor: colors.brandPrimary,
                  overlayColor: colors.brandPrimary.withValues(alpha: 0.12),
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
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
            ],
          ),
        ),

        // 3. Calculation Method Selection Menu Tile (replaces segmented tabs)
        PopupMenuButton<AttendanceCalculationMethod>(
          initialValue: semester.calculationMethod,
          tooltip: 'Select Calculation Method',
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.mdBorder,
          ),
          color: colors.surface,
          elevation: 6,
          onSelected: (newMethod) async {
            AppHaptics.selectionClick(ref);
            if (newMethod != semester.calculationMethod) {
              final updated =
                  semester.copyWith(calculationMethod: newMethod);
              await ref
                  .read(semesterControllerProvider.notifier)
                  .updateSemester(updated);
            }
          },
          itemBuilder: (context) => [
            for (final method in AttendanceCalculationMethod.values)
              PopupMenuItem(
                value: method,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            method.displayName,
                            style: AppTypography.subhead.copyWith(
                              color: colors.textPrimary,
                              fontWeight: method == semester.calculationMethod
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            method.description,
                            style: AppTypography.caption2.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (method == semester.calculationMethod) ...[
                      const SizedBox(width: 8),
                      AppIcon(
                        Icons.check,
                        size: 16,
                        color: colors.brandPrimary,
                      ),
                    ],
                  ],
                ),
              ),
          ],
          child: AppleListTile(
            leading: AppleIconTile(
              icon: AppIcons.insights,
              backgroundColor: colors.accentPeach,
            ),
            title: 'Calculation Method',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  semester.calculationMethod.displayName,
                  style: AppTypography.subhead.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                AppIcon(
                  AppIcons.arrowDown,
                  size: 16,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),

        // 4. Edit Details Link Tile
        AppleListTile(
          leading: AppleIconTile(
            icon: AppIcons.edit,
            backgroundColor: colors.brandPrimary,
          ),
          title: 'Edit Semester Details',
          showDisclosure: true,
          onTap: () {
            AppHaptics.selectionClick(ref);
            showAppBottomSheet(
              context: context,
              title: 'Edit Semester',
              child: SemesterFormSheet(initialSemester: semester),
            );
          },
        ),
      ],
    );
  }
}
