import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import 'session_form_sheet.dart';

/// Reusable Apple capsule pill button for logging a class session.
///
/// Used consistently across both the Dashboard (HomeScreen) and HistoryScreen.
class LogClassButton extends StatelessWidget {
  const LogClassButton({
    super.key,
    required this.selectedDate,
    this.semanticLabel,
    this.onPressed,
  });

  final DateTime selectedDate;
  final String? semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: semanticLabel ?? 'Log class',
      child: Material(
        color: colors.surfaceSubtle.withValues(
          alpha: colors.isDark ? 0.6 : 0.8,
        ),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed ??
              () {
                HapticFeedback.selectionClick();
                showSessionFormSheet(
                  context: context,
                  prefilledDate: selectedDate,
                );
              },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.4 : 0.6,
                ),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  AppIcons.add,
                  size: 14,
                  color: colors.brandPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Log Class',
                  style: AppTypography.caption1.copyWith(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
