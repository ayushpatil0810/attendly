import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import 'session_form_sheet.dart';

/// Reusable Apple capsule pill button for logging attendance.
///
/// Used consistently across both the Dashboard (HomeScreen) and HistoryScreen.
class LogAttendanceButton extends StatelessWidget {
  const LogAttendanceButton({
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
            .isAfter(today);

    if (isFuture) {
      return const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? 'Log attendance',
      child: Material(
        color: colors.surfaceSubtle.withValues(
          alpha: colors.isDark ? 0.6 : 0.8,
        ),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed ??
              () {
                showSessionFormSheet(
                  context: context,
                  prefilledDate: selectedDate,
                );
              },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
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
                  'Log Attendance',
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

/// Backwards compatibility alias for LogAttendanceButton
typedef LogClassButton = LogAttendanceButton;
