import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/semesters/presentation/widgets/share_semester_qr_sheet.dart';
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

  Widget createWidgetUnderTest(Semester semester) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(body: ShareSemesterQrSheet(semester: semester)),
      ),
    );
  }

  group('ShareSemesterQrSheet Widget Tests', () {
    testWidgets(
      'renders QR code, semester title, and metadata when subjects exist',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final semId = await semRepo.createSemester(
          name: 'Spring 2026',
          attendanceThreshold: 0.75,
          calculationMethod: AttendanceCalculationMethod.rawCombined,
        );
        final sem = (await semRepo.getSemesterById(semId))!;

        await subjRepo.createSubject(
          semesterId: semId,
          name: 'Operating Systems',
          lectureEnabled: true,
          labEnabled: true,
        );
        await subjRepo.createSubject(
          semesterId: semId,
          name: 'Computer Networks',
          lectureEnabled: true,
          labEnabled: false,
        );

        await tester.pumpWidget(createWidgetUnderTest(sem));
        await tester.pumpAndSettle();

        expect(find.text('Share Semester'), findsOneWidget);
        expect(find.text('Spring 2026'), findsOneWidget);
        expect(find.text('75% Goal'), findsOneWidget);
        expect(find.text('2 courses'), findsOneWidget);
        expect(find.text('Equal weight'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(
          find.text('Scan with Attendly on another phone'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Shares courses and targets only · Attendance records stay private',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label ==
                    'QR Code for semester Spring 2026 with 2 courses',
          ),
          findsOneWidget,
        );
        // Verify QR container has single elevation: border present, no box shadows
        final qrContainerFinder = find
            .ancestor(
              of: find.byType(QrImageView),
              matching: find.byType(Container),
            )
            .first;
        final qrContainer = tester.widget<Container>(qrContainerFinder);
        final boxDecoration = qrContainer.decoration as BoxDecoration?;
        expect(boxDecoration?.border, isNotNull);
        expect(boxDecoration?.boxShadow, isNull);

        // Verify close button tap target is at least 48x48
        final closeButtonFinder = find.byType(AppCloseButton);
        expect(
          tester.getSize(closeButtonFinder).width,
          greaterThanOrEqualTo(48.0),
        );
        expect(
          tester.getSize(closeButtonFinder).height,
          greaterThanOrEqualTo(48.0),
        );

        expect(find.text('Copy Code Data'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets('displays warning and hides QR when semester has 0 subjects', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final semId = await semRepo.createSemester(
        name: 'Empty Semester',
        attendanceThreshold: 0.80,
      );
      final sem = (await semRepo.getSemesterById(semId))!;

      await tester.pumpWidget(createWidgetUnderTest(sem));
      await tester.pumpAndSettle();

      expect(find.text('No courses in this semester'), findsOneWidget);
      expect(
        find.text(
          'Add at least one subject to this semester before sharing it with classmates.',
        ),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsNothing);
      expect(find.widgetWithText(AppButton, 'Close'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('tapping Copy Code Data copies payload to clipboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? capturedClipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            capturedClipboardText =
                (methodCall.arguments as Map)['text'] as String?;
            return null;
          } else if (methodCall.method == 'Clipboard.getData') {
            return {'text': capturedClipboardText};
          }
          return null;
        },
      );

      final semId = await semRepo.createSemester(name: 'Fall 2026');
      final sem = (await semRepo.getSemesterById(semId))!;

      await subjRepo.createSubject(semesterId: semId, name: 'Compiler Design');

      await tester.pumpWidget(createWidgetUnderTest(sem));
      await tester.pumpAndSettle();

      final copyBtn = find.widgetWithText(AppButton, 'Copy Code Data');
      expect(copyBtn, findsOneWidget);

      await tester.tap(copyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedClipboardText, isNotNull);
      expect(capturedClipboardText, contains('"app":"attendly"'));
      expect(capturedClipboardText, contains('Compiler Design'));

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}
