import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/notification_preferences_service.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_switch.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_motion.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';

class DailyReminderSection extends ConsumerWidget {
  const DailyReminderSection({super.key});

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay currentTime,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.inkViolet,
              onPrimary: AppColors.pureWhite,
              onSurface: AppColors.ink,
              surface: AppColors.pureWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      await ref
          .read(notificationPreferencesProvider.notifier)
          .setReminderTime(picked);
      AppHaptics.lightImpact(ref);
      if (context.mounted) {
        AppToast.showSuccess(
          context,
          message: 'Reminder time updated to ${picked.format(context)}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferencesProvider);

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
          // Daily Reminder Switch Tile
          AppSwitchTile(
            title: 'Daily Attendance Reminder',
            subtitle: 'Prompt to log your classes for the day',
            icon: AppIcon(
              AppIcons.notification,
              size: 20,
              color: AppColors.brandViolet,
            ),
            value: preferences.dailyReminderEnabled,
            onChanged: (val) async {
              final success = await ref
                  .read(notificationPreferencesProvider.notifier)
                  .setDailyReminderEnabled(val);

              if (val) {
                if (success) {
                  AppHaptics.selectionClick(ref);
                  if (context.mounted) {
                    AppToast.showSuccess(
                      context,
                      message:
                          'Daily reminder scheduled for ${preferences.formattedTime}',
                    );
                  }
                } else if (context.mounted) {
                  AppToast.showError(
                    context,
                    message: 'Notification permission is required to schedule daily reminders.',
                  );
                }
              } else {
                AppHaptics.selectionClick(ref);
                if (context.mounted) {
                  AppToast.showInfo(
                    context,
                    message: 'Daily reminder turned off.',
                  );
                }
              }
            },
          ),

          // Expanded Controls when Reminder is enabled
          AnimatedCrossFade(
            duration: AppMotion.duration(
              context,
              const Duration(milliseconds: 250),
            ),
            crossFadeState: preferences.dailyReminderEnabled
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Selector Row
                  Material(
                    color: Colors.transparent,
                    borderRadius: AppRadius.mdBorder,
                    child: InkWell(
                      borderRadius: AppRadius.mdBorder,
                      onTap: () => _pickReminderTime(
                        context,
                        ref,
                        preferences.reminderTime,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTint.withValues(alpha: 0.6),
                          borderRadius: AppRadius.mdBorder,
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppIcon(
                              AppIcons.clock,
                              size: 18,
                              color: AppColors.inkViolet,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Reminder Time',
                                    style: AppTypography.itemTitle,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Repeats every day at this time',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.mutedInk,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Stylized Time Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softLavender,
                                borderRadius: AppRadius.pillBorder,
                                border: Border.all(
                                  color: AppColors.brandViolet.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    preferences.formattedTime,
                                    style: AppTypography.withTabularFigures(
                                      AppTypography.labelLarge.copyWith(
                                        color: AppColors.inkViolet,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  AppIcon(
                                    AppIcons.edit,
                                    size: 13,
                                    color: AppColors.inkViolet,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Send Test Notification Button
                  AppButton(
                    label: 'Send Test Notification',
                    icon: AppIcon(
                      AppIcons.notification,
                      size: 15,
                      color: AppColors.inkViolet,
                    ),
                    variant: AppButtonVariant.secondary,
                    isFullWidth: true,
                    size: AppButtonSize.small,
                    onPressed: () async {
                      await ref
                          .read(notificationPreferencesProvider.notifier)
                          .sendTestNotification();
                      AppHaptics.lightImpact(ref);
                      if (context.mounted) {
                        AppToast.showSuccess(
                          context,
                          message: 'Test reminder sent! Check your notification tray.',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Privacy & Offline Reassurance Note
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softLavender.withValues(alpha: 0.4),
                      borderRadius: AppRadius.mdBorder,
                      border: Border.all(
                        color: AppColors.brandViolet.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        AppIcon(
                          AppIcons.shield,
                          size: 16,
                          color: AppColors.inkViolet,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '100% offline: reminders are scheduled directly by your device without background tracking or server sync.',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.mutedInk,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
