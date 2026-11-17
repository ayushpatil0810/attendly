import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

abstract final class AppToast {
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    bool persist = false,
  }) {
    final colors = context.colors;
    _show(
      context,
      message: message,
      backgroundColor: colors.surfaceElevated,
      textColor: colors.textPrimary,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      persist: persist,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    bool persist = false,
  }) {
    final colors = context.colors;
    _show(
      context,
      message: message,
      backgroundColor: colors.accentCoralInk,
      textColor: Colors.white,
      duration: duration,
      persist: persist,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    bool persist = false,
  }) {
    final colors = context.colors;
    _show(
      context,
      message: message,
      backgroundColor: colors.surfaceElevated,
      textColor: colors.textPrimary,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      persist: persist,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color textColor,
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
    required bool persist,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: textColor),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        persist: persist,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 90, // Positioned comfortably above the floating dock
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.brandMint,
                onPressed: () {
                  onAction?.call();
                },
              )
            : null,
      ),
    );
  }
}
