import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:attendly/features/subjects/presentation/screens/subjects_screen.dart';

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
      child: const MaterialApp(home: SubjectsScreen()),
    );
  }

  testWidgets(
    'SubjectsScreen renders empty state and then subject card after creation',
    (tester) async {
      // Create an active semester
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(name: 'Fall 2026');
      prefs.setInt('selected_active_semester_id_v1', semId);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Fall 2026'), findsOneWidget);
      expect(find.text('No Subjects Added'), findsOneWidget);

      // Create a subject
      final subjRepo = SubjectRepositoryImpl(db);
      await subjRepo.createSubject(
        semesterId: semId,
        name: 'Computer Networks',
        lectureEnabled: true,
        labEnabled: true,
      );

      // Re-pump
      await tester.pumpAndSettle();

      expect(find.text('Computer Networks'), findsOneWidget);
      expect(find.text('Lecture'), findsOneWidget);
      expect(find.text('Lab'), findsOneWidget);
      expect(find.text('No sessions recorded yet (Phase 2)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );
}
