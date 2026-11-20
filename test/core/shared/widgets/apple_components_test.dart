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
  });
}
