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
import 'share_semester_qr_sheet.dart';
import '../screens/scan_semester_qr_screen.dart';

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
    final colors = context.colors;
    final willArchive = !semester.isArchived;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          willArchive ? 'Archive ${semester.name}?' : 'Unarchive ${semester.name}?',
          style: AppTypography.headline.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          willArchive
              ? 'Archiving "${semester.name}" preserves all its subjects and records, but hides it from daily logging.'
              : 'Restore "${semester.name}" back to your active semesters list?',
          style: AppTypography.subhead.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          'Delete ${semester.name}?',
          style: AppTypography.headline.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently remove all subjects and attendance logs for this semester.',
          style: AppTypography.subhead.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    final colors = context.colors;
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
                style: AppTypography.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _showArchived = !_showArchived);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    _showArchived ? 'Show Active Only' : 'Show Archived',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.brandPrimary,
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
                      style: AppTypography.bodyMuted.copyWith(
                        color: colors.textSecondary,
                      ),
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

                  final cardBg = isSelected
                      ? (colors.isDark ? colors.surfaceElevated : colors.surface)
                      : (colors.isDark
                          ? colors.surface
                          : colors.surfaceSubtle.withValues(alpha: 0.5));
                  final borderColor = colors.border.withValues(
                    alpha: colors.isDark
                        ? (isSelected ? 0.6 : 0.4)
                        : (isSelected ? 0.8 : 0.5),
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: AppRadius.lgBorder,
                      border: Border.all(
                        color: borderColor,
                        width: 0.5,
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
                                          color: colors.textPrimary,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      AppIcon(
                                        AppIcons.check,
                                        size: 16,
                                        color: colors.brandPrimary,
                                      ),
                                    ],
                                    if (semester.isArchived) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.track,
                                          borderRadius: AppRadius.smBorder,
                                        ),
                                        child: Text(
                                          'Archived',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: colors.textSecondary,
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
                                  style: AppTypography.labelSmall.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Actions: Quick Share QR + Overflow PopupMenuButton
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: AppIcon(
                                AppIcons.qrCode,
                                size: 20,
                                color: colors.brandPrimary,
                              ),
                              tooltip: 'Share QR',
                              onPressed: () {
                                showShareSemesterQrSheet(
                                  context: context,
                                  semester: semester,
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: AppIcon(
                                AppIcons.moreVert,
                                size: 20,
                                color: colors.textSecondary,
                              ),
                              tooltip: 'More options',
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.mdBorder,
                              ),
                              color: colors.surfaceElevated,
                              elevation: 6,
                              onSelected: (action) {
                                switch (action) {
                                  case 'edit':
                                    _openEditSemester(semester);
                                    break;
                                  case 'archive':
                                    _confirmArchive(semester);
                                    break;
                                  case 'delete':
                                    _confirmDelete(semester);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      AppIcon(
                                        AppIcons.edit,
                                        size: 18,
                                        color: colors.textPrimary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Edit',
                                        style: AppTypography.body.copyWith(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'archive',
                                  child: Row(
                                    children: [
                                      AppIcon(
                                        AppIcons.archive,
                                        size: 18,
                                        color: colors.textPrimary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        semester.isArchived
                                            ? 'Unarchive'
                                            : 'Archive',
                                        style: AppTypography.body.copyWith(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      AppIcon(
                                        AppIcons.delete,
                                        size: 18,
                                        color: colors.accentRed,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Delete',
                                        style: AppTypography.body.copyWith(
                                          color: colors.accentRed,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
            icon: const AppIcon(AppIcons.add, size: 18),
            onPressed: _openCreateSemester,
            isFullWidth: true,
            size: AppButtonSize.medium,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Scan QR to Import',
            icon: AppIcon(
              AppIcons.scan,
              size: 18,
              color: colors.brandPrimary,
            ),
            variant: AppButtonVariant.outline,
            onPressed: () async {
              Navigator.of(context).pop();
              await openScanSemesterQrScreen(context);
            },
            isFullWidth: true,
            size: AppButtonSize.medium,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
