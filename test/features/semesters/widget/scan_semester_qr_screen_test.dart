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
import 'package:attendly/features/semesters/presentation/screens/scan_semester_qr_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  late SemesterRepositoryImpl semRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    semRepo = SemesterRepositoryImpl(db);
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
      child: const MaterialApp(
        home: ScanSemesterQrScreen(disableCameraForTesting: true),
      ),
    );
  }

  const samplePayload = SemesterQrPayload(
    semesterName: 'Fall 2026',
    attendanceThreshold: 0.85,
    calculationMethod: AttendanceCalculationMethod.componentAverage,
    subjects: [
      SubjectQrPayload(name: 'Embedded Systems', lectureEnabled: true, labEnabled: true),
    ],
  );

  group('ScanSemesterQrScreen Widget Tests', () {
    testWidgets('renders top bar, reticle, and paste code fallback button', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Scan Semester QR'), findsOneWidget);
      expect(find.text('Point camera at an Attendly Semester QR code'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Paste Code Manually'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('pasting valid QR payload opens import preview sheet and completes import', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap "Paste Code Manually"
      final pasteBtn = find.widgetWithText(AppButton, 'Paste Code Manually');
      await tester.tap(pasteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Paste Semester Code'), findsOneWidget);

      // Enter valid QR JSON
      final inputField = find.byType(AppTextField);
      await tester.enterText(inputField, samplePayload.toEncodedString());
      await tester.pumpAndSettle();

      // Tap Review
      await tester.tap(find.widgetWithText(AppButton, 'Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Import preview sheet opens!
      expect(find.text('Import Semester'), findsNWidgets(2));
      expect(find.text('Embedded Systems'), findsOneWidget);
      expect(find.text('85% Attendance Goal'), findsOneWidget);

      // Tap Import Semester
      final importBtn = find.widgetWithText(AppButton, 'Import Semester');
      await tester.tap(importBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 4)); // Toast dismissal

      // Semester is saved in SQLite
      final semesters = await semRepo.getSemesters();
      expect(semesters.length, equals(1));
      expect(semesters.first.name, equals('Fall 2026'));
      expect(semesters.first.attendanceThreshold, equals(0.85));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('pasting invalid payload does not open import sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Paste Code Manually'));
      await tester.pumpAndSettle();

      final inputField = find.byType(AppTextField);
      await tester.enterText(inputField, '{"app":"unknown_app"}');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Review'));
      await tester.pumpAndSettle();

      // Import sheet did NOT open
      expect(find.text('Embedded Systems'), findsNothing);
      final semesters = await semRepo.getSemesters();
      expect(semesters.isEmpty, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}
