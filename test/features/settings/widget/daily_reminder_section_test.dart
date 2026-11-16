import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/services/notification_service.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_switch.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/settings/presentation/widgets/daily_reminder_section.dart';

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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeNotificationService = FakeNotificationService();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(fakeNotificationService),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: DailyReminderSection()),
        ),
      ),
    );
  }

  void setLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('DailyReminderSection Widget Tests', () {
    testWidgets('renders daily reminder switch in disabled state by default', (
      tester,
    ) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Daily Attendance Reminder'), findsOneWidget);
      expect(
        find.text('Prompt to log your classes for the day'),
        findsOneWidget,
      );

      final switchFinder = find.byType(AppSwitchTile);
      expect(switchFinder, findsOneWidget);
      final switchTile = tester.widget<AppSwitchTile>(switchFinder);
      expect(switchTile.value, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'toggling switch to enabled expands time selector and test button',
      (tester) async {
        setLargeViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final switchFinder = find.byType(AppSwitchTile);
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(fakeNotificationService.scheduledHour, equals(20));
        expect(fakeNotificationService.scheduledMinute, equals(0));

        // Controls now visible
        expect(find.text('Reminder Time'), findsOneWidget);
        expect(find.text('8:00 PM'), findsOneWidget);
        expect(find.text('Send Test Notification'), findsOneWidget);
        expect(
          find.text(
            '100% offline: reminders are scheduled directly by your device without background tracking or server sync.',
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets('tapping Send Test Notification invokes service', (
      tester,
    ) async {
      setLargeViewport(tester);
      // Pre-enable in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'pref_daily_reminder_enabled_v1': true,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final testBtn = find.widgetWithText(AppButton, 'Send Test Notification');
      expect(testBtn, findsOneWidget);

      await tester.tap(testBtn);
      await tester.pumpAndSettle();

      expect(fakeNotificationService.testNotificationShown, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('toggling off cancels reminder and hides controls', (
      tester,
    ) async {
      setLargeViewport(tester);
      SharedPreferences.setMockInitialValues({
        'pref_daily_reminder_enabled_v1': true,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final switchFinder = find.byType(AppSwitchTile);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(fakeNotificationService.wasCancelled, isTrue);

      final switchTile = tester.widget<AppSwitchTile>(switchFinder);
      expect(switchTile.value, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}
