import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_empty_state.dart';
import 'package:attendly/core/shared/widgets/app_loading_state.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_switcher_sheet.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';
import 'package:attendly/features/subjects/presentation/widgets/subject_form_sheet.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  void _openAddSubject(BuildContext context, int semesterId) {
    showAppBottomSheet(
      context: context,
      title: 'Add Subject',
      child: SubjectFormSheet(semesterId: semesterId),
    );
  }

  void _openEditSubject(BuildContext context, int semesterId, Subject subject) {
    showAppBottomSheet(
      context: context,
      title: 'Edit Subject',
      child: SubjectFormSheet(semesterId: semesterId, initialSubject: subject),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text(
          'Are you sure you want to delete "${subject.name}"? All its attendance records will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Delete',
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.small,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(subjectControllerProvider.notifier)
            .deleteSubject(subject.id);
        if (context.mounted) {
          AppToast.showSuccess(context, message: 'Subject deleted.');
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.showError(context, message: 'Failed to delete: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSemester = ref.watch(activeSemesterProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);

    if (activeSemester == null) {
      return Scaffold(
        backgroundColor: AppColors.warmWhite,
        body: SafeArea(
          child: AppEmptyState(
            title: 'No Active Semester',
            description: 'Please select or create a semester first.',
            icon: const AppIcon(AppIcons.home, size: 28),
            actionLabel: 'Select Semester',
            onAction: () {
              showAppBottomSheet(
                context: context,
                title: 'Semesters',
                child: const SemesterSwitcherSheet(),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar with Semester context and Add button
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenHorizontal,
                right: AppSpacing.screenHorizontal,
                top: AppSpacing.screenTop,
                bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subjects', style: AppTypography.screenTitle),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            showAppBottomSheet(
                              context: context,
                              title: 'Switch Semester',
                              child: const SemesterSwitcherSheet(),
                            );
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                activeSemester.name,
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.brandViolet,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: AppColors.brandViolet,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    label: 'Add Subject',
                    icon: const AppIcon(
                      AppIcons.add,
                      size: 16,
                      color: AppColors.pureWhite,
                    ),
                    size: AppButtonSize.small,
                    onPressed: () =>
                        _openAddSubject(context, activeSemester.id),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider),

            // Content
            Expanded(
              child: subjectsAsync.when(
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return AppEmptyState(
                      title: 'No Subjects Added',
                      description: 'Add your enrolled courses to begin tracking lectures and labs.',
                      icon: const AppIcon(
                        AppIcons.subjects,
                        size: 32,
                        color: AppColors.brandViolet,
                      ),
                      actionLabel: 'Add First Subject',
                      onAction: () =>
                          _openAddSubject(context, activeSemester.id),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.screenHorizontal,
                      right: AppSpacing.screenHorizontal,
                      top: 16,
                      bottom: AppSpacing.dockClearance,
                    ),
                    itemCount: subjects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return _SubjectCard(
                        subject: subject,
                        onEdit: () => _openEditSubject(
                          context,
                          activeSemester.id,
                          subject,
                        ),
                        onDelete: () => _confirmDelete(context, ref, subject),
                      );
                    },
                  );
                },
                loading: () =>
                    const AppLoadingState(message: 'Loading subjects...'),
                error: (e, _) =>
                    Center(child: Text('Error loading subjects: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  final Subject subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  subject.name,
                  style: AppTypography.itemTitle.copyWith(fontSize: 16),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppColors.mutedInk),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        AppIcon(AppIcons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Subject'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        AppIcon(
                          AppIcons.delete,
                          size: 16,
                          color: AppColors.brandCoral,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete Subject',
                          style: TextStyle(color: AppColors.brandCoral),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Component badges
          Row(
            children: [
              if (subject.lectureEnabled) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softLavender,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        AppIcons.lecture,
                        size: 14,
                        color: AppColors.brandViolet,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lecture',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandViolet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (subject.labEnabled) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softMint,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        AppIcons.lab,
                        size: 14,
                        color: AppColors.brandMint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lab',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Phase 1 Honest Attendance Status: No fake numbers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.track,
              borderRadius: AppRadius.smBorder,
            ),
            child: Row(
              children: [
                const AppIcon(
                  AppIcons.info,
                  size: 14,
                  color: AppColors.mutedInk,
                ),
                const SizedBox(width: 6),
                Text(
                  'No sessions recorded yet (Phase 2)',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mutedInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
