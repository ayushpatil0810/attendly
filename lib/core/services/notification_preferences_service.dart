import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/notification_service.dart';
import 'package:attendly/core/providers/shared_preferences_provider.dart';

const String _dailyReminderEnabledKey = 'pref_daily_reminder_enabled_v1';
const String _dailyReminderHourKey = 'pref_daily_reminder_hour_v1';
const String _dailyReminderMinuteKey = 'pref_daily_reminder_minute_v1';

class NotificationPreferencesState {
  const NotificationPreferencesState({
    required this.dailyReminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
  });

  final bool dailyReminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);

  String get formattedTime {
    final hour12 = reminderHour % 12 == 0 ? 12 : reminderHour % 12;
    final minutePadded = reminderMinute.toString().padLeft(2, '0');
    final period = reminderHour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minutePadded $period';
  }

  NotificationPreferencesState copyWith({
    bool? dailyReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return NotificationPreferencesState(
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferencesState> {
  @override
  NotificationPreferencesState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final enabled = prefs.getBool(_dailyReminderEnabledKey) ?? false;
    final hour = prefs.getInt(_dailyReminderHourKey) ?? 20; // 8:00 PM default
    final minute = prefs.getInt(_dailyReminderMinuteKey) ?? 0;

    return NotificationPreferencesState(
      dailyReminderEnabled: enabled,
      reminderHour: hour,
      reminderMinute: minute,
    );
  }

  Future<bool> setDailyReminderEnabled(bool enabled) async {
    final notificationService = ref.read(notificationServiceProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    if (enabled) {
      final granted = await notificationService.requestPermissions();
      if (!granted) {
        return false;
      }

      await notificationService.scheduleDailyAttendanceReminder(
        hour: state.reminderHour,
        minute: state.reminderMinute,
      );

      await prefs.setBool(_dailyReminderEnabledKey, true);
      state = state.copyWith(dailyReminderEnabled: true);
      return true;
    } else {
      await notificationService.cancelDailyAttendanceReminder();
      await prefs.setBool(_dailyReminderEnabledKey, false);
      state = state.copyWith(dailyReminderEnabled: false);
      return true;
    }
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_dailyReminderHourKey, time.hour);
    await prefs.setInt(_dailyReminderMinuteKey, time.minute);

    state = state.copyWith(
      reminderHour: time.hour,
      reminderMinute: time.minute,
    );

    if (state.dailyReminderEnabled) {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.scheduleDailyAttendanceReminder(
        hour: time.hour,
        minute: time.minute,
      );
    }
  }

  Future<void> sendTestNotification() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.showTestNotification();
  }
}

final notificationPreferencesProvider =
    NotifierProvider<
      NotificationPreferencesNotifier,
      NotificationPreferencesState
    >(NotificationPreferencesNotifier.new);
