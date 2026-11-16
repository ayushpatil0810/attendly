import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
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

  group('Attendance State Management & Reactivity', () {
    test('SelectedDateNotifier updates selected date and returns to today', () {
      final container = createContainer();
      final notifier = container.read(selectedDateProvider.notifier);
      final initial = container.read(selectedDateProvider);
      final now = DateTime.now();
      expect(initial.year, equals(now.year));
      expect(initial.month, equals(now.month));
      expect(initial.day, equals(now.day));

      final target = DateTime(2026, 3, 5);
      notifier.selectDate(target);
      expect(
        container.read(selectedDateProvider),
        equals(DateTime(2026, 3, 5)),
      );

      notifier.selectToday();
      expect(container.read(selectedDateProvider).day, equals(now.day));
    });

    test('CurrentMonthNotifier navigates months correctly', () {
      final container = createContainer();
      final notifier = container.read(currentMonthProvider.notifier);
      notifier.setMonth(DateTime(2026, 5, 1));
      expect(
        container.read(currentMonthProvider),
        equals(DateTime(2026, 5, 1)),
      );

      notifier.previousMonth();
      expect(
        container.read(currentMonthProvider),
        equals(DateTime(2026, 4, 1)),
      );

      notifier.nextMonth();
      expect(
        container.read(currentMonthProvider),
        equals(DateTime(2026, 5, 1)),
      );
    });

    test(
      'recording, editing, and deleting a session updates reactive streams',
      () async {
        final container = createContainer();
        final sub1 = container.listen(activeSemestersStreamProvider, (_, _) {});
        final sub2 = container.listen(
          sessionsForSelectedDateProvider,
          (_, _) {},
        );

        // 1. Create active semester
        final semId = await container
            .read(semesterControllerProvider.notifier)
            .createSemester(name: 'Active Sem');
        await container.read(activeSemestersStreamProvider.future);
        expect(container.read(activeSemesterProvider)?.id, equals(semId));

        // 2. Create subject
        final subId = await container
            .read(subjectControllerProvider.notifier)
            .createSubject(
              semesterId: semId!,
              name: 'Software Engineering',
              lectureEnabled: true,
              labEnabled: true,
            );
        expect(subId, isNotNull);

        final date = DateTime(2026, 3, 10);
        container.read(selectedDateProvider.notifier).selectDate(date);
        final dateStr = formatDateOnly(date);

        // Initially empty sessions
        await container.read(sessionsForSelectedDateProvider.future);
        var sessions = container
            .read(sessionsForSelectedDateProvider)
            .requireValue;
        expect(sessions, isEmpty);

        // 3. Record session
        final controller = container.read(
          attendanceControllerProvider.notifier,
        );
        final sessId = await controller.recordSession(
          subjectId: subId,
          sessionDate: dateStr,
          component: SessionComponent.lecture,
          status: AttendanceStatus.absent,
        );
        expect(sessId, greaterThan(0));

        await Future<void>.delayed(Duration.zero);
        sessions = container.read(sessionsForSelectedDateProvider).requireValue;
        expect(sessions.length, equals(1));
        expect(sessions.first.status, equals(AttendanceStatus.absent));

        // 4. Update session from Absent to Present
        final session = sessions.first;
        await controller.updateSession(
          session.copyWith(status: AttendanceStatus.present),
        );

        await Future<void>.delayed(Duration.zero);
        sessions = container.read(sessionsForSelectedDateProvider).requireValue;
        expect(sessions.first.status, equals(AttendanceStatus.present));

        // 5. Delete session
        await controller.deleteSession(sessions.first);

        await Future<void>.delayed(Duration.zero);
        sessions = container.read(sessionsForSelectedDateProvider).requireValue;
        expect(sessions, isEmpty);

        sub1.close();
        sub2.close();
      },
    );

    test('undo after recordSession deletes the recorded session', () async {
      final container = createContainer();
      final sub1 = container.listen(activeSemestersStreamProvider, (_, _) {});

      final semId = await container
          .read(semesterControllerProvider.notifier)
          .createSemester(name: 'Undo Sem');
      await container.read(activeSemestersStreamProvider.future);

      final subId = await container
          .read(subjectControllerProvider.notifier)
          .createSubject(
            semesterId: semId!,
            name: 'Physics',
            lectureEnabled: true,
            labEnabled: false,
          );

      final dateStr = '2026-03-10';
      final controller = container.read(attendanceControllerProvider.notifier);
      final id = await controller.recordSession(
        subjectId: subId,
        sessionDate: dateStr,
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      final repo = container.read(attendanceRepositoryProvider);
      expect(await repo.getSessionById(id), isNotNull);

      // Perform Undo
      await controller.undo();
      expect(await repo.getSessionById(id), isNull);

      sub1.close();
    });

    test('undo after deleteSession restores the deleted session', () async {
      final container = createContainer();
      final sub1 = container.listen(activeSemestersStreamProvider, (_, _) {});

      final semId = await container
          .read(semesterControllerProvider.notifier)
          .createSemester(name: 'Undo Restore Sem');
      await container.read(activeSemestersStreamProvider.future);

      final subId = await container
          .read(subjectControllerProvider.notifier)
          .createSubject(
            semesterId: semId!,
            name: 'Chemistry',
            lectureEnabled: true,
            labEnabled: true,
          );

      final dateStr = '2026-03-10';
      final controller = container.read(attendanceControllerProvider.notifier);
      final id = await controller.recordSession(
        subjectId: subId,
        sessionDate: dateStr,
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      final repo = container.read(attendanceRepositoryProvider);
      final session = (await repo.getSessionById(id))!;

      await controller.deleteSession(session);
      expect(await repo.getSessionById(id), isNull);

      // Perform Undo
      await controller.undo();
      final restored = await repo.getSessionBySubjectDateComponent(
        subId,
        dateStr,
        SessionComponent.lecture,
      );
      expect(restored, isNotNull);
      expect(restored!.status, equals(AttendanceStatus.present));

      sub1.close();
    });

    test('a second lecture on the same day is recorded', () async {
      final container = createContainer();
      final sub1 = container.listen(activeSemestersStreamProvider, (_, _) {});

      final semId = await container
          .read(semesterControllerProvider.notifier)
          .createSemester(name: 'Duplicate Sem');
      await container.read(activeSemestersStreamProvider.future);

      final subId = await container
          .read(subjectControllerProvider.notifier)
          .createSubject(
            semesterId: semId!,
            name: 'Biology',
            lectureEnabled: true,
            labEnabled: false,
          );

      final dateStr = '2026-03-10';
      final controller = container.read(attendanceControllerProvider.notifier);
      await controller.recordSession(
        subjectId: subId,
        sessionDate: dateStr,
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      final secondId = await controller.recordSession(
        subjectId: subId,
        sessionDate: dateStr,
        component: SessionComponent.lecture,
        status: AttendanceStatus.absent,
      );
      expect(secondId, isNot(equals(0)));
      final rows = await db.select(db.attendanceSessions).get();
      expect(rows.where((row) => row.sessionDate == dateStr).length, equals(2));

      sub1.close();
    });
  });
}
