import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/theme/app_motion.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_segmented_control.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';
import 'package:intl/intl.dart';

class QuickLogSheet extends ConsumerStatefulWidget {
  const QuickLogSheet({super.key, this.initialDate, this.initialSubjectId});

  final DateTime? initialDate;
  final int? initialSubjectId;

  @override
  ConsumerState<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<QuickLogSheet> {
  int? _selectedSubjectId;
  SessionComponent _selectedComponent = SessionComponent.lecture;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate =
        widget.initialDate ?? DateTime(now.year, now.month, now.day);
    if (widget.initialSubjectId != null) {
      _selectedSubjectId = widget.initialSubjectId;
    }
  }

  void _syncComponentForSubject(Subject subject) {
    if (subject.hasBothComponents) {
      if (_selectedComponent != SessionComponent.lecture &&
          _selectedComponent != SessionComponent.lab) {
        _selectedComponent = SessionComponent.lecture;
      }
    } else if (subject.lectureEnabled) {
      _selectedComponent = SessionComponent.lecture;
    } else if (subject.labEnabled) {
      _selectedComponent = SessionComponent.lab;
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day), // No future dates
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

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _recordAttendance(
    Subject subject,
    AttendanceStatus status,
  ) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final dateStr = formatDateOnly(_selectedDate);

    try {
      await ref
          .read(attendanceControllerProvider.notifier)
          .recordSession(
            subjectId: subject.id,
            sessionDate: dateStr,
            component: _selectedComponent,
            status: status,
          );

      AppHaptics.lightImpact(ref);

      if (!mounted) return;
      Navigator.of(context).pop();

      final statusLabel = status == AttendanceStatus.present
          ? 'Present'
          : 'Absent';
      final componentLabel = _selectedComponent.displayName;

      AppToast.showSuccess(
        context,
        message: 'Marked $statusLabel for ${subject.name} ($componentLabel)',
        actionLabel: 'Undo',
        onAction: () async {
          await ref.read(attendanceControllerProvider.notifier).undo();
          if (mounted) {
            AppToast.showInfo(context, message: 'Attendance entry undone.');
          }
        },
      );
    } on DuplicateSessionFailure catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(
        context,
        message: e is AppFailure ? e.message : 'Could not save attendance.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);

    return subjectsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.brandViolet),
        ),
      ),
      error: (err, _) => AppErrorState(
        message: 'Subjects could not load.',
        onRetry: () => ref.invalidate(activeSemesterSubjectsProvider),
      ),
      data: (subjects) {
        if (subjects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.softPeach,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const AppIcon(
                    AppIcons.subjects,
                    size: 28,
                    color: AppColors.inkPeach,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No subjects found',
                  style: AppTypography.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please add subjects to your semester before logging attendance.',
                  style: AppTypography.bodyMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Close',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }

        // Auto-select first subject if none selected or if selected is missing
        final selectedSubject = subjects.firstWhere(
          (s) => s.id == _selectedSubjectId,
          orElse: () => subjects.first,
        );

        if (_selectedSubjectId != selectedSubject.id) {
          _selectedSubjectId = selectedSubject.id;
          _syncComponentForSubject(selectedSubject);
        }

        final dateStr = formatDateOnly(_selectedDate);
        final isToday = dateStr == formatDateOnly(DateTime.now());

        // Check if an existing session exists for this subject, component, and date
        final sessionsForDateAsync = ref.watch(
          sessionsForDateFamilyProvider(dateStr),
        );
        var loggedCount = 0;

        sessionsForDateAsync.whenData((sessions) {
          for (final s in sessions) {
            if (s.subjectId == selectedSubject.id &&
                s.component == _selectedComponent &&
                s.sessionDate == dateStr) {
              loggedCount++;
            }
          }
        });

        final formattedDate = DateFormat('EEE, d MMM').format(_selectedDate);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selector row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Date', style: AppTypography.labelSmall),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: AppRadius.smBorder,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIcon(
                            AppIcons.calendar,
                            size: 14,
                            color: AppColors.brandViolet,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isToday ? 'Today ($formattedDate)' : formattedDate,
                            style: AppTypography.itemTitle.copyWith(
                              color: AppColors.inkViolet,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const AppIcon(
                            AppIcons.edit,
                            size: 12,
                            color: AppColors.brandViolet,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subject selection chips
              const Text('Select Subject', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: subjects.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final isSelected = subject.id == _selectedSubjectId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSubjectId = subject.id;
                          _syncComponentForSubject(subject);
                        });
                      },
                      child: AnimatedContainer(
                        duration: AppMotion.duration(
                          context,
                          const Duration(milliseconds: 180),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.softLavender
                              : AppColors.pureWhite,
                          borderRadius: AppRadius.pillBorder,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brandViolet
                                : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          subject.name,
                          style: AppTypography.itemTitle.copyWith(
                            color: isSelected
                                ? AppColors.inkViolet
                                : AppColors.ink,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Component selection
              if (selectedSubject.hasBothComponents) ...[
                const Text('Component', style: AppTypography.labelSmall),
                const SizedBox(height: 8),
                AppSegmentedControl<SessionComponent>(
                  items: const [
                    SegmentItem(
                      value: SessionComponent.lecture,
                      label: 'Lecture',
                    ),
                    SegmentItem(value: SessionComponent.lab, label: 'Lab'),
                  ],
                  selectedValue: _selectedComponent,
                  onChanged: (comp) {
                    setState(() => _selectedComponent = comp);
                  },
                ),
                const SizedBox(height: 20),
              ] else ...[
                Row(
                  children: [
                    const Text('Component: ', style: AppTypography.labelSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.softLavender,
                        borderRadius: AppRadius.smBorder,
                      ),
                      child: Text(
                        _selectedComponent.displayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.inkViolet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              if (loggedCount > 0) ...[
                Text(
                  loggedCount == 1
                      ? '1 ${_selectedComponent.displayName} is already logged for this day. This save adds another.'
                      : '$loggedCount ${_selectedComponent.displayName}s are already logged for this day. This save adds another.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Mark Attendance (saves immediately)',
                style: AppTypography.labelSmall,
              ),
              const SizedBox(height: 10),
              Row(
                  children: [
                    // Present Button
                    Expanded(
                      child: _AttendanceActionButton(
                        label: 'Present',
                        icon: AppIcons.check,
                        backgroundColor: AppColors.brandMint,
                        textColor: AppColors.ink,
                        isLoading: _isSubmitting,
                        onTap: () => _recordAttendance(
                          selectedSubject,
                          AttendanceStatus.present,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Absent Button
                    Expanded(
                      child: _AttendanceActionButton(
                        label: 'Absent',
                        icon: AppIcons.close,
                        backgroundColor: AppColors.brandCoral,
                        textColor: AppColors.ink,
                        isLoading: _isSubmitting,
                        onTap: () => _recordAttendance(
                          selectedSubject,
                          AttendanceStatus.absent,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceActionButton extends StatelessWidget {
  const _AttendanceActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final dynamic icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: AppRadius.lgBorder,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: AppRadius.lgBorder,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgBorder,
            border: Border.all(
              color: backgroundColor == AppColors.brandCoral
                  ? AppColors.inkCoral
                  : AppColors.inkMint,
              width: 1.5,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: textColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(icon, size: 22, color: textColor),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: AppTypography.labelLarge.copyWith(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

void showQuickLogSheet({
  required BuildContext context,
  DateTime? initialDate,
  int? initialSubjectId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.pureWhite,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Quick Attendance Log',
                        style: AppTypography.sectionTitle,
                      ),
                    ),
                    AppCloseButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider, height: 20),
              QuickLogSheet(
                initialDate: initialDate,
                initialSubjectId: initialSubjectId,
              ),
            ],
          ),
        ),
      );
    },
  );
}
