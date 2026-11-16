import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/attendance/presentation/screens/history_screen.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  late int semesterId;
  late int subjectId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final semRepo = SemesterRepositoryImpl(db);
    semesterId = await semRepo.createSemester(name: 'Fall 2026');
    prefs.setInt('selected_active_semester_id_v1', semesterId);

    final subjRepo = SubjectRepositoryImpl(db);
    subjectId = await subjRepo.createSubject(
      semesterId: semesterId,
      name: 'Distributed Systems',
      lectureEnabled: true,
      labEnabled: true,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidgetUnderTest({DateTime? initialSelectedDate}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (initialSelectedDate != null)
          selectedDateProvider.overrideWith(
            () => _FixedSelectedDateNotifier(initialSelectedDate),
          ),
      ],
      child: const MaterialApp(home: HistoryScreen()),
    );
  }

  group('HistoryScreen Widget Tests', () {
    testWidgets(
      'renders calendar and empty state when no sessions recorded for selected date',
      (tester) async {
        final testDate = DateTime(2026, 3, 10);
        await tester.pumpWidget(
          createWidgetUnderTest(initialSelectedDate: testDate),
        );
        await tester.pumpAndSettle();

        expect(find.text('History'), findsOneWidget);
        expect(find.text('Calendar & Attendance Timeline'), findsOneWidget);
        expect(find.text('No sessions recorded for this date'), findsOneWidget);
        expect(
          find.text(
            'Classes not entered are unrecorded and never treated as absences.',
          ),
          findsOneWidget,
        );
        expect(find.text('Add Session'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'displays recorded sessions with subject, component and status badges',
      (tester) async {
        final testDate = DateTime(2026, 3, 10);
        final dateStr = '2026-03-10';

        final repo = AttendanceRepositoryImpl(db);
        await repo.createSession(
          subjectId: subjectId,
          sessionDate: dateStr,
          component: SessionComponent.lecture,
          status: AttendanceStatus.present,
        );
        await repo.createSession(
          subjectId: subjectId,
          sessionDate: dateStr,
          component: SessionComponent.lab,
          status: AttendanceStatus.absent,
        );

        await tester.pumpWidget(
          createWidgetUnderTest(initialSelectedDate: testDate),
        );
        await tester.pumpAndSettle();

        // Both sessions visible
        expect(find.text('Distributed Systems'), findsNWidgets(2));
        expect(find.text('Lecture'), findsOneWidget);
        expect(find.text('Lab'), findsOneWidget);
        expect(find.text('Present'), findsOneWidget);
        expect(find.text('Absent'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets('opens session edit sheet when edit icon tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testDate = DateTime(2026, 3, 10);
      final dateStr = '2026-03-10';

      final repo = AttendanceRepositoryImpl(db);
      final sessId = await repo.createSession(
        subjectId: subjectId,
        sessionDate: dateStr,
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(initialSelectedDate: testDate),
      );
      await tester.pumpAndSettle();

      // Tap edit button
      final editBtn = find.byKey(Key('edit_session_$sessId'));
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit Session'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('deletes session after confirming delete dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testDate = DateTime(2026, 3, 10);
      final dateStr = '2026-03-10';

      final repo = AttendanceRepositoryImpl(db);
      final sessId = await repo.createSession(
        subjectId: subjectId,
        sessionDate: dateStr,
        component: SessionComponent.lecture,
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(initialSelectedDate: testDate),
      );
      await tester.pumpAndSettle();

      expect(find.text('Distributed Systems'), findsOneWidget);

      // Tap delete icon on session card
      final deleteBtn = find.byKey(Key('delete_session_$sessId'));
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog opens
      expect(find.text('Delete Session'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete this Lecture session for Distributed Systems on 2026-03-10? This session will be permanently removed from attendance calculations.',
        ),
        findsOneWidget,
      );

      // Tap Delete in dialog
      await tester.tap(find.widgetWithText(AppButton, 'Delete'));
      await tester.pumpAndSettle();

      // Session deleted in DB
      expect(await repo.getSessionById(sessId), isNull);

      // Empty state now shown
      expect(find.text('No sessions recorded for this date'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'opens redesigned historical session drawer (matching quick log style) and logs attendance on the spot when Add Session tapped',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testDate = DateTime(2026, 3, 10);

        await tester.pumpWidget(
          createWidgetUnderTest(initialSelectedDate: testDate),
        );
        await tester.pumpAndSettle();

        // Tap Add Session on History screen
        final addBtn = find.widgetWithText(AppButton, 'Add Session');
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        // Drawer is open with redesigned Quick Attendance Log model style
        expect(find.text('Record Historical Session'), findsOneWidget);
        expect(find.text('Distributed Systems'), findsOneWidget);
        expect(find.text('Theory Lecture'), findsOneWidget);
        expect(find.text('Practical Lab'), findsOneWidget);
        expect(find.text('Done Logging'), findsOneWidget);

        // Tap "+ Present" for Lecture
        final markPresentBtn = find.text('+ Present').first;
        expect(markPresentBtn, findsOneWidget);
        await tester.tap(markPresentBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Immediate session chip feedback in drawer without closing
        expect(find.text('Lec 1: Present'), findsOneWidget);
        expect(find.text('Record Historical Session'), findsOneWidget);

        // Tap "Done Logging" to close drawer
        await tester.tap(find.text('Done Logging'));
        await tester.pumpAndSettle();

        // Drawer is closed and session is now rendered on HistoryScreen
        expect(find.text('Record Historical Session'), findsNothing);
        expect(find.text('Distributed Systems'), findsOneWidget);
        expect(find.text('Lecture'), findsOneWidget);
        expect(find.text('Present'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });
}

class _FixedSelectedDateNotifier extends SelectedDateNotifier {
  _FixedSelectedDateNotifier(this._initial);
  final DateTime _initial;

  @override
  DateTime build() => _initial;
}
