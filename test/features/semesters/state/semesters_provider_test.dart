import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

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

  group('Semesters State Management', () {
    test('creates semester and updates active selection', () async {
      final container = createContainer();
      final sub = container.listen(activeSemestersStreamProvider, (_, _) {});

      // Initially no semesters
      final initialSemesters = await container.read(
        activeSemestersStreamProvider.future,
      );
      expect(initialSemesters, isEmpty);
      expect(container.read(activeSemesterProvider), isNull);

      // Create a semester via controller
      final id = await container
          .read(semesterControllerProvider.notifier)
          .createSemester(
            name: 'Semester 1',
            attendanceThreshold: 0.75,
            calculationMethod: AttendanceCalculationMethod.rawCombined,
          );

      expect(id, isNotNull);
      expect(container.read(selectedSemesterIdProvider), equals(id));

      // Wait for stream to emit new event
      await Future<void>.delayed(Duration.zero);
      final activeSemesters = container
          .read(activeSemestersStreamProvider)
          .requireValue;
      expect(activeSemesters.length, equals(1));
      expect(activeSemesters.first.name, equals('Semester 1'));

      // Active semester provider resolves to created semester
      final active = container.read(activeSemesterProvider);
      expect(active, isNotNull);
      expect(active!.id, equals(id));
      sub.close();
    });

    test(
      'active semester fallback selects first active if no explicit selection',
      () async {
        final container = createContainer();
        final sub = container.listen(activeSemestersStreamProvider, (_, _) {});

        // Create two semesters
        final id1 = await container
            .read(semesterControllerProvider.notifier)
            .createSemester(name: 'Sem A');
        final id2 = await container
            .read(semesterControllerProvider.notifier)
            .createSemester(name: 'Sem B');

        // Clear explicit selection
        container.read(selectedSemesterIdProvider.notifier).clearSelection();
        expect(container.read(selectedSemesterIdProvider), isNull);

        // Wait for stream to emit updated list
        await Future<void>.delayed(Duration.zero);
        final activeSemesters = container
            .read(activeSemestersStreamProvider)
            .requireValue;
        expect(activeSemesters.length, equals(2));

        // Provider should default to the first in the active list
        final active = container.read(activeSemesterProvider);
        expect(active, isNotNull);
        expect(active!.id, anyOf(equals(id1), equals(id2)));

        // Explicitly switch
        container
            .read(selectedSemesterIdProvider.notifier)
            .selectSemester(id1!);
        expect(container.read(activeSemesterProvider)?.id, equals(id1));
        sub.close();
      },
    );

    test('archiving active semester clears selection', () async {
      final container = createContainer();

      final id = await container
          .read(semesterControllerProvider.notifier)
          .createSemester(name: 'To Archive');

      expect(container.read(selectedSemesterIdProvider), equals(id));

      await container
          .read(semesterControllerProvider.notifier)
          .archiveSemester(id!, isArchived: true);

      expect(container.read(selectedSemesterIdProvider), isNull);
    });
  });
}
