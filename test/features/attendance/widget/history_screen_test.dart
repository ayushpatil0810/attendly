import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/attendance/presentation/screens/history_screen.dart';
import 'package:attendly/features/attendance/presentation/widgets/quick_log_sheet.dart';
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
        expect(find.text('Log Attendance'), findsOneWidget);

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
        expect(find.byIcon(AppIcons.check), findsOneWidget);
        expect(find.byIcon(AppIcons.close), findsOneWidget);

        // Apple HIG crisp 24dp solid status circles with white icons
        final checkIcon = tester.widget<Icon>(find.byIcon(AppIcons.check));
        expect(checkIcon.color, equals(Colors.white));
        expect(checkIcon.size, equals(14));
        final closeIcon = tester.widget<Icon>(find.byIcon(AppIcons.close));
        expect(closeIcon.color, equals(Colors.white));
        expect(closeIcon.size, equals(14));

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets('opens session edit sheet when session row tapped', (
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

      // Tap session row to open edit sheet
      final sessionRow = find.byKey(Key('session_tile_$sessId'));
      expect(sessionRow, findsOneWidget);
      await tester.tap(sessionRow);
      await tester.pumpAndSettle();

      expect(find.text('Edit Session'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('deletes session via swipe-to-delete with undo affordance', (
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

      // Swipe session row left to delete
      final dismissible = find.byKey(Key('session_dismissible_$sessId'));
      expect(dismissible, findsOneWidget);
      await tester.drag(dismissible, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Session deleted in DB
      expect(await repo.getSessionById(sessId), isNull);

      // Undo snackbar shown
      expect(find.text('Session deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Empty state now shown
      expect(find.text('No sessions recorded for this date'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'opens redesigned historical session drawer (matching quick log style) and logs attendance on the spot when Log Attendance tapped',
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

        // Tap Log Attendance on History screen
        final addBtn = find.text('Log Attendance');
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        // Drawer is open with Log Attendance model style
        expect(
          find.descendant(
            of: find.byType(QuickLogSheet),
            matching: find.text('Log Attendance'),
          ),
          findsOneWidget,
        );
        expect(find.text('Distributed Systems'), findsOneWidget);
        expect(find.text('Lecture'), findsOneWidget);
        expect(find.text('Lab'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);

        // Tap "Present" for Lecture
        final markPresentBtn = find.text('Present').first;
        expect(markPresentBtn, findsOneWidget);
        await tester.tap(markPresentBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Immediate live counter feedback on button without closing
        expect(find.text('Present · 1'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(QuickLogSheet),
            matching: find.text('Log Attendance'),
          ),
          findsOneWidget,
        );

        // Tap "Done" to close drawer
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Drawer is closed and session is now rendered on HistoryScreen
        expect(find.byType(QuickLogSheet), findsNothing);
        expect(find.text('Distributed Systems'), findsOneWidget);
        expect(find.text('Lecture'), findsOneWidget);
        expect(find.byIcon(AppIcons.check), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'hides Log Attendance button and shows Future date placeholder on future dates',
      (tester) async {
        final futureDate = DateTime(2099, 5, 20);
        await tester.pumpWidget(
          createWidgetUnderTest(initialSelectedDate: futureDate),
        );
        await tester.pumpAndSettle();

        // Header shows date
        expect(find.text('History'), findsOneWidget);

        // Log Attendance button is hidden for future date
        expect(find.text('+ Log Attendance'), findsNothing);

        // Add note button is hidden for future date
        expect(find.text('+ Add note for this day'), findsNothing);

        // Empty state shows future date notice
        expect(find.text('Future date'), findsOneWidget);
        expect(
          find.text('Attendance cannot be logged in advance.'),
          findsOneWidget,
        );

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
