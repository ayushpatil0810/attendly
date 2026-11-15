import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.screenTop,
            bottom: AppSpacing.dockClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('History', style: AppTypography.screenTitle),
              const SizedBox(height: 4),
              Text(
                'Calendar & Attendance Timeline',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 32),

              // Placeholder Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: AppRadius.xlBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.softPeach,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const AppIcon(
                        AppIcons.history,
                        size: 32,
                        color: AppColors.brandPeach,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Attendance History (Phase 2)',
                      style: AppTypography.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The calendar history and past session editing workflow will be implemented in Phase 2.',
                      style: AppTypography.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _FeatureBullet(
                      icon: AppIcons.calendar,
                      text: 'Monthly calendar view with Present / Absent dots',
                    ),
                    const SizedBox(height: 12),
                    _FeatureBullet(
                      icon: AppIcons.edit,
                      text: 'Add, update or delete historical class records',
                    ),
                    const SizedBox(height: 12),
                    _FeatureBullet(
                      icon: AppIcons.check,
                      text: 'Date-only storage with zero timezone shifts',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.icon, required this.text});

  final dynamic icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.track,
            borderRadius: AppRadius.smBorder,
          ),
          child: AppIcon(icon, size: 16, color: AppColors.ink),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTypography.bodySmall)),
      ],
    );
  }
}
