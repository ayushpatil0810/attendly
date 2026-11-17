import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_switch.dart';
import 'package:attendly/core/shared/widgets/app_text_field.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

class SubjectFormSheet extends ConsumerStatefulWidget {
  const SubjectFormSheet({
    super.key,
    required this.semesterId,
    this.initialSubject,
    this.onSaved,
  });

  final int semesterId;
  final Subject? initialSubject;
  final ValueChanged<int>? onSaved;

  @override
  ConsumerState<SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends ConsumerState<SubjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late bool _lectureEnabled;
  late bool _labEnabled;
  bool _isLoading = false;

  bool get _isEditing => widget.initialSubject != null;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSubject;
    _nameController = TextEditingController(text: s?.name ?? '');
    _lectureEnabled = s?.lectureEnabled ?? true;
    _labEnabled = s?.labEnabled ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_lectureEnabled && !_labEnabled) {
      AppToast.showError(
        context,
        message: 'A subject must have at least Lecture or Lab enabled.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final updated = widget.initialSubject!.copyWith(
          name: _nameController.text.trim(),
          lectureEnabled: _lectureEnabled,
          labEnabled: _labEnabled,
        );
        await ref
            .read(subjectControllerProvider.notifier)
            .updateSubject(updated);

        if (mounted) {
          AppToast.showSuccess(context, message: 'Subject updated.');
          Navigator.of(context).pop();
        }
      } else {
        final id = await ref
            .read(subjectControllerProvider.notifier)
            .createSubject(
              semesterId: widget.semesterId,
              name: _nameController.text.trim(),
              lectureEnabled: _lectureEnabled,
              labEnabled: _labEnabled,
            );

        if (mounted) {
          AppToast.showSuccess(context, message: 'Subject added.');
          widget.onSaved?.call(id);
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.showError(
          context,
          message: 'The subject could not be saved. Try again.',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Subject Name',
              hint: 'e.g. Computer Networks, Microprocessors',
              autofocus: !_isEditing,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a subject name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Attendance Components',
              style: AppTypography.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Select which class types this subject conducts.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mutedInk,
              ),
            ),
            const SizedBox(height: 12),

            // Lecture Toggle
            AppSwitchTile(
              title: 'Theory Lecture',
              subtitle: 'Track lecture classroom sessions',
              icon: AppIcon(AppIcons.lecture, color: AppColors.brandViolet),
              value: _lectureEnabled,
              onChanged: (val) {
                if (!val && !_labEnabled) {
                  AppToast.showError(
                    context,
                    message: 'At least one component must remain enabled.',
                  );
                  return;
                }
                setState(() => _lectureEnabled = val);
              },
            ),
            const SizedBox(height: 10),

            // Lab Toggle
            AppSwitchTile(
              title: 'Practical Lab',
              subtitle: 'Track laboratory or workshop sessions',
              icon: AppIcon(AppIcons.lab, color: AppColors.inkMint),
              value: _labEnabled,
              onChanged: (val) {
                if (!val && !_lectureEnabled) {
                  AppToast.showError(
                    context,
                    message: 'At least one component must remain enabled.',
                  );
                  return;
                }
                setState(() => _labEnabled = val);
              },
            ),
            const SizedBox(height: 28),

            // Submit Button
            AppButton(
              label: _isEditing ? 'Save Changes' : 'Add Subject',
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
