import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_text_field.dart';
import 'package:attendly/features/attendance/data/repositories/day_note_repository_impl.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/attendance/presentation/screens/history_screen.dart';
import 'package:attendly/features/attendance/presentation/widgets/attendance_calendar.dart';
import 'package:attendly/features/attendance/presentation/widgets/day_note_banner.dart';
import 'package:attendly/features/attendance/presentation/widgets/quick_log_sheet.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

class _FixedSelectedDateNotifier extends SelectedDateNotifier {
  _FixedSelectedDateNotifier(this._initialDate);
  final DateTime _initialDate;

  @override
  DateTime build() => _initialDate;
}

class _FixedCurrentMonthNotifier extends CurrentMonthNotifier {
  _FixedCurrentMonthNotifier(this._initialMonth);
  final DateTime _initialMonth;

  @override
  DateTime build() => _initialMonth;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  late int semesterId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final semRepo = SemesterRepositoryImpl(db);
    semesterId = await semRepo.createSemester(name: 'Fall 2026');
    prefs.setInt('selected_active_semester_id_v1', semesterId);

    final subjRepo = SubjectRepositoryImpl(db);
    await subjRepo.createSubject(
      semesterId: semesterId,
      name: 'Mobile Computing',
      lectureEnabled: true,
      labEnabled: false,
    );
  });

  tearDown(() async {
    await db.close();
  });

  void setTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
  }

  Widget createWidgetUnderTest({
    required Widget child,
    DateTime? initialSelectedDate,
    DateTime? initialMonth,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (initialSelectedDate != null)
          selectedDateProvider.overrideWith(
            () => _FixedSelectedDateNotifier(initialSelectedDate),
          ),
        if (initialMonth != null)
          currentMonthProvider.overrideWith(
            () => _FixedCurrentMonthNotifier(initialMonth),
          ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('DayNoteBanner Widget Tests', () {
    testWidgets('renders "+ Add note for this day" when no note exists', (
      tester,
    ) async {
      setTestViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const DayNoteBanner(dateStr: '2026-03-10'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+ Add note for this day'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'opens dialog, saves a note, and displays the content in banner',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createWidgetUnderTest(
            child: const DayNoteBanner(dateStr: '2026-03-10'),
          ),
        );
        await tester.pumpAndSettle();

        // Tap to open dialog
        await tester.tap(find.text('+ Add note for this day'));
        await tester.pumpAndSettle();

        // Dialog is open
        expect(find.text('Add Day Note'), findsOneWidget);

        // Enter note text
        await tester.enterText(
          find.byType(AppTextField),
          'Sports Day - No lectures held',
        );
        await tester.pump();

        // Tap Save
        await tester.tap(find.widgetWithText(AppButton, 'Save'));
        await tester.pumpAndSettle();

        // Banner now shows note text
        expect(find.text('Sports Day - No lectures held'), findsOneWidget);
        expect(find.byTooltip('Edit day note'), findsOneWidget);
        expect(find.byTooltip('Delete day note'), findsOneWidget);

        // Verify persisted in DB
        final noteRepo = DayNoteRepositoryImpl(db);
        final note = await noteRepo.getNoteForDate(semesterId, '2026-03-10');
        expect(note, isNotNull);
        expect(note!.content, equals('Sports Day - No lectures held'));

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets('edits existing note via edit button and dialog', (
      tester,
    ) async {
      setTestViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final noteRepo = DayNoteRepositoryImpl(db);
      await noteRepo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-10',
        content: 'Initial text',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const DayNoteBanner(dateStr: '2026-03-10'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Initial text'), findsOneWidget);

      // Tap edit button
      await tester.tap(find.byTooltip('Edit day note'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Day Note'), findsOneWidget);

      // Update text
      await tester.enterText(
        find.byType(AppTextField),
        'Updated: Rain holiday',
      );
      await tester.pump();

      // Tap Save
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Updated: Rain holiday'), findsOneWidget);

      final note = await noteRepo.getNoteForDate(semesterId, '2026-03-10');
      expect(note!.content, equals('Updated: Rain holiday'));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('deletes note via delete button on banner', (tester) async {
      setTestViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final noteRepo = DayNoteRepositoryImpl(db);
      await noteRepo.setNoteForDate(
        semesterId: semesterId,
        date: '2026-03-10',
        content: 'Note to be removed',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const DayNoteBanner(dateStr: '2026-03-10'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Note to be removed'), findsOneWidget);

      // Tap delete icon
      await tester.tap(find.byTooltip('Delete day note'));
      await tester.pumpAndSettle();

      // Banner reverts back to "+ Add note for this day"
      expect(find.text('+ Add note for this day'), findsOneWidget);
      expect(find.text('Note to be removed'), findsNothing);

      // Verify removed from DB
      final note = await noteRepo.getNoteForDate(semesterId, '2026-03-10');
      expect(note, isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });

  group('AttendanceCalendar with Day Note Tests', () {
    testWidgets(
      'renders calendar cell with "Has note" semantic and dot indicator when note exists',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testDate = DateTime(2026, 3, 15);
        final noteRepo = DayNoteRepositoryImpl(db);
        await noteRepo.setNoteForDate(
          semesterId: semesterId,
          date: '2026-03-15',
          content: 'Midterm exam week',
        );

        await tester.pumpWidget(
          createWidgetUnderTest(
            child: const AttendanceCalendar(),
            initialMonth: DateTime(2026, 3, 1),
            initialSelectedDate: testDate,
          ),
        );
        await tester.pumpAndSettle();

        // Verify day 15 has semantics label containing 'Has note'
        final day15Semantics = find.bySemanticsLabel(
          RegExp(r'Day 15.*Has note'),
        );
        expect(day15Semantics, findsOneWidget);

        // Day without note does NOT contain 'Has note'
        final day14Semantics = find.bySemanticsLabel(
          RegExp(r'Day 14.*Has note'),
        );
        expect(day14Semantics, findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });

  group('DayNote Integration in HistoryScreen and QuickLogSheet', () {
    testWidgets(
      'shows DayNoteBanner in HistoryScreen below selected date header',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testDate = DateTime(2026, 3, 10);
        await tester.pumpWidget(
          createWidgetUnderTest(
            child: const HistoryScreen(),
            initialSelectedDate: testDate,
            initialMonth: DateTime(2026, 3, 1),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DayNoteBanner), findsOneWidget);
        expect(find.text('+ Add note for this day'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'shows DayNoteBanner in QuickLogSheet and allows adding note from sheet',
      (tester) async {
        setTestViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testDate = DateTime(2026, 3, 10);
        await tester.pumpWidget(
          createWidgetUnderTest(child: QuickLogSheet(initialDate: testDate)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DayNoteBanner), findsOneWidget);
        expect(find.text('+ Add note for this day'), findsOneWidget);

        // Open dialog from QuickLogSheet
        await tester.tap(find.text('+ Add note for this day'));
        await tester.pumpAndSettle();

        expect(find.text('Add Day Note'), findsOneWidget);

        await tester.enterText(find.byType(AppTextField), 'Logged from drawer');
        await tester.pump();

        await tester.tap(find.widgetWithText(AppButton, 'Save'));
        await tester.pumpAndSettle();

        expect(find.text('Logged from drawer'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });
}
