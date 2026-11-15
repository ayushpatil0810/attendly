import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createWidgetUnderTest({WidgetRef? ref}) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: OnboardingScreen()),
    );
  }

  testWidgets('OnboardingScreen navigates pages and updates button label', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Page 1
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Track Lectures & Labs'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Advance to Page 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Know Your Safe Absences'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Advance to Page 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Review & Correct History'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
