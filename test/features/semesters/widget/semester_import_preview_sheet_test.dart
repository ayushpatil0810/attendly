import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_text_field.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/semesters/domain/entities/semester_qr_payload.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_import_preview_sheet.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  late SemesterRepositoryImpl semRepo;
  late SubjectRepositoryImpl subjRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    semRepo = SemesterRepositoryImpl(db);
    subjRepo = SubjectRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidgetUnderTest(SemesterQrPayload payload) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SemesterImportPreviewSheet(payload: payload),
        ),
      ),
    );
  }

  const samplePayload = SemesterQrPayload(
    semesterName: 'Fall 2026',
    attendanceThreshold: 0.80,
    calculationMethod: AttendanceCalculationMethod.componentAverage,
    subjects: [
      SubjectQrPayload(name: 'Database Management Systems', lectureEnabled: true, labEnabled: true),
      SubjectQrPayload(name: 'Artificial Intelligence', lectureEnabled: true, labEnabled: false),
    ],
  );

  group('SemesterImportPreviewSheet Widget Tests', () {
    testWidgets('renders curriculum preview with courses and badges', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest(samplePayload));
      await tester.pumpAndSettle();

      expect(find.text('Import Semester'), findsNWidgets(2)); // Title and button
      expect(find.text('80% Attendance Goal'), findsOneWidget);
      expect(find.text('2 Subjects'), findsOneWidget);
      expect(find.text('Split in half'), findsOneWidget);

      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('Theory'), findsNWidgets(2));
      expect(find.text('Lab'), findsOneWidget);
      expect(find.text('Artificial Intelligence'), findsOneWidget);

      expect(find.widgetWithText(AppButton, 'Import Semester'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Cancel'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('imports new semester into database and closes sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest(samplePayload));
      await tester.pumpAndSettle();

      final importBtn = find.widgetWithText(AppButton, 'Import Semester');
      await tester.tap(importBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final semesters = await semRepo.getSemesters();
      expect(semesters.length, equals(1));
      expect(semesters.first.name, equals('Fall 2026'));
      expect(semesters.first.attendanceThreshold, equals(0.80));

      final subjects = await subjRepo.getSubjectsForSemester(semesters.first.id);
      expect(subjects.length, equals(2));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('detects duplicate name collision and imports with (Imported) suffix', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pre-create existing semester
      await semRepo.createSemester(name: 'Fall 2026');

      await tester.pumpWidget(createWidgetUnderTest(samplePayload));
      await tester.pumpAndSettle();

      // Conflict warning card appears
      expect(find.text('Semester "Fall 2026" already exists'), findsOneWidget);
      expect(
        find.text('Import as a new copy ("Fall 2026 (Imported)")'),
        findsOneWidget,
      );

      final importBtn = find.widgetWithText(AppButton, 'Import Semester');
      await tester.tap(importBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final semesters = await semRepo.getSemesters();
      expect(semesters.length, equals(2));
      expect(semesters.any((s) => s.name == 'Fall 2026 (Imported)'), isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('allows editing semester name before import', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest(samplePayload));
      await tester.pumpAndSettle();

      final nameField = find.byType(AppTextField);
      await tester.enterText(nameField, 'Custom Term 2026');
      await tester.pumpAndSettle();

      final importBtn = find.widgetWithText(AppButton, 'Import Semester');
      await tester.tap(importBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final semesters = await semRepo.getSemesters();
      expect(semesters.length, equals(1));
      expect(semesters.first.name, equals('Custom Term 2026'));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}
