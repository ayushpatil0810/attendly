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
    'Floating dock navigates between tabs and opens Quick Log placeholder',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Initially on Home
      expect(find.text('College Attendance'), findsOneWidget);
      expect(find.text('Fall 2026'), findsOneWidget);

      // Tap Subjects tab
      await tester.tap(find.text('Subjects'));
      await tester.pumpAndSettle();
      expect(find.text('No Subjects Added'), findsOneWidget);

      // Tap History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Attendance History (Phase 2)'), findsOneWidget);

      // Tap Insights tab
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Analytics & Simulator (Phases 3 & 4)'), findsOneWidget);

      // Tap Quick Log (+) button
      await tester.tap(find.byKey(const Key('quick_log_dock_button')));
      await tester.pumpAndSettle();

      expect(find.text('Quick Log Coming in Phase 2'), findsOneWidget);

      // Dismiss bottom sheet
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Log Coming in Phase 2'), findsNothing);

      // Flush any pending microtasks from Stream disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );
}
