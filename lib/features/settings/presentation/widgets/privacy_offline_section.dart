import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';

class PrivacyOfflineSection extends StatelessWidget {
  const PrivacyOfflineSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withAlpha(6),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.softMint,
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  AppIcons.shield,
                  color: AppColors.inkMint,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Data & Privacy Information',
                style: AppTypography.itemTitle,
              ),
            ],
          ),
          const SizedBox(height: 14),

          _PrivacyItem(
            icon: AppIcons.database,
            title: '100% Offline & Local Storage',
            description: 'All attendance data is stored exclusively on your device in a local database.',
          ),
          const SizedBox(height: 10),

          _PrivacyItem(
            icon: AppIcons.shield,
            title: 'No Account Required',
            description: 'Attendly requires no sign-in, account creation, personal profile, or password.',
          ),
          const SizedBox(height: 10),

          _PrivacyItem(
            icon: AppIcons.info,
            title: 'No Cloud Synchronization',
            description: 'Your attendance records are never automatically uploaded to any remote server or third-party service.',
          ),
          const SizedBox(height: 10),

          _PrivacyItem(
            icon: AppIcons.exportFile,
            title: 'Student-Managed Backups',
            description: 'You own your records. Backups are exported manually whenever you choose to save or migrate your data.',
          ),
          const SizedBox(height: 10),

          _PrivacyItem(
            icon: AppIcons.alert,
            title: 'Data Safety Reminder',
            description: 'Uninstalling the app or losing your device will delete local attendance records unless you have exported a backup.',
            iconColor: AppColors.brandCoral,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),

          // App build info
          Center(
            child: Text(
              'Attendly • 100% Offline Attendance Tracker',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mutedInk,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor = AppColors.brandViolet,
  });

  final dynamic icon;
  final String title;
  final String description;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: AppIcon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedInk,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
