import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/core/services/notification_preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_frame.dart';
import 'package:attendly/core/shared/widgets/app_segmented_control.dart';
import 'package:attendly/core/shared/widgets/app_text_field.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

import 'scan_semester_qr_screen.dart';

class SemesterSetupScreen extends ConsumerStatefulWidget {
  const SemesterSetupScreen({super.key});

  @override
  ConsumerState<SemesterSetupScreen> createState() =>
      _SemesterSetupScreenState();
}

class _SemesterSetupScreenState extends ConsumerState<SemesterSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  double _thresholdPercent = 75.0;
  AttendanceCalculationMethod _calculationMethod =
      AttendanceCalculationMethod.rawCombined;
  bool _dailyReminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final threshold = _thresholdPercent / 100.0;
      await ref
          .read(semesterControllerProvider.notifier)
          .createSemester(
            name: _nameController.text.trim(),
            attendanceThreshold: threshold,
            calculationMethod: _calculationMethod,
            targetGoal: threshold,
          );

      // Save daily reminder settings
      final notifNotifier = ref.read(notificationPreferencesProvider.notifier);
      if (_dailyReminderEnabled) {
        await notifNotifier.setReminderTime(_reminderTime);
        await notifNotifier.setDailyReminderEnabled(true);
      } else {
        await notifNotifier.setDailyReminderEnabled(false);
      }

      if (mounted) {
        AppToast.showSuccess(
          context,
          message: 'Semester created successfully!',
        );
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        AppToast.showError(
          context,
          message: 'The semester could not be created. Try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: AppFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Heading
                  Text(
                    'Set Up First Semester',
                    style: AppTypography.screenTitle.copyWith(
                      fontSize: 28,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your current academic semester details to start tracking classes.',
                    style: AppTypography.bodyMuted.copyWith(
                      fontSize: 15,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Input
                  AppTextField(
                    controller: _nameController,
                    label: 'Semester Name',
                    hint: 'e.g. Semester 5, Fall 2026',
                    autofocus: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a semester name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Attendance Threshold
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attendance Threshold',
                        style: AppTypography.labelMedium.copyWith(
                          color: colors.textPrimary,
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
                          '${_thresholdPercent.round()}%',
                          style: AppTypography.labelLarge.copyWith(
                            color: colors.isDark
                                ? colors.brandPrimary
                                : colors.brandPrimaryInk,
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
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: _thresholdPercent,
                      min: 50,
                      max: 100,
                      divisions: 50,
                      onChanged: (val) {
                        setState(() => _thresholdPercent = val);
                      },
                    ),
                  ),
                  Text(
                    'Default is 75% for most universities. You can adjust this anytime.',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Calculation Method
                  Text(
                    'Calculation Method',
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppSegmentedControl<AttendanceCalculationMethod>(
                    items: [
                      SegmentItem(
                        value: AttendanceCalculationMethod.rawCombined,
                        label:
                            AttendanceCalculationMethod.rawCombined.displayName,
                      ),
                      SegmentItem(
                        value: AttendanceCalculationMethod.componentAverage,
                        label: AttendanceCalculationMethod
                            .componentAverage
                            .displayName,
                      ),
                    ],
                    selectedValue: _calculationMethod,
                    onChanged: (val) {
                      setState(() => _calculationMethod = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _calculationMethod.description,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Daily Reminder Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: AppRadius.lgBorder,
                      border: Border.all(color: colors.border),
                      boxShadow: [
                        BoxShadow(
                          color: colors.isDark
                              ? Colors.transparent
                              : colors.textPrimary.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.isDark
                                    ? colors.brandPrimary.withValues(alpha: 0.16)
                                    : colors.brandPrimarySoft,
                                borderRadius: AppRadius.smBorder,
                              ),
                              alignment: Alignment.center,
                              child: AppIcon(
                                AppIcons.notification,
                                size: 18,
                                color: colors.isDark
                                    ? colors.brandPrimary
                                    : colors.brandPrimaryInk,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Reminder',
                                    style: AppTypography.itemTitle.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Get reminded to log your classes',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _dailyReminderEnabled,
                              activeColor: colors.isDark
                                  ? Colors.white
                                  : colors.brandPrimary,
                              onChanged: (val) {
                                setState(() => _dailyReminderEnabled = val);
                              },
                            ),
                          ],
                        ),
                        if (_dailyReminderEnabled) ...[
                          const SizedBox(height: 14),
                          Divider(height: 1, color: colors.divider),
                          const SizedBox(height: 14),
                          Text(
                            'Preferred Reminder Time',
                            style: AppTypography.labelSmall.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildTimePresetChip(
                                context: context,
                                label: '7:00 PM',
                                time: const TimeOfDay(hour: 19, minute: 0),
                              ),
                              _buildTimePresetChip(
                                context: context,
                                label: '8:00 PM',
                                time: const TimeOfDay(hour: 20, minute: 0),
                              ),
                              _buildTimePresetChip(
                                context: context,
                                label: '9:00 PM',
                                time: const TimeOfDay(hour: 21, minute: 0),
                              ),
                              _buildCustomTimeChip(context),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Continue Button
                  AppButton(
                    label: 'Save & Continue',
                    onPressed: _submit,
                    isLoading: _isLoading,
                    isFullWidth: true,
                    size: AppButtonSize.large,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: colors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: AppTypography.labelSmall.copyWith(
                            color: colors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colors.divider)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Scan QR to Import Semester',
                    icon: AppIcon(
                      AppIcons.scan,
                      size: 18,
                      color: colors.brandPrimary,
                    ),
                    variant: AppButtonVariant.outline,
                    onPressed: () async {
                      final success = await openScanSemesterQrScreen(context);
                      if (success == true && context.mounted) {
                        context.go('/home');
                      }
                    },
                    isFullWidth: true,
                    size: AppButtonSize.large,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePresetChip({
    required BuildContext context,
    required String label,
    required TimeOfDay time,
  }) {
    final colors = context.colors;
    final isSelected =
        _reminderTime.hour == time.hour && _reminderTime.minute == time.minute;
    return GestureDetector(
      onTap: () => setState(() => _reminderTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (colors.isDark
                  ? colors.brandPrimary.withValues(alpha: 0.16)
                  : colors.brandPrimarySoft)
              : colors.surface,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: isSelected ? colors.brandPrimary : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? (colors.isDark
                    ? colors.brandPrimary
                    : colors.brandPrimaryInk)
                : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTimeChip(BuildContext context) {
    final colors = context.colors;
    final isPreset =
        (_reminderTime.hour == 19 && _reminderTime.minute == 0) ||
        (_reminderTime.hour == 20 && _reminderTime.minute == 0) ||
        (_reminderTime.hour == 21 && _reminderTime.minute == 0);
    final isSelected = !isPreset;

    final hour12 = _reminderTime.hour % 12 == 0 ? 12 : _reminderTime.hour % 12;
    final minPadded = _reminderTime.minute.toString().padLeft(2, '0');
    final period = _reminderTime.hour >= 12 ? 'PM' : 'AM';
    final customLabel = isSelected ? '$hour12:$minPadded $period' : 'Custom';

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _reminderTime,
          builder: (ctx, child) {
            return Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: colors.isDark
                    ? ColorScheme.dark(
                        primary: colors.brandPrimary,
                        surface: colors.surface,
                        onSurface: colors.textPrimary,
                      )
                    : ColorScheme.light(
                        primary: colors.brandPrimary,
                        surface: colors.surface,
                        onSurface: colors.textPrimary,
                      ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _reminderTime = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (colors.isDark
                  ? colors.brandPrimary.withValues(alpha: 0.16)
                  : colors.brandPrimarySoft)
              : colors.surface,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: isSelected ? colors.brandPrimary : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              customLabel,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? (colors.isDark
                        ? colors.brandPrimary
                        : colors.brandPrimaryInk)
                    : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            AppIcon(
              AppIcons.arrowDown,
              size: 12,
              color: isSelected
                  ? (colors.isDark
                      ? colors.brandPrimary
                      : colors.brandPrimaryInk)
                  : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
