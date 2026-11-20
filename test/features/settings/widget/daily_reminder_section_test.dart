import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/services/notification_service.dart';
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

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'toggling switch to enabled expands time selector',
      (tester) async {
        setLargeViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final switchFinder = find.byType(Switch);
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(fakeNotificationService.scheduledHour, equals(20));
        expect(fakeNotificationService.scheduledMinute, equals(0));

        // Controls now visible
        expect(find.text('Reminder Time'), findsOneWidget);
        expect(find.text('8:00 PM'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

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

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(fakeNotificationService.wasCancelled, isTrue);

      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}
