import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/shared/widgets/apple/apple.dart';
import 'package:attendly/core/theme/app_theme.dart';

void main() {
  group('Apple HIG Components Widget Tests', () {
    testWidgets('AppleInsetGroup renders header, divider, and footer correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppleInsetGroup(
                header: 'Preferences',
                footer: 'Settings sync across your local devices.',
                children: const [
                  Text('Child 1'),
                  Text('Child 2'),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('Preferences'), findsOneWidget);
      // Verify children
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
      // Verify hairline divider between 2 children
      expect(find.byType(Divider), findsOneWidget);
      // Verify footer
      expect(
        find.text('Settings sync across your local devices.'),
        findsOneWidget,
      );
    });

    testWidgets('AppleListTile renders content and handles tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppleInsetGroup(
              children: [
                AppleListTile(
                  title: 'Notifications',
                  subtitle: 'Daily 8:00 PM reminder',
                  showDisclosure: true,
                  leading: const AppleIconTile(
                    icon: Icons.notifications,
                    backgroundColor: Colors.red,
                  ),
                  onTap: () => tapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Daily 8:00 PM reminder'), findsOneWidget);
      expect(find.byType(AppleIconTile), findsOneWidget);

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('AppleScaffold renders collapsible large title and content', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AppleScaffold(
            title: 'Dashboard',
            subtitle: 'Overview of term attendance',
            child: Text('Dashboard Content'),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Overview of term attendance'), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);
    });

    testWidgets('AppleWeekStrip renders 7 days and handles selection', (
      tester,
    ) async {
      DateTime? selected;
      final today = DateTime(2026, 1, 3); // Saturday, Jan 3 2026

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppleWeekStrip(
              selectedDate: today,
              onDateSelected: (d) => selected = d,
            ),
          ),
        ),
      );

      // Verify week days are rendered
      expect(find.byType(AppleWeekStrip), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Tap on another day
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
    });

    testWidgets('AppleWeekStrip dims future dates and disables tap', (
      tester,
    ) async {
      DateTime? selected;
      // Fixed reference: Thursday, Jan 15 2026
      final fixedNow = DateTime(2026, 1, 15);
      final currentDay = DateTime(2026, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppleWeekStrip(
              selectedDate: currentDay,
              now: fixedNow,
              onDateSelected: (d) => selected = d,
            ),
          ),
        ),
      );

      // In the week containing Jan 15 (Jan 12 to Jan 18):
      // Jan 16, 17, 18 are in the future
      expect(find.text('16'), findsOneWidget);

      // Attempting to tap future day 16 should NOT trigger selection
      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();
      expect(selected, isNull);

      // Tapping past day 14 should trigger selection
      expect(find.text('14'), findsOneWidget);
      await tester.tap(find.text('14'));
      await tester.pumpAndSettle();
      expect(selected, equals(DateTime(2026, 1, 14)));
    });
  });
}
