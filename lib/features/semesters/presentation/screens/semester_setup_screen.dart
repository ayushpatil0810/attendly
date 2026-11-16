import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          );

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
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
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
                  style: AppTypography.screenTitle.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your current academic semester details to start tracking classes.',
                  style: AppTypography.bodyMuted.copyWith(fontSize: 15),
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
                    const Text(
                      'Attendance Threshold',
                      style: AppTypography.labelMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softLavender,
                        borderRadius: AppRadius.pillBorder,
                      ),
                      child: Text(
                        '${_thresholdPercent.round()}%',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.inkViolet,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.inkViolet,
                    inactiveTrackColor: AppColors.track,
                    thumbColor: AppColors.inkViolet,
                    overlayColor: AppColors.inkViolet.withOpacity(0.12),
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
                    color: AppColors.mutedInk,
                  ),
                ),
                const SizedBox(height: 28),

                // Calculation Method
                const Text(
                  'Calculation Method',
                  style: AppTypography.labelMedium,
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
                    color: AppColors.mutedInk,
                  ),
                ),
                const SizedBox(height: 40),

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
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Scan QR to Import Semester',
                  icon: const AppIcon(
                    AppIcons.scan,
                    size: 18,
                    color: AppColors.inkViolet,
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
}
