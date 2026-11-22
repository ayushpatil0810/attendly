import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/backup/sample_data.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/shared/widgets/apple/apple_list_tile.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/settings/presentation/providers/settings_providers.dart';

import 'backup_summary_dialog.dart';

class BackupRestoreSection extends ConsumerWidget {
  const BackupRestoreSection({super.key});

  void _handleExport(BuildContext context, WidgetRef ref) async {
    final colors = context.colors;
    final result = await ref
        .read(backupControllerProvider.notifier)
        .exportBackup();

    if (!context.mounted) return;

    if (result.isSuccess && !result.isCanceled) {
      AppToast.showSuccess(context, message: 'Backup exported successfully!');
    } else if (!result.isSuccess && result.errorMessage != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.surface,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
          title: Text(
            'Export Failed',
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            'Could not export backup: ${result.errorMessage}',
            style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
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
    final colors = context.colors;
    final validationResult = await ref
        .read(backupControllerProvider.notifier)
        .pickAndValidateBackup();

    if (!context.mounted || validationResult == null) return;

    if (!validationResult.isValid) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.surface,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
          title: Row(
            children: [
              AppIcon(AppIcons.alert, color: colors.accentRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Invalid Backup File',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            validationResult.error ??
                'The selected file could not be verified as a valid Attendly backup.',
            style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
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
            AppToast.showSuccess(
              context,
              message: 'Attendance data restored successfully!',
            );
          } else {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: colors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.lgBorder,
                ),
                title: Text(
                  'Restore Failed',
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                content: Text(
                  'An error occurred during restore. All changes were rolled back and existing data is safe.',
                  style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
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

  void _handleLoadSampleData(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          'Load Sample Data?',
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'This will seed a complete test scenario ("Fall 2026") with 4 subjects, 76 sessions, and day notes. It will replace existing data so you can test calculations and simulators.\n\nAre you sure you want to proceed?',
          style: AppTypography.bodySmall.copyWith(
            color: colors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.headline.copyWith(
                color: colors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
          AppButton(
            label: 'Load Data',
            size: AppButtonSize.small,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final sampleData = SampleData.getSampleBackupData();
              final success = await ref
                  .read(backupControllerProvider.notifier)
                  .executeRestore(sampleData);

              if (!context.mounted) return;

              if (success) {
                AppToast.showSuccess(
                  context,
                  message: 'Sample data loaded! 4 subjects & 76 classes seeded.',
                );
              } else {
                AppToast.showError(
                  context,
                  message: 'Failed to load sample data.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final backupState = ref.watch(backupControllerProvider);

    return AppleInsetGroup(
      header: 'Backup & Restore',
      margin: EdgeInsets.zero,
      children: [
        // Export Tile
        AppleListTile(
          leading: AppleIconTile(
            icon: AppIcons.exportFile,
            backgroundColor: colors.accentGreen,
          ),
          title: 'Export Backup',
          trailing: backupState.isExporting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.brandPrimary,
                  ),
                )
              : null,
          showDisclosure: !backupState.isExporting,
          onTap: backupState.isExporting ? null : () => _handleExport(context, ref),
        ),

        // Restore Tile
        AppleListTile(
          leading: AppleIconTile(
            icon: AppIcons.importFile,
            backgroundColor: colors.brandPrimary,
          ),
          title: 'Restore Backup',
          trailing: backupState.isRestoring
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.brandPrimary,
                  ),
                )
              : null,
          showDisclosure: !backupState.isRestoring,
          onTap: backupState.isRestoring ? null : () => _handleRestore(context, ref),
        ),

        // Seed Sample Data Tile
        AppleListTile(
          leading: AppleIconTile(
            icon: AppIcons.insights,
            backgroundColor: colors.accentOrange,
          ),
          title: 'Load Sample Data',
          trailing: backupState.isRestoring
              ? null
              : Text(
                  'Demo',
                  style: AppTypography.caption1.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          showDisclosure: !backupState.isRestoring,
          onTap: backupState.isRestoring
              ? null
              : () => _handleLoadSampleData(context, ref),
        ),
      ],
    );
  }
}
