import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final String title;
  final String? description;
  final Widget? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? actionIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle.withValues(
                    alpha: colors.isDark ? 0.6 : 0.8,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.border.withValues(
                      alpha: colors.isDark ? 0.4 : 0.6,
                    ),
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: icon,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: AppTypography.bodyMuted.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              AppButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
                size: AppButtonSize.medium,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
