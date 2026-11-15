import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_switch.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';

class AppPreferencesSection extends ConsumerWidget {
  const AppPreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Haptic Feedback Toggle
          AppSwitchTile(
            title: 'Haptic Feedback',
            subtitle: 'Provide tactile vibration when logging classes and tapping actions',
            icon: const AppIcon(
              AppIcons.device,
              size: 20,
              color: AppColors.brandViolet,
            ),
            value: preferences.hapticFeedbackEnabled,
            onChanged: (val) {
              ref.read(appPreferencesProvider.notifier).setHapticFeedback(val);
              if (val) {
                AppHaptics.selectionClick(ref);
              }
            },
          ),
          const SizedBox(height: 12),

          // Animation & Reduced Motion Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const AppIcon(
                  AppIcons.info,
                  size: 18,
                  color: AppColors.mutedInk,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reduced Motion',
                        style: AppTypography.itemTitle.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Animations automatically adapt to your device\'s system accessibility preferences.',
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
          ),
        ],
      ),
    );
  }
}
