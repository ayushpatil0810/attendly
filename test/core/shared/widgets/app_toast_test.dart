import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';

void main() {
  group('AppToast Tests', () {
    testWidgets('showSuccess with action sets persist to false and auto-dismisses',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AppToast.showSuccess(
                        context,
                        message: 'Session recorded',
                        actionLabel: 'Undo',
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: const Text('Show Toast'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to show toast
      await tester.tap(find.text('Show Toast'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300)); // Finish entry animation

      // Toast is visible
      expect(find.text('Session recorded'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Verify SnackBar widget has persist == false
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.persist, isFalse);

      // Advance time past the duration (2 seconds)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300)); // Exit animation

      // Verify toast is now dismissed automatically
      expect(find.text('Session recorded'), findsNothing);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('showInfo sets persist to false and auto-dismisses',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AppToast.showInfo(
                        context,
                        message: 'Info message',
                        duration: const Duration(seconds: 1),
                      );
                    },
                    child: const Text('Show Info'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Info message'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.persist, isFalse);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Info message'), findsNothing);
    });

    testWidgets('showError sets persist to false and auto-dismisses',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AppToast.showError(
                        context,
                        message: 'Error message',
                        duration: const Duration(seconds: 1),
                      );
                    },
                    child: const Text('Show Error'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Error message'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.persist, isFalse);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Error message'), findsNothing);
    });
  });
}
