import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_day_schedule_card.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

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

  Widget createWidgetUnderTest({required DateTime selectedDate}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardDayScheduleCard(selectedDate: selectedDate),
          ),
        ),
      ),
    );
  }

  testWidgets('DashboardDayScheduleCard renders empty state and logs session on tap', (
    tester,
  ) async {
    final semRepo = SemesterRepositoryImpl(db);
    final semId = await semRepo.createSemester(name: 'Spring 2026');
    prefs.setInt('selected_active_semester_id_v1', semId);

    final today = DateTime.now();

    await tester.pumpWidget(createWidgetUnderTest(selectedDate: today));
    await tester.pumpAndSettle();

    expect(find.text("Today's Schedule"), findsOneWidget);
    expect(find.text('Log Class'), findsOneWidget);
    expect(find.text('No classes recorded for this date'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('DashboardDayScheduleCard renders classes when sessions exist', (
    tester,
  ) async {
    final semRepo = SemesterRepositoryImpl(db);
    final semId = await semRepo.createSemester(name: 'Spring 2026');
    prefs.setInt('selected_active_semester_id_v1', semId);

    final subjRepo = SubjectRepositoryImpl(db);
    final subId = await subjRepo.createSubject(
      semesterId: semId,
      name: 'Computer Networks',
      lectureEnabled: true,
      labEnabled: false,
    );

    final targetDate = DateTime(2026, 3, 10);
    final attRepo = AttendanceRepositoryImpl(db);
    await attRepo.createSession(
      subjectId: subId,
      sessionDate: formatDateOnly(targetDate),
      component: SessionComponent.lecture,
      status: AttendanceStatus.present,
    );

    await tester.pumpWidget(createWidgetUnderTest(selectedDate: targetDate));
    await tester.pumpAndSettle();

    expect(find.text('Tuesday, Mar 10'), findsOneWidget);
    expect(find.text('Computer Networks'), findsOneWidget);
    expect(find.text('Lecture'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
