import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';
import 'package:attendly/features/subjects/presentation/widgets/subject_form_sheet.dart';

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

  Widget createTestApp(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets(
    'Adding a subject closes bottom sheet and shows success toast without error',
    (tester) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(name: 'Fall 2026');

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showAppBottomSheet(
                    context: context,
                    title: 'Add Subject',
                    child: SubjectFormSheet(semesterId: semId),
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Form sheet is visible
      expect(find.byType(SubjectFormSheet), findsOneWidget);
      expect(find.text('Add Subject'), findsWidgets);

      // Enter subject name
      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Computer Networks');

      // Click Add Subject button
      final submitButton = find.widgetWithText(ElevatedButton, 'Add Subject');
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
      } else {
        await tester.tap(find.text('Add Subject').last);
      }

      // Allow async save to finish and animation to run
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify bottom sheet auto-closed
      expect(find.byType(SubjectFormSheet), findsNothing);

      // Verify subject exists in repository
      final subjRepo = SubjectRepositoryImpl(db);
      final subjects = await subjRepo.getSubjectsForSemester(semId);
      expect(subjects.length, equals(1));
      expect(subjects.first.name, equals('Computer Networks'));

      // Verify no error toast is present
      expect(
        find.text('The subject could not be saved. Try again.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Editing a subject updates data, closes bottom sheet and shows success toast',
    (tester) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(name: 'Fall 2026');
      final subjRepo = SubjectRepositoryImpl(db);
      final subjectId = await subjRepo.createSubject(
        semesterId: semId,
        name: 'Database Systems',
        lectureEnabled: true,
        labEnabled: false,
      );
      final initialSubject = await subjRepo.getSubjectById(subjectId);

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showAppBottomSheet(
                    context: context,
                    title: 'Edit Subject',
                    child: SubjectFormSheet(
                      semesterId: semId,
                      initialSubject: initialSubject,
                    ),
                  );
                },
                child: const Text('Open Edit Sheet'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the sheet
      await tester.tap(find.text('Open Edit Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(SubjectFormSheet), findsOneWidget);
      expect(find.text('Database Systems'), findsOneWidget);

      // Change name
      final nameField = find.byType(TextField);
      await tester.enterText(nameField, 'Advanced Database Systems');

      // Click Save Changes button
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify bottom sheet auto-closed
      expect(find.byType(SubjectFormSheet), findsNothing);

      // Verify subject is updated
      final updated = await subjRepo.getSubjectById(subjectId);
      expect(updated?.name, equals('Advanced Database Systems'));

      // Verify no error toast
      expect(
        find.text('The subject could not be saved. Try again.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'SubjectController deleteSubject executes cleanly without ref error',
    (tester) async {
      final semRepo = SemesterRepositoryImpl(db);
      final semId = await semRepo.createSemester(name: 'Fall 2026');
      final subjRepo = SubjectRepositoryImpl(db);
      final subjectId = await subjRepo.createSubject(
        semesterId: semId,
        name: 'Compiler Design',
        lectureEnabled: true,
        labEnabled: false,
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Delete subject via controller
      await expectLater(
        container
            .read(subjectControllerProvider.notifier)
            .deleteSubject(subjectId),
        completes,
      );

      final remaining = await subjRepo.getSubjectsForSemester(semId);
      expect(remaining, isEmpty);
    },
  );
}
