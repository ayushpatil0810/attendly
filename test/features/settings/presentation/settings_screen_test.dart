import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/backup/backup_format.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/services/platform_file_service.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';
import 'package:attendly/features/settings/presentation/screens/settings_screen.dart';
import 'package:attendly/features/subjects/data/repositories/subject_repository_impl.dart';

class MockPlatformFileService implements PlatformFileService {
  String? jsonToReturn;
  bool returnErrorOnPick = false;
  ExportFileResult exportResultToReturn = const ExportFileResult(
    isSuccess: true,
    filePath: '/mock/path/attendly_backup.json',
  );
  String? lastExportedJson;
  String? lastExportedFileName;

  @override
  Future<String?> pickBackupJsonFile() async {
    if (returnErrorOnPick) throw Exception('Simulated pick failure');
    return jsonToReturn;
  }

  @override
  Future<ExportFileResult> exportBackupFile({
    required String fileName,
    required String jsonContent,
  }) async {
    lastExportedFileName = fileName;
    lastExportedJson = jsonContent;
    return exportResultToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  late MockPlatformFileService mockFileService;
  late SemesterRepositoryImpl semesterRepo;
  late SubjectRepositoryImpl subjectRepo;
  late int activeSemId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'pref_haptic_feedback_enabled_v1': true,
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockFileService = MockPlatformFileService();

    semesterRepo = SemesterRepositoryImpl(db);
    subjectRepo = SubjectRepositoryImpl(db);

    // Seed 1 active semester and 1 subject
    activeSemId = await semesterRepo.createSemester(
      name: 'Semester 5',
      attendanceThreshold: 0.75,
      calculationMethod: AttendanceCalculationMethod.rawCombined,
    );
    await subjectRepo.createSubject(
      semesterId: activeSemId,
      name: 'Cloud Computing',
      lectureEnabled: true,
      labEnabled: true,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        platformFileServiceProvider.overrideWithValue(mockFileService),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  void setLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all 4 sections and initial semester details', (
      tester,
    ) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Semester Settings'), findsOneWidget);
      expect(find.text('App Preferences'), findsOneWidget);
      expect(find.text('Local Backup & Restore'), findsOneWidget);
      expect(find.text('Privacy & Offline Guarantee'), findsOneWidget);

      // Semester details
      expect(find.text('Semester 5'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Equal weight'), findsOneWidget);
      expect(find.text('Split in half'), findsOneWidget);

      // Buttons
      expect(find.text('Export Backup'), findsOneWidget);
      expect(find.text('Restore Backup'), findsOneWidget);
      expect(find.text('Haptic Feedback'), findsOneWidget);
      expect(find.byTooltip('Share Semester via QR'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('toggling Haptic Feedback updates preference state', (
      tester,
    ) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(prefs.getBool('pref_haptic_feedback_enabled_v1'), isTrue);

      // Tap the Haptic Feedback tile
      await tester.tap(find.text('Haptic Feedback'));
      await tester.pumpAndSettle();

      expect(prefs.getBool('pref_haptic_feedback_enabled_v1'), isFalse);

      // Tap again to toggle back on
      await tester.tap(find.text('Haptic Feedback'));
      await tester.pumpAndSettle();

      expect(prefs.getBool('pref_haptic_feedback_enabled_v1'), isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('changing calculation method updates the semester', (
      tester,
    ) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Split in half'));
      await tester.pumpAndSettle();

      final updatedSem = await semesterRepo.getSemesterById(activeSemId);
      expect(
        updatedSem!.calculationMethod,
        AttendanceCalculationMethod.componentAverage,
      );

      await tester.tap(find.text('Equal weight'));
      await tester.pumpAndSettle();

      final revertedSem = await semesterRepo.getSemesterById(activeSemId);
      expect(
        revertedSem!.calculationMethod,
        AttendanceCalculationMethod.rawCombined,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('export backup flow triggers file service and shows success', (
      tester,
    ) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Export Backup
      await tester.tap(find.text('Export Backup'));
      await tester.pumpAndSettle();

      expect(mockFileService.lastExportedJson, isNotNull);
      expect(
        mockFileService.lastExportedFileName,
        startsWith('attendly_backup_'),
      );
      expect(find.text('Backup exported successfully!'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('restore with invalid file shows error dialog', (tester) async {
      setLargeViewport(tester);
      mockFileService.jsonToReturn = '{"invalid": "format"}';

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Restore Backup
      await tester.tap(find.text('Restore Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Backup File'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Backup File'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets(
      'restore with valid file displays summary dialog and cancels safely',
      (tester) async {
        setLargeViewport(tester);
        final validJson = jsonEncode({
          'format': BackupConstants.formatIdentifier,
          'formatVersion': 1,
          'exportedAt': '2026-11-15T10:00:00.000Z',
          'data': {
            'semesters': [
              {
                'id': 99,
                'name': 'Backup Semester 8',
                'attendanceThreshold': 0.85,
                'calculationMethod': 'raw_combined',
                'isArchived': false,
                'createdAt': 1700000000000,
                'updatedAt': 1700000000000,
              },
            ],
            'subjects': [
              {
                'id': 9901,
                'semesterId': 99,
                'name': 'Robotics',
                'lectureEnabled': true,
                'labEnabled': false,
                'sortOrder': 0,
                'createdAt': 1700000000000,
                'updatedAt': 1700000000000,
              },
            ],
            'attendanceSessions': [
              {
                'id': 99001,
                'subjectId': 9901,
                'sessionDate': '2026-03-01',
                'component': 'lecture',
                'status': 'present',
                'createdAt': 1700000000000,
                'updatedAt': 1700000000000,
              },
            ],
          },
        });
        mockFileService.jsonToReturn = validJson;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Tap Restore Backup
        await tester.tap(find.text('Restore Backup'));
        await tester.pumpAndSettle();

        // Verify Summary Dialog appears
        expect(find.text('Restore Backup'), findsWidgets);
        expect(find.text('Review backup summary'), findsOneWidget);
        expect(find.textContaining('Backup Semester 8'), findsOneWidget);
        expect(find.text('Robotics'), findsNothing); // subject count is shown
        expect(find.textContaining('1 (1 Present, 0 Absent)'), findsOneWidget);
        expect(
          find.textContaining(
            'Restoring this backup will replace all current semesters',
          ),
          findsOneWidget,
        );

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Ensure original data still intact
        final currentSems = await semesterRepo.getSemesters();
        expect(currentSems.first.name, 'Semester 5');

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'confirming Restore & Replace updates database and refreshes screen',
      (tester) async {
        setLargeViewport(tester);
        final validJson = jsonEncode({
          'format': BackupConstants.formatIdentifier,
          'formatVersion': 1,
          'exportedAt': '2026-11-15T10:00:00.000Z',
          'data': {
            'semesters': [
              {
                'id': 88,
                'name': 'Restored Semester 1',
                'attendanceThreshold': 0.80,
                'calculationMethod': 'component_average',
                'isArchived': false,
                'createdAt': 1700000000000,
                'updatedAt': 1700000000000,
              },
            ],
            'subjects': [],
            'attendanceSessions': [],
          },
        });
        mockFileService.jsonToReturn = validJson;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Tap Restore Backup
        await tester.tap(find.text('Restore Backup'));
        await tester.pumpAndSettle();

        // Tap Restore & Replace
        await tester.tap(find.text('Restore & Replace'));
        await tester.pumpAndSettle();

        expect(
          find.text('Attendance data restored successfully!'),
          findsOneWidget,
        );

        // Verify new semester is now active
        final sems = await semesterRepo.getSemesters();
        expect(sems.length, 1);
        expect(sems.first.name, 'Restored Semester 1');
        expect(sems.first.attendanceThreshold, 0.80);
        expect(
          sems.first.calculationMethod,
          AttendanceCalculationMethod.componentAverage,
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );

    testWidgets(
      'Privacy section displays all offline guarantees and data ownership notices',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Scroll to privacy section
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();

        expect(find.text('100% Offline & Local Storage'), findsOneWidget);
        expect(find.text('No Account Required'), findsOneWidget);
        expect(find.text('No Cloud Synchronization'), findsOneWidget);
        expect(find.text('Student-Managed Backups'), findsOneWidget);
        expect(find.text('Data Safety Reminder'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });
}
