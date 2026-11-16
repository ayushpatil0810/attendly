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
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Shield Icon
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.softMint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const AppIcon(
                  AppIcons.shield,
                  color: AppColors.inkMint,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data & Privacy Information',
                      style: AppTypography.itemTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your attendance records belong to you alone.',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.mutedInk,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),

          const _PrivacyItem(
            icon: AppIcons.database,
            iconBgColor: AppColors.softLavender,
            iconColor: AppColors.inkViolet,
            title: '100% Offline & Local Storage',
            description: 'All attendance data is stored exclusively on your device in a local database.',
          ),
          const SizedBox(height: 12),

          const _PrivacyItem(
            icon: AppIcons.shield,
            iconBgColor: AppColors.softMint,
            iconColor: AppColors.inkMint,
            title: 'No Account Required',
            description: 'Attendly requires no sign-in, account creation, personal profile, or password.',
          ),
          const SizedBox(height: 12),

          const _PrivacyItem(
            icon: AppIcons.info,
            iconBgColor: AppColors.softLavender,
            iconColor: AppColors.inkViolet,
            title: 'No Cloud Synchronization',
            description: 'Your attendance records are never automatically uploaded to any remote server or third-party service.',
          ),
          const SizedBox(height: 12),

          const _PrivacyItem(
            icon: AppIcons.exportFile,
            iconBgColor: AppColors.softPeach,
            iconColor: AppColors.inkPeach,
            title: 'Student-Managed Backups',
            description: 'You own your records. Backups are exported manually whenever you choose to save or migrate your data.',
          ),
          const SizedBox(height: 12),

          const _PrivacyItem(
            icon: AppIcons.alert,
            iconBgColor: AppColors.softCoral,
            iconColor: AppColors.inkCoral,
            title: 'Data Safety Reminder',
            description: 'Uninstalling the app or losing your device will delete local attendance records unless you have exported a backup.',
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // App identity badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warmWhite,
                borderRadius: AppRadius.pillBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Attendly • 100% Offline Attendance Tracker',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
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
    required this.iconBgColor,
    required this.iconColor,
  });

  final dynamic icon;
  final String title;
  final String description;
  final Color iconBgColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: AppRadius.smBorder,
          ),
          alignment: Alignment.center,
          child: AppIcon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedInk,
                  fontSize: 12,
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
