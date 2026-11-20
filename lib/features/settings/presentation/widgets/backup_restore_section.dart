import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/preferences_service.dart';
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
    AppHaptics.selectionClick(ref);
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
              AppIcon(AppIcons.alert, color: colors.accentCoral, size: 20),
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
            AppHaptics.lightImpact(ref);
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
            backgroundColor: colors.accentMint,
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
            backgroundColor: colors.isDark
                ? const Color(0xFF0A84FF)
                : const Color(0xFF007AFF),
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
      ],
    );
  }
}
