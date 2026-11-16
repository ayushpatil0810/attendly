import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract interface class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> scheduleDailyAttendanceReminder({
    required int hour,
    required int minute,
    String? title,
    String? body,
  });
  Future<void> cancelDailyAttendanceReminder();
  Future<void> showTestNotification({String? title, String? body});
  Future<bool> areNotificationsEnabled();
}

class NotificationServiceImpl implements NotificationService {
  NotificationServiceImpl({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int dailyReminderId = 1001;
  static const int testNotificationId = 1002;
  static const String reminderChannelId = 'attendly_daily_reminders';
  static const String reminderChannelName = 'Daily Attendance Reminders';
  static const String reminderChannelDescription =
      'Reminds you to log your classes and attendance for the day';

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Retain tz.local fallback on platforms without timezone discovery
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    await initialize();

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final granted = await androidImplementation
          .requestNotificationsPermission();
      return granted ?? false;
    }

    final iosImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  @override
  Future<void> scheduleDailyAttendanceReminder({
    required int hour,
    required int minute,
    String? title,
    String? body,
  }) async {
    await initialize();

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        reminderChannelId,
        reminderChannelName,
        channelDescription: reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id: dailyReminderId,
      title: title ?? 'Time to log attendance!',
      body:
          body ??
          "Take a quick second to record today's classes and stay on track.",
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'attendly_log_attendance',
    );
  }

  @override
  Future<void> cancelDailyAttendanceReminder() async {
    await initialize();
    await _plugin.cancel(id: dailyReminderId);
  }

  @override
  Future<void> showTestNotification({String? title, String? body}) async {
    await initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        reminderChannelId,
        reminderChannelName,
        channelDescription: reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: testNotificationId,
      title: title ?? 'Attendly Reminder',
      body: body ?? 'Daily attendance reminders are working smoothly!',
      notificationDetails: notificationDetails,
      payload: 'attendly_test_notification',
    );
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final enabled = await androidImplementation.areNotificationsEnabled();
      return enabled ?? false;
    }
    return true;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationServiceImpl();
});
