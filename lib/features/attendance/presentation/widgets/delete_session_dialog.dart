import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';

Future<bool?> showDeleteSessionDialog({
  required BuildContext context,
  required String subjectName,
  required String componentName,
  required String date,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      title: Text('Delete Session', style: AppTypography.sectionTitle),
      content: Text(
        'Are you sure you want to delete this $componentName session for $subjectName on $date? This session will be permanently removed from attendance calculations.',
        style: AppTypography.bodySmall,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Delete',
                variant: AppButtonVariant.destructive,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
