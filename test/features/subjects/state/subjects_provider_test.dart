import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

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

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Subjects State Management', () {
    test('creates, updates, and deletes subjects in active semester', () async {
      final container = createContainer();
      final sub1 = container.listen(activeSemestersStreamProvider, (_, _) {});
      final sub2 = container.listen(activeSemesterSubjectsProvider, (_, _) {});

      // Create an active semester
      final semId = await container
          .read(semesterControllerProvider.notifier)
          .createSemester(name: 'Active Sem');

      // Wait for active semester provider to settle
      await container.read(activeSemestersStreamProvider.future);
      expect(container.read(activeSemesterProvider)?.id, equals(semId));

      // Initially no subjects
      var subjects = await container.read(
        activeSemesterSubjectsProvider.future,
      );
      expect(subjects, isEmpty);

      // Create subject via controller
      final subId = await container
          .read(subjectControllerProvider.notifier)
          .createSubject(
            semesterId: semId!,
            name: 'Linear Algebra',
            lectureEnabled: true,
            labEnabled: false,
          );

      expect(subId, isNotNull);

      // Stream emits newly created subject
      await Future<void>.delayed(Duration.zero);
      subjects = container.read(activeSemesterSubjectsProvider).requireValue;
      expect(subjects.length, equals(1));
      expect(subjects.first.name, equals('Linear Algebra'));
      expect(subjects.first.lectureEnabled, isTrue);
      expect(subjects.first.labEnabled, isFalse);

      // Update subject
      await container
          .read(subjectControllerProvider.notifier)
          .updateSubject(
            subjects.first.copyWith(
              name: 'Linear Algebra II',
              labEnabled: true,
            ),
          );

      await Future<void>.delayed(Duration.zero);
      subjects = container.read(activeSemesterSubjectsProvider).requireValue;
      expect(subjects.first.name, equals('Linear Algebra II'));
      expect(subjects.first.labEnabled, isTrue);

      // Delete subject
      await container
          .read(subjectControllerProvider.notifier)
          .deleteSubject(subId);

      await Future<void>.delayed(Duration.zero);
      subjects = container.read(activeSemesterSubjectsProvider).requireValue;
      expect(subjects, isEmpty);

      sub1.close();
      sub2.close();
    });
  });
}
