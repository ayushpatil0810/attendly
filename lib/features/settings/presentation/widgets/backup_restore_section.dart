import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/settings/presentation/providers/settings_providers.dart';

import 'backup_summary_dialog.dart';

class BackupRestoreSection extends ConsumerWidget {
  const BackupRestoreSection({super.key});

  void _handleExport(BuildContext context, WidgetRef ref) async {
    AppHaptics.selectionClick(ref);
    final result = await ref
        .read(backupControllerProvider.notifier)
        .exportBackup();

    if (!context.mounted) return;

    if (result.isSuccess && !result.isCanceled) {
      AppHaptics.lightImpact(ref);
      AppToast.showSuccess(context, message: 'Backup exported successfully!');
    } else if (!result.isSuccess && result.errorMessage != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.pureWhite,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
          title: Text(
            'Export Failed',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
          ),
          content: Text(
            'Could not export backup: ${result.errorMessage}',
            style: AppTypography.bodySmall,
          ),
          actions: [
            AppButton(
              label: 'OK',
              size: AppButtonSize.small,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  void _handleRestore(BuildContext context, WidgetRef ref) async {
    AppHaptics.selectionClick(ref);
    final validationResult = await ref
        .read(backupControllerProvider.notifier)
        .pickAndValidateBackup();

    if (!context.mounted || validationResult == null) return;

    if (!validationResult.isValid) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.pureWhite,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
          title: Row(
            children: [
              const AppIcon(
                AppIcons.alert,
                color: AppColors.inkCoral,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Invalid Backup File',
                style: AppTypography.screenTitle.copyWith(fontSize: 18),
              ),
            ],
          ),
          content: Text(
            validationResult.error ?? 'The selected file could not be verified as a valid Attendly backup.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
          ),
          actions: [
            AppButton(
              label: 'OK',
              size: AppButtonSize.small,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return;
    }

    // Valid backup - display summary confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackupSummaryDialog(
        summary: validationResult.summary!,
        onConfirm: () async {
          final success = await ref
              .read(backupControllerProvider.notifier)
              .executeRestore(validationResult.data!);

          if (!context.mounted) return;

          if (success) {
            AppHaptics.lightImpact(ref);
            AppToast.showSuccess(
              context,
              message: 'Attendance data restored successfully!',
            );
          } else {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.pureWhite,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.lgBorder,
                ),
                title: Text(
                  'Restore Failed',
                  style: AppTypography.screenTitle.copyWith(fontSize: 18),
                ),
                content: const Text(
                  'An error occurred during restore. All changes were rolled back and existing data is safe.',
                  style: AppTypography.bodySmall,
                ),
                actions: [
                  AppButton(
                    label: 'OK',
                    size: AppButtonSize.small,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupControllerProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export Card Block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.softMint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const AppIcon(
                  AppIcons.exportFile,
                  color: AppColors.inkMint,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export Local Backup',
                      style: AppTypography.itemTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Save all semesters, subjects, and attendance history to a portable JSON backup file.',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.mutedInk,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Export Backup',
                      icon: const AppIcon(
                        AppIcons.exportFile,
                        size: 16,
                        color: AppColors.pureWhite,
                      ),
                      size: AppButtonSize.small,
                      isLoading: backupState.isExporting,
                      onPressed:
                          backupState.isExporting || backupState.isRestoring
                          ? null
                          : () => _handleExport(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Restore Card Block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.softLavender,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const AppIcon(
                  AppIcons.importFile,
                  color: AppColors.brandViolet,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Restore from Backup',
                      style: AppTypography.itemTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Import data from a previously saved JSON file. Restoring will replace existing local records.',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.mutedInk,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Restore Backup',
                      variant: AppButtonVariant.secondary,
                      icon: const AppIcon(
                        AppIcons.importFile,
                        size: 16,
                        color: AppColors.brandViolet,
                      ),
                      size: AppButtonSize.small,
                      isLoading: backupState.isRestoring,
                      onPressed:
                          backupState.isExporting || backupState.isRestoring
                          ? null
                          : () => _handleRestore(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Atomic Guarantee Safety Callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.softMint.withValues(alpha: 0.6),
              borderRadius: AppRadius.smBorder,
            ),
            child: Row(
              children: [
                const AppIcon(
                  AppIcons.check,
                  size: 14,
                  color: AppColors.inkMint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Atomic guarantee: If an import is interrupted, all changes roll back safely with zero data loss.',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.inkMint,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
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
