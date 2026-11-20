import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/shell/presentation/screens/main_shell_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Create an active semester
    final semRepo = SemesterRepositoryImpl(db);
    final id = await semRepo.createSemester(name: 'Fall 2026');
    prefs.setInt('selected_active_semester_id_v1', id);
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
      child: const MaterialApp(home: MainShellScreen()),
    );
  }

  testWidgets(
    'Floating dock navigates between tabs and opens Quick Log sheet',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Initially on Home
      expect(find.text('attendly'), findsOneWidget);
      expect(find.text('Fall 2026'), findsOneWidget);
      // Empty dashboard verifies duplicate "Your Courses" is removed
      expect(find.text('Start Semester Setup'), findsOneWidget);
      expect(find.text('Your Courses'), findsNothing);

      // Verify dock has active Home tab label, dock tab keys, and quick log button
      expect(find.text('Home'), findsOneWidget);
      expect(find.byKey(const Key('dock_tab_subjects')), findsOneWidget);
      expect(find.byKey(const Key('quick_log_dock_button')), findsOneWidget);
      expect(find.byKey(const Key('dock_tab_history')), findsOneWidget);
      expect(find.byKey(const Key('dock_tab_insights')), findsNothing);

      // Tap Subjects tab
      await tester.tap(find.byKey(const Key('dock_tab_subjects')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('dock_tab_subjects')),
          matching: find.text('Subjects'),
        ),
        findsOneWidget,
      );
      expect(find.text('Enrolled Courses and Attendance'), findsOneWidget);
      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('No Subjects Added'), findsOneWidget);

      // Tap History tab
      await tester.tap(find.byKey(const Key('dock_tab_history')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('dock_tab_history')),
          matching: find.text('History'),
        ),
        findsOneWidget,
      );
      expect(find.text('Calendar & Attendance Timeline'), findsOneWidget);
      expect(find.text('No sessions recorded for this date'), findsOneWidget);

      // Tap Quick Log (+) button
      await tester.tap(find.byKey(const Key('quick_log_dock_button')));
      await tester.pumpAndSettle();

      expect(find.text('Quick Attendance Log'), findsOneWidget);
      expect(find.text('No subjects found'), findsOneWidget);

      // Dismiss bottom sheet
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Attendance Log'), findsNothing);

      // Flush any pending microtasks from Stream disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );
}
