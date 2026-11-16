import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/services/home_widget_service.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_availability.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/recovery_result.dart';
import 'package:attendly/features/attendance/domain/entities/safe_absence_result.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';

class MockHomeWidgetWrapper implements HomeWidgetWrapper {
  final Map<String, dynamic> savedData = {};
  final List<String> updatedWidgets = [];
  final StreamController<Uri?> clickController =
      StreamController<Uri?>.broadcast();
  Uri? initialUri;

  @override
  Future<bool?> saveWidgetData<T>(String id, T? data) async {
    savedData[id] = data;
    return true;
  }

  @override
  Future<bool?> updateWidget({
    String? name,
    String? androidName,
    String? iOSName,
    String? qualifiedAndroidName,
  }) async {
    if (androidName != null) {
      updatedWidgets.add(androidName);
    }
    return true;
  }

  @override
  Future<Uri?> initiallyLaunchedFromHomeWidget() async {
    return initialUri;
  }

  @override
  Stream<Uri?> get widgetClicked => clickController.stream;
}

void main() {
  late MockHomeWidgetWrapper mockWrapper;
  late HomeWidgetService service;

  setUp(() {
    mockWrapper = MockHomeWidgetWrapper();
    service = HomeWidgetService(wrapper: mockWrapper);
  });

  group('HomeWidgetService', () {
    test('updateWidgets saves empty state when summary is null', () async {
      await service.updateWidgets(null);

      expect(mockWrapper.savedData['semester_name'], 'Attendly');
      expect(mockWrapper.savedData['overall_percentage'], '—');
      expect(mockWrapper.savedData['overall_percentage_int'], 0);
      expect(mockWrapper.savedData['threshold_status'], 'none');
      expect(mockWrapper.savedData['status_label'], 'No Semester');
      expect(mockWrapper.savedData['subject_count'], 0);

      expect(
        mockWrapper.updatedWidgets,
        containsAll([
          'SmallAttendanceWidgetProvider',
          'MediumAttendanceWidgetProvider',
          'LargeAttendanceWidgetProvider',
        ]),
      );
    });

    test(
      'updateWidgets saves accurate statistics for active summary',
      () async {
        final summary = SemesterAttendanceSummary(
          semesterId: 1,
          semesterName: 'Fall 2026',
          threshold: 0.75,
          calculationMethod: AttendanceCalculationMethod.rawCombined,
          totalPresent: 28,
          totalAbsent: 4,
          totalConducted: 32,
          lecturePresent: 20,
          lectureConducted: 22,
          labPresent: 8,
          labConducted: 10,
          overallPercentage: 87.5,
          availability: AttendanceAvailability.available,
          thresholdStatus: ThresholdStatus.meeting,
          targetGoal: 0.85,
          safeAbsenceResult: const SafeAbsenceResult(
            safeAbsences: 5,
            isAvailable: true,
            message: 'Can miss 5 sessions',
          ),
          recoveryResult: const RecoveryResult.notNeeded(),
          goalRecoveryResult: const RecoveryResult.notNeeded(
            message: 'You reached your 85% goal!',
          ),
          subjectSummaries: [
            const SubjectAttendanceSummary(
              subjectId: 101,
              subjectName: 'Data Structures',
              lectureEnabled: true,
              labEnabled: false,
              totalPresent: 14,
              totalAbsent: 2,
              totalConducted: 16,
              percentage: 87.5,
              availability: AttendanceAvailability.available,
              thresholdStatus: ThresholdStatus.meeting,
              safeAbsenceResult: SafeAbsenceResult(
                safeAbsences: 2,
                isAvailable: true,
                message: '',
              ),
              recoveryResult: RecoveryResult.notNeeded(),
              targetGoal: 0.85,
              goalRecoveryResult: RecoveryResult.notNeeded(),
            ),
          ],
          trendPoints: const [],
        );

        await service.updateWidgets(summary);

        expect(mockWrapper.savedData['semester_name'], 'Fall 2026');
        expect(mockWrapper.savedData['overall_percentage'], '87.5%');
        expect(mockWrapper.savedData['overall_percentage_int'], 88);
        expect(mockWrapper.savedData['threshold_percent'], 75);
        expect(mockWrapper.savedData['target_goal_percent'], 85);
        expect(mockWrapper.savedData['threshold_status'], 'meeting');
        expect(mockWrapper.savedData['status_label'], 'Above 75%');
        expect(mockWrapper.savedData['total_present'], 28);
        expect(mockWrapper.savedData['total_absent'], 4);
        expect(mockWrapper.savedData['total_conducted'], 32);
        expect(mockWrapper.savedData['meets_goal'], isTrue);
        expect(mockWrapper.savedData['subject_count'], 1);
        expect(mockWrapper.savedData['subject_1_name'], 'Data Structures');
        expect(mockWrapper.savedData['subject_1_stats'], '14/16');
        expect(mockWrapper.savedData['subject_1_pct'], '87.5%');
        expect(mockWrapper.savedData['subject_1_meeting'], isTrue);

        expect(mockWrapper.updatedWidgets, [
          'SmallAttendanceWidgetProvider',
          'MediumAttendanceWidgetProvider',
          'LargeAttendanceWidgetProvider',
        ]);
      },
    );

    test('listens to widget clicks', () async {
      Uri? capturedUri;
      service.listenToWidgetClicks((uri) {
        capturedUri = uri;
      });

      final testUri = Uri.parse('attendly://quick-log');
      mockWrapper.clickController.add(testUri);

      await pumpEventQueue();
      expect(capturedUri, testUri);
    });
  });
}
