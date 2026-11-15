import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';

class QuickLogPlaceholderSheet extends StatelessWidget {
  const QuickLogPlaceholderSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.softLavender,
              borderRadius: AppRadius.xlBorder,
            ),
            alignment: Alignment.center,
            child: const AppIcon(
              AppIcons.quickLog,
              size: 28,
              color: AppColors.brandViolet,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Log Coming in Phase 2',
            style: AppTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'In Phase 2, this button will open an ultra-fast logging sheet: choose your subject, tap Present or Absent, and the session will be saved immediately with an Undo snackbar.',
            style: AppTypography.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Got it',
            isFullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
