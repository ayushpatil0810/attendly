import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_segmented_control.dart';
import 'package:attendly/core/shared/widgets/app_text_field.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

import 'delete_session_dialog.dart';
import 'quick_log_sheet.dart';

class SessionFormSheet extends ConsumerStatefulWidget {
  const SessionFormSheet({super.key, this.sessionToEdit, this.prefilledDate});

  final AttendanceSession? sessionToEdit;
  final DateTime? prefilledDate;

  @override
  ConsumerState<SessionFormSheet> createState() => _SessionFormSheetState();
}

class _SessionFormSheetState extends ConsumerState<SessionFormSheet> {
  late DateTime _sessionDate;
  int? _subjectId;
  late SessionComponent _component;
  late AttendanceStatus _status;
  late final TextEditingController _noteController;
  bool _isSubmitting = false;

  bool get _isEditing => widget.sessionToEdit != null;

  @override
  void initState() {
    super.initState();
    final toEdit = widget.sessionToEdit;
    if (toEdit != null) {
      _sessionDate = DateTime.parse(toEdit.sessionDate);
      _subjectId = toEdit.subjectId;
      _component = toEdit.component;
      _status = toEdit.status;
      _noteController = TextEditingController(text: toEdit.note ?? '');
    } else {
      final now = DateTime.now();
      _sessionDate =
          widget.prefilledDate ?? DateTime(now.year, now.month, now.day);
      _component = SessionComponent.lecture;
      _status = AttendanceStatus.present;
      _noteController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
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
        _sessionDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _save() async {
    if (_subjectId == null) {
      AppToast.showError(context, message: 'Please select a subject.');
      return;
    }

    setState(() => _isSubmitting = true);
    final dateStr = formatDateOnly(_sessionDate);

    try {
      if (_isEditing) {
        final updated = widget.sessionToEdit!.copyWith(
          subjectId: _subjectId!,
          sessionDate: dateStr,
          component: _component,
          status: _status,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

        await ref
            .read(attendanceControllerProvider.notifier)
            .updateSession(updated);

        AppHaptics.lightImpact(ref);

        if (!mounted) return;
        Navigator.of(context).pop();

        AppToast.showSuccess(
          context,
          message: 'Attendance record updated',
          actionLabel: 'Undo',
          onAction: () async {
            await ref.read(attendanceControllerProvider.notifier).undo();
            if (mounted) {
              AppToast.showInfo(context, message: 'Update reverted');
            }
          },
        );
      } else {
        await ref
            .read(attendanceControllerProvider.notifier)
            .recordSession(
              subjectId: _subjectId!,
              sessionDate: dateStr,
              component: _component,
              status: _status,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            );

        AppHaptics.lightImpact(ref);

        if (!mounted) return;
        Navigator.of(context).pop();

        AppToast.showSuccess(
          context,
          message: 'Attendance session recorded',
          actionLabel: 'Undo',
          onAction: () async {
            await ref.read(attendanceControllerProvider.notifier).undo();
            if (mounted) {
              AppToast.showInfo(context, message: 'Attendance entry undone');
            }
          },
        );
      }
    } on DuplicateSessionFailure catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(
        context,
        message: e is AppFailure ? e.message : 'Could not save session.',
      );
    }
  }

  Future<void> _handleDelete(Subject? subject) async {
    final session = widget.sessionToEdit;
    if (session == null) return;

    final subjectName = subject?.name ?? 'Subject';
    final confirmed = await showDeleteSessionDialog(
      context: context,
      subjectName: subjectName,
      componentName: session.component.displayName,
      date: session.sessionDate,
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();

      try {
        await ref
            .read(attendanceControllerProvider.notifier)
            .deleteSession(session);

        if (mounted) {
          AppToast.showSuccess(
            context,
            message: 'Session deleted',
            actionLabel: 'Undo',
            onAction: () async {
              await ref.read(attendanceControllerProvider.notifier).undo();
              if (mounted) {
                AppToast.showInfo(context, message: 'Deleted session restored');
              }
            },
          );
        }
      } catch (e) {
        if (mounted) {
          AppToast.showError(
            context,
            message: e is AppFailure
                ? e.message
                : 'The session could not be deleted. Try again.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return QuickLogSheet(
        initialDate: widget.prefilledDate,
        title: 'Record Historical Session',
      );
    }

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
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No subjects found in this semester.'),
          );
        }

        final selectedSubject = subjects.firstWhere(
          (s) => s.id == _subjectId,
          orElse: () => subjects.first,
        );

        final dateDisplay = DateFormat('EEEE, d MMMM yyyy')
            .format(_sessionDate);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject display
              const Text('Subject', style: AppTypography.labelSmall),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softLavender.withValues(alpha: 0.5),
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(
                    color: AppColors.brandViolet.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const AppIcon(
                      AppIcons.subjects,
                      size: 18,
                      color: AppColors.inkViolet,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedSubject.name,
                        style: AppTypography.itemTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Date row
              const Text('Date', style: AppTypography.labelSmall),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: AppRadius.mdBorder,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: AppRadius.mdBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const AppIcon(
                        AppIcons.calendar,
                        size: 18,
                        color: AppColors.brandViolet,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dateDisplay,
                          style: AppTypography.itemTitle,
                        ),
                      ),
                      const AppIcon(
                        AppIcons.edit,
                        size: 16,
                        color: AppColors.mutedInk,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Component selection
              if (selectedSubject.hasBothComponents) ...[
                const Text('Component', style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                AppSegmentedControl<SessionComponent>(
                  items: const [
                    SegmentItem(
                      value: SessionComponent.lecture,
                      label: 'Lecture',
                      icon: AppIcon(AppIcons.lecture, size: 16),
                    ),
                    SegmentItem(
                      value: SessionComponent.lab,
                      label: 'Lab',
                      icon: AppIcon(AppIcons.lab, size: 16),
                    ),
                  ],
                  selectedValue: _component,
                  onChanged: (comp) {
                    AppHaptics.selectionClick(ref);
                    setState(() => _component = comp);
                  },
                ),
                const SizedBox(height: 16),
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
                        _component.displayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.inkViolet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Attendance Status
              const Text('Status', style: AppTypography.labelSmall),
              const SizedBox(height: 6),
              AppSegmentedControl<AttendanceStatus>(
                items: const [
                  SegmentItem(
                    value: AttendanceStatus.present,
                    label: 'Present',
                    icon: AppIcon(
                      AppIcons.check,
                      size: 16,
                      color: AppColors.inkMint,
                    ),
                  ),
                  SegmentItem(
                    value: AttendanceStatus.absent,
                    label: 'Absent',
                    icon: AppIcon(
                      AppIcons.close,
                      size: 16,
                      color: AppColors.inkCoral,
                    ),
                  ),
                ],
                selectedValue: _status,
                onChanged: (st) {
                  AppHaptics.selectionClick(ref);
                  setState(() => _status = st);
                },
              ),

              const SizedBox(height: 16),

              // Note (optional)
              AppTextField(
                controller: _noteController,
                label: 'Note (Optional)',
                hint: 'e.g. Guest lecture, Unit test, Lab viva',
                textCapitalization: TextCapitalization.sentences,
                maxLength: 150,
              ),

              const SizedBox(height: 24),

              // Action buttons: Delete and Save Changes
              Row(
                children: [
                  AppButton(
                    label: 'Delete',
                    icon: const AppIcon(
                      AppIcons.delete,
                      size: 16,
                      color: AppColors.pureWhite,
                    ),
                    variant: AppButtonVariant.destructive,
                    onPressed: () => _handleDelete(selectedSubject),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Save Changes',
                      icon: const AppIcon(
                        AppIcons.check,
                        size: 16,
                        color: AppColors.pureWhite,
                      ),
                      isLoading: _isSubmitting,
                      onPressed: _save,
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

void showSessionFormSheet({
  required BuildContext context,
  AttendanceSession? sessionToEdit,
  DateTime? prefilledDate,
}) {
  if (sessionToEdit == null) {
    showQuickLogSheet(
      context: context,
      initialDate: prefilledDate,
      title: 'Record Historical Session',
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.pureWhite,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.88,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: mediaQuery.viewInsets.bottom,
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
                          'Edit Session',
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
                Expanded(
                  child: SessionFormSheet(
                    sessionToEdit: sessionToEdit,
                    prefilledDate: prefilledDate,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
