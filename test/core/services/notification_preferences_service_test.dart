import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/services/notification_preferences_service.dart';
import 'package:attendly/core/services/notification_service.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';

class FakeNotificationService implements NotificationService {
  bool permissionsGranted = true;
  bool areEnabled = true;
  bool isInitialized = false;
  int? scheduledHour;
  int? scheduledMinute;
  bool wasCancelled = false;
  bool testNotificationShown = false;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    return permissionsGranted;
  }

  @override
  Future<void> scheduleDailyAttendanceReminder({
    required int hour,
    required int minute,
    String? title,
    String? body,
  }) async {
    scheduledHour = hour;
    scheduledMinute = minute;
    wasCancelled = false;
  }

  @override
  Future<void> cancelDailyAttendanceReminder() async {
    wasCancelled = true;
  }

  @override
  Future<void> showTestNotification({String? title, String? body}) async {
    testNotificationShown = true;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return areEnabled;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeNotificationService fakeNotificationService;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeNotificationService = FakeNotificationService();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(fakeNotificationService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('NotificationPreferencesNotifier Tests', () {
    test('initial state defaults to disabled at 8:00 PM (20:00)', () {
      final state = container.read(notificationPreferencesProvider);
      expect(state.dailyReminderEnabled, isFalse);
      expect(state.reminderHour, equals(20));
      expect(state.reminderMinute, equals(0));
      expect(state.formattedTime, equals('8:00 PM'));
    });

    test('enabling reminder requests permission and schedules at chosen time',
        () async {
      fakeNotificationService.permissionsGranted = true;

      final success = await container
          .read(notificationPreferencesProvider.notifier)
          .setDailyReminderEnabled(true);

      expect(success, isTrue);
      final state = container.read(notificationPreferencesProvider);
      expect(state.dailyReminderEnabled, isTrue);
      expect(fakeNotificationService.scheduledHour, equals(20));
      expect(fakeNotificationService.scheduledMinute, equals(0));
      expect(prefs.getBool('pref_daily_reminder_enabled_v1'), isTrue);
    });

    test('enabling reminder fails and remains disabled if permission is denied',
        () async {
      fakeNotificationService.permissionsGranted = false;

      final success = await container
          .read(notificationPreferencesProvider.notifier)
          .setDailyReminderEnabled(true);

      expect(success, isFalse);
      final state = container.read(notificationPreferencesProvider);
      expect(state.dailyReminderEnabled, isFalse);
      expect(fakeNotificationService.scheduledHour, isNull);
      expect(prefs.getBool('pref_daily_reminder_enabled_v1'), isNull);
    });

    test('disabling reminder cancels alarm and persists state', () async {
      // First enable
      fakeNotificationService.permissionsGranted = true;
      await container
          .read(notificationPreferencesProvider.notifier)
          .setDailyReminderEnabled(true);

      // Now disable
      final success = await container
          .read(notificationPreferencesProvider.notifier)
          .setDailyReminderEnabled(false);

      expect(success, isTrue);
      final state = container.read(notificationPreferencesProvider);
      expect(state.dailyReminderEnabled, isFalse);
      expect(fakeNotificationService.wasCancelled, isTrue);
      expect(prefs.getBool('pref_daily_reminder_enabled_v1'), isFalse);
    });

    test('changing reminder time updates state, prefs, and reschedules if enabled',
        () async {
      // Enable first
      fakeNotificationService.permissionsGranted = true;
      await container
          .read(notificationPreferencesProvider.notifier)
          .setDailyReminderEnabled(true);

      // Change time to 18:30 (6:30 PM)
      await container
          .read(notificationPreferencesProvider.notifier)
          .setReminderTime(const TimeOfDay(hour: 18, minute: 30));

      final state = container.read(notificationPreferencesProvider);
      expect(state.reminderHour, equals(18));
      expect(state.reminderMinute, equals(30));
      expect(state.formattedTime, equals('6:30 PM'));
      expect(prefs.getInt('pref_daily_reminder_hour_v1'), equals(18));
      expect(prefs.getInt('pref_daily_reminder_minute_v1'), equals(30));
      expect(fakeNotificationService.scheduledHour, equals(18));
      expect(fakeNotificationService.scheduledMinute, equals(30));
    });

    test('sending test notification calls service showTestNotification', () async {
      await container
          .read(notificationPreferencesProvider.notifier)
          .sendTestNotification();

      expect(fakeNotificationService.testNotificationShown, isTrue);
    });
  });
}
