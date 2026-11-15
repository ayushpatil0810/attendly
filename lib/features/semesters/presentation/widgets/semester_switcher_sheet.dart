import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

import 'semester_form_sheet.dart';

class SemesterSwitcherSheet extends ConsumerStatefulWidget {
  const SemesterSwitcherSheet({super.key});

  @override
  ConsumerState<SemesterSwitcherSheet> createState() =>
      _SemesterSwitcherSheetState();
}

class _SemesterSwitcherSheetState extends ConsumerState<SemesterSwitcherSheet> {
  bool _showArchived = false;

  void _openCreateSemester() {
    Navigator.of(context).pop();
    showAppBottomSheet(
      context: context,
      title: 'New Semester',
      child: const SemesterFormSheet(),
    );
  }

  void _openEditSemester(Semester semester) {
    Navigator.of(context).pop();
    showAppBottomSheet(
      context: context,
      title: 'Edit Semester',
      child: SemesterFormSheet(initialSemester: semester),
    );
  }

  Future<void> _confirmArchive(Semester semester) async {
    final willArchive = !semester.isArchived;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(willArchive ? 'Archive Semester?' : 'Unarchive Semester?'),
        content: Text(
          willArchive
              ? 'Archiving "${semester.name}" preserves all its subjects and records, but hides it from daily logging.'
              : 'Restore "${semester.name}" back to your active semesters list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: willArchive ? 'Archive' : 'Restore',
            variant: willArchive
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
            size: AppButtonSize.small,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(semesterControllerProvider.notifier)
            .archiveSemester(semester.id, isArchived: willArchive);
        if (mounted) {
          AppToast.showSuccess(
            context,
            message: willArchive ? 'Semester archived.' : 'Semester restored.',
          );
        }
      } catch (_) {
        if (mounted) {
          AppToast.showError(
            context,
            message: 'The semester could not be updated. Try again.',
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(Semester semester) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Semester?'),
        content: Text(
          'Are you sure you want to permanently delete "${semester.name}"? All subjects and attendance records inside this semester will be removed.',
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

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(semesterControllerProvider.notifier)
            .deleteSemester(semester.id);
        if (mounted) {
          AppToast.showSuccess(context, message: 'Semester deleted.');
        }
      } catch (_) {
        if (mounted) {
          AppToast.showError(
            context,
            message: 'The semester could not be deleted. Try again.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSemester = ref.watch(activeSemesterProvider);
    final semestersStream = _showArchived
        ? ref.watch(allSemestersStreamProvider)
        : ref.watch(activeSemestersStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showArchived ? 'All Semesters' : 'Active Semesters',
                style: AppTypography.labelMedium,
              ),
              GestureDetector(
                onTap: () => setState(() => _showArchived = !_showArchived),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _showArchived ? 'Show Active Only' : 'Show Archived',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.inkViolet,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          semestersStream.when(
            data: (semesters) {
              if (semesters.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      _showArchived
                          ? 'No semesters found.'
                          : 'No active semesters.',
                      style: AppTypography.bodyMuted,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: semesters.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final semester = semesters[index];
                  final isSelected = activeSemester?.id == semester.id;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.softLavender
                          : AppColors.pureWhite,
                      borderRadius: AppRadius.lgBorder,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandViolet
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(selectedSemesterIdProvider.notifier)
                                  .selectSemester(semester.id);
                              Navigator.of(context).pop();
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        semester.name,
                                        style: AppTypography.itemTitle.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (semester.isArchived) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.track,
                                          borderRadius: AppRadius.smBorder,
                                        ),
                                        child: Text(
                                          'Archived',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: AppColors.mutedInk,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Threshold: ${semester.thresholdPercent}% • ${semester.calculationMethod.displayName}',
                                  style: AppTypography.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Actions: Edit, Archive, Delete
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const AppIcon(AppIcons.edit, size: 18),
                              color: AppColors.mutedInk,
                              onPressed: () => _openEditSemester(semester),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const AppIcon(AppIcons.archive, size: 18),
                              color: semester.isArchived
                                  ? AppColors.brandViolet
                                  : AppColors.mutedInk,
                              onPressed: () => _confirmArchive(semester),
                              tooltip: semester.isArchived
                                  ? 'Unarchive'
                                  : 'Archive',
                            ),
                            IconButton(
                              icon: const AppIcon(
                                AppIcons.delete,
                                size: 18,
                                color: AppColors.inkCoral,
                              ),
                              onPressed: () => _confirmDelete(semester),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => AppErrorState(
              message: 'Semesters could not load.',
              onRetry: () {
                ref.invalidate(allSemestersStreamProvider);
                ref.invalidate(activeSemestersStreamProvider);
              },
            ),
          ),

          const SizedBox(height: 24),
          AppButton(
            label: 'Add New Semester',
            icon: const AppIcon(
              AppIcons.add,
              size: 18,
              color: AppColors.pureWhite,
            ),
            onPressed: _openCreateSemester,
            isFullWidth: true,
            size: AppButtonSize.medium,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
