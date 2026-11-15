import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_segmented_control.dart';
import 'package:attendly/core/shared/widgets/app_text_field.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

class SemesterFormSheet extends ConsumerStatefulWidget {
  const SemesterFormSheet({super.key, this.initialSemester, this.onSaved});

  final Semester? initialSemester;
  final ValueChanged<int>? onSaved;

  @override
  ConsumerState<SemesterFormSheet> createState() => _SemesterFormSheetState();
}

class _SemesterFormSheetState extends ConsumerState<SemesterFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late double _thresholdPercent;
  late AttendanceCalculationMethod _calculationMethod;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  bool get _isEditing => widget.initialSemester != null;

  @override
  void initState() {
    super.initState();
    final sem = widget.initialSemester;
    _nameController = TextEditingController(text: sem?.name ?? '');
    _thresholdPercent = (sem?.attendanceThreshold ?? 0.75) * 100;
    _calculationMethod =
        sem?.calculationMethod ?? AttendanceCalculationMethod.rawCombined;
    _startDate = sem?.startDate;
    _endDate = sem?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.inkViolet,
              onPrimary: AppColors.pureWhite,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate != null &&
        _endDate != null &&
        _startDate!.isAfter(_endDate!)) {
      AppToast.showError(
        context,
        message: 'Start date cannot be after end date.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final threshold = _thresholdPercent / 100.0;
      if (_isEditing) {
        final updated = widget.initialSemester!.copyWith(
          name: _nameController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          attendanceThreshold: threshold,
          calculationMethod: _calculationMethod,
        );
        await ref
            .read(semesterControllerProvider.notifier)
            .updateSemester(updated);

        if (mounted) {
          AppToast.showSuccess(context, message: 'Semester updated.');
          Navigator.of(context).pop();
        }
      } else {
        final id = await ref
            .read(semesterControllerProvider.notifier)
            .createSemester(
              name: _nameController.text.trim(),
              startDate: _startDate,
              endDate: _endDate,
              attendanceThreshold: threshold,
              calculationMethod: _calculationMethod,
            );

        if (mounted) {
          AppToast.showSuccess(context, message: 'Semester created.');
          widget.onSaved?.call(id!);
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.showError(
          context,
          message: 'The semester could not be saved. Try again.',
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
    final dateFormat = DateFormat('MMM dd, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Semester Name
            AppTextField(
              controller: _nameController,
              label: 'Semester Name',
              hint: 'e.g. Semester 5, Fall 2026',
              autofocus: !_isEditing,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a semester name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Attendance Threshold Slider & Number
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
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.inkViolet,
                inactiveTrackColor: AppColors.track,
                thumbColor: AppColors.inkViolet,
                overlayColor: AppColors.inkViolet.withOpacity(0.12),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
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
            const SizedBox(height: 16),

            // Calculation Method
            const Text('Calculation Method', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            AppSegmentedControl<AttendanceCalculationMethod>(
              items: [
                SegmentItem(
                  value: AttendanceCalculationMethod.rawCombined,
                  label: AttendanceCalculationMethod.rawCombined.displayName,
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
            const SizedBox(height: 6),
            Text(
              _calculationMethod.description,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mutedInk,
              ),
            ),
            const SizedBox(height: 20),

            // Optional Dates
            const Text('Duration (Optional)', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(isStart: true),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const AppIcon(AppIcons.calendar, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _startDate != null
                                  ? dateFormat.format(_startDate!)
                                  : 'Start Date',
                              style: _startDate != null
                                  ? AppTypography.bodyMedium
                                  : AppTypography.bodySmall.copyWith(
                                      color: AppColors.subtleInk,
                                    ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_startDate != null)
                            Semantics(
                              button: true,
                              label: 'Clear start date',
                              child: GestureDetector(
                                onTap: () => setState(() => _startDate = null),
                                behavior: HitTestBehavior.opaque,
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Center(
                                    child: AppIcon(
                                      AppIcons.close,
                                      size: 18,
                                      color: AppColors.mutedInk,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(isStart: false),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const AppIcon(AppIcons.calendar, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _endDate != null
                                  ? dateFormat.format(_endDate!)
                                  : 'End Date',
                              style: _endDate != null
                                  ? AppTypography.bodyMedium
                                  : AppTypography.bodySmall.copyWith(
                                      color: AppColors.subtleInk,
                                    ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_endDate != null)
                            Semantics(
                              button: true,
                              label: 'Clear end date',
                              child: GestureDetector(
                                onTap: () => setState(() => _endDate = null),
                                behavior: HitTestBehavior.opaque,
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Center(
                                    child: AppIcon(
                                      AppIcons.close,
                                      size: 18,
                                      color: AppColors.mutedInk,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Submit Button
            AppButton(
              label: _isEditing ? 'Save Changes' : 'Create Semester',
              onPressed: _save,
              isLoading: _isLoading,
              isFullWidth: true,
              size: AppButtonSize.large,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
