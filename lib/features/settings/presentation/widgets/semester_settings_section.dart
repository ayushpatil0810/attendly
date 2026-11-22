import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            backgroundColor: colors.brandPrimary,
          ),
          title: semester.name,
          showDisclosure: true,
          onTap: () {
            showAppBottomSheet(
              context: context,
              title: 'Semesters',
              child: const SemesterSwitcherSheet(),
            );
          },
        ),

        // 2. Attendance Target & Slider Control with precision steppers
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppleIconTile(
                    icon: AppIcons.target,
                    backgroundColor: colors.accentGreen,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus stepper
                      _ThresholdStepperButton(
                        key: const Key('threshold_stepper_decrement'),
                        icon: AppIcons.minus,
                        tooltip: 'Decrease threshold by 1%',
                        enabled: thresholdPercent > 50,
                        onTap: () async {
                          final updatedVal = (thresholdPercent - 1) / 100.0;
                          await ref
                              .read(semesterControllerProvider.notifier)
                              .updateSemester(
                                semester.copyWith(
                                  attendanceThreshold: updatedVal,
                                ),
                              );
                        },
                      ),
                      const SizedBox(width: 2),
                      // Tappable percentage pill with tabular figures
                      Tooltip(
                        message: 'Tap to enter exact target',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: AppRadius.pillBorder,
                            onTap: () {
                              _showThresholdInputDialog(
                                context,
                                ref,
                                semester,
                                thresholdPercent,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.isDark
                                    ? colors.brandPrimary.withValues(
                                        alpha: 0.16,
                                      )
                                    : colors.brandPrimarySoft,
                                borderRadius: AppRadius.pillBorder,
                                border: Border.all(
                                  color: colors.brandPrimary.withValues(
                                    alpha: colors.isDark ? 0.35 : 0.25,
                                  ),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '$thresholdPercent%',
                                style: AppTypography.withTabularFigures(
                                  AppTypography.labelLarge.copyWith(
                                    color: colors.brandPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Plus stepper
                      _ThresholdStepperButton(
                        key: const Key('threshold_stepper_increment'),
                        icon: AppIcons.add,
                        tooltip: 'Increase threshold by 1%',
                        enabled: thresholdPercent < 95,
                        onTap: () async {
                          final updatedVal = (thresholdPercent + 1) / 100.0;
                          await ref
                              .read(semesterControllerProvider.notifier)
                              .updateSemester(
                                semester.copyWith(
                                  attendanceThreshold: updatedVal,
                                ),
                              );
                        },
                      ),
                    ],
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
              backgroundColor: colors.accentOrange,
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

  void _showThresholdInputDialog(
    BuildContext context,
    WidgetRef ref,
    Semester semester,
    int currentPercent,
  ) {
    final controller = TextEditingController(text: '$currentPercent');
    final colors = context.colors;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          'Set Attendance Threshold',
          style: AppTypography.headline.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter target attendance percentage (50% – 95%):',
              style: AppTypography.footnote.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: AppTypography.withTabularFigures(
                AppTypography.headline.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              decoration: InputDecoration(
                suffixText: '%',
                suffixStyle: AppTypography.headline.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: colors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdBorder,
                  borderSide: BorderSide(
                    color: colors.border.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdBorder,
                  borderSide: BorderSide(color: colors.brandPrimary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 50 && parsed <= 95) {
                Navigator.of(dialogCtx).pop();
                await ref
                    .read(semesterControllerProvider.notifier)
                    .updateSemester(
                      semester.copyWith(attendanceThreshold: parsed / 100.0),
                    );
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: colors.brandPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdStepperButton extends StatelessWidget {
  const _ThresholdStepperButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: enabled
                      ? colors.surfaceSubtle.withValues(
                          alpha: colors.isDark ? 0.6 : 0.8,
                        )
                      : colors.surfaceSubtle.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.border.withValues(
                      alpha: enabled ? (colors.isDark ? 0.4 : 0.6) : 0.2,
                    ),
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  icon,
                  size: 15,
                  color: enabled
                      ? colors.brandPrimary
                      : colors.textTertiary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
