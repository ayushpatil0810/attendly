import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/notification_preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/shared/widgets/apple/apple_list_tile.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';

class DailyReminderSection extends ConsumerWidget {
  const DailyReminderSection({super.key});

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay currentTime,
  ) async {
    final colors = context.colors;
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: colors.isDark
                ? ColorScheme.dark(
                    primary: colors.brandPrimary,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: colors.brandPrimary,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
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
    final colors = context.colors;
    final preferences = ref.watch(notificationPreferencesProvider);

    return AppleInsetGroup(
      header: 'Daily Reminder',
      margin: EdgeInsets.zero,
      children: [
        // Daily Attendance Reminder Switch Row
        AppleListTile(
          leading: AppleIconTile(
            icon: AppIcons.notification,
            backgroundColor: colors.brandPrimary,
          ),
          title: 'Daily Attendance Reminder',
          trailing: Switch.adaptive(
            value: preferences.dailyReminderEnabled,
            activeColor: Colors.white,
            activeTrackColor: colors.brandPrimary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: colors.isDark
                ? const Color(0xFF39393D)
                : const Color(0xFFE9E9EA),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            thumbColor: WidgetStateProperty.all(Colors.white),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? colors.brandPrimary
                  : (colors.isDark
                      ? const Color(0xFF39393D)
                      : const Color(0xFFE9E9EA)),
            ),
            onChanged: (val) async {
              final success = await ref
                  .read(notificationPreferencesProvider.notifier)
                  .setDailyReminderEnabled(val);

              if (val) {
                if (success) {
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
                    message:
                        'Notification permission is required to schedule daily reminders.',
                  );
                }
              } else {
                if (context.mounted) {
                  AppToast.showInfo(
                    context,
                    message: 'Daily reminder turned off.',
                  );
                }
              }
            },
          ),
        ),

        // Reminder Time Row (dimmed and disabled when reminder is OFF)
        AnimatedOpacity(
          opacity: preferences.dailyReminderEnabled ? 1.0 : 0.38,
          duration: const Duration(milliseconds: 200),
          child: AppleListTile(
            enabled: preferences.dailyReminderEnabled,
            leading: AppleIconTile(
              icon: AppIcons.clock,
              backgroundColor: preferences.dailyReminderEnabled
                  ? colors.brandPrimary
                  : (colors.isDark
                      ? const Color(0xFF39393D)
                      : const Color(0xFFE9E9EA)),
            ),
            title: 'Reminder Time',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: preferences.dailyReminderEnabled
                    ? (colors.isDark
                        ? colors.brandPrimary.withValues(alpha: 0.16)
                        : colors.brandPrimarySoft)
                    : colors.surfaceSubtle,
                borderRadius: AppRadius.pillBorder,
              ),
              child: Text(
                preferences.formattedTime,
                style: AppTypography.withTabularFigures(
                  AppTypography.labelLarge.copyWith(
                    color: preferences.dailyReminderEnabled
                        ? colors.brandPrimary
                        : colors.textTertiary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            showDisclosure: preferences.dailyReminderEnabled,
            onTap: preferences.dailyReminderEnabled
                ? () => _pickReminderTime(
                      context,
                      ref,
                      preferences.reminderTime,
                    )
                : null,
          ),
        ),
      ],
    );
  }
}
