import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/semesters/presentation/screens/semester_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: SemesterSetupScreen()),
    );
  }

  testWidgets('SemesterSetupScreen shows validation error when name is empty', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Set Up First Semester'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);

    // Tap Save & Continue with blank field
    await tester.tap(find.text('Save & Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a semester name.'), findsOneWidget);
  });

  testWidgets(
    'SemesterSetupScreen successfully creates semester with valid input',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextFormField), 'Semester 3');
      await tester.pumpAndSettle();

      // Tap Save & Continue
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      // Check database has record
      final repo = SemesterRepositoryImpl(db);
      final semesters = await repo.getSemesters();
      expect(semesters.length, equals(1));
      expect(semesters.first.name, equals('Semester 3'));
      expect(semesters.first.attendanceThreshold, equals(0.75));
    },
  );

  testWidgets(
    'renders Scan QR to Import Semester button',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Scan QR to Import Semester'), findsOneWidget);
    },
  );
}
