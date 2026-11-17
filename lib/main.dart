import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/presentation/providers/onboarding_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style with edge-to-edge mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize NotificationService
  final notificationService = NotificationServiceImpl();
  try {
    await notificationService.initialize();
    final reminderEnabled =
        sharedPreferences.getBool('pref_daily_reminder_enabled_v1') ?? false;
    if (reminderEnabled) {
      final hour =
          sharedPreferences.getInt('pref_daily_reminder_hour_v1') ?? 20;
      final minute =
          sharedPreferences.getInt('pref_daily_reminder_minute_v1') ?? 0;
      await notificationService.scheduleDailyAttendanceReminder(
        hour: hour,
        minute: minute,
      );
    }
  } catch (_) {
    // Non-fatal if platform channels are unavailable on specific desktop runtimes
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const AttendlyApp(),
    ),
  );
}
