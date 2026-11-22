import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/backup/backup_format.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';

class BackupSummaryDialog extends StatelessWidget {
  const BackupSummaryDialog({
    super.key,
    required this.summary,
    required this.onConfirm,
  });

  final BackupSummary summary;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(summary.exportedAt.toLocal());

    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? colors.brandPrimary.withValues(alpha: 0.16)
                        : colors.brandPrimarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    AppIcons.importFile,
                    color: colors.brandPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restore Backup',
                        style: AppTypography.screenTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review backup summary',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary content box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.isDark ? colors.surfaceSubtle : colors.background,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Exported', value: formattedDate),
                  Divider(height: 16, color: colors.divider),
                  _SummaryRow(
                    label: 'Semesters',
                    value:
                        '${summary.semestersCount} (${summary.semesterNames.join(', ')})',
                  ),
                  Divider(height: 16, color: colors.divider),
                  _SummaryRow(
                    label: 'Subjects',
                    value: '${summary.subjectsCount}',
                  ),
                  Divider(height: 16, color: colors.divider),
                  _SummaryRow(
                    label: 'Attendance Sessions',
                    value:
                        '${summary.sessionsCount} (${summary.presentCount} Present, ${summary.absentCount} Absent)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Warning Notice Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.accentRed.withValues(alpha: 0.12),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(
                  color: colors.accentRed.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AppIcon(
                      AppIcons.alert,
                      color: colors.accentRed,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Restoring this backup will replace all current semesters, subjects, and attendance sessions on this device. This cannot be undone.',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dialog Actions
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Restore & Replace',
                    variant: AppButtonVariant.destructive,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.labelMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
