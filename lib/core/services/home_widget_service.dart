import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';

/// Testable wrapper around [HomeWidget] plugin methods
class HomeWidgetWrapper {
  const HomeWidgetWrapper();

  Future<bool?> saveWidgetData<T>(String id, T? data) {
    return HomeWidget.saveWidgetData<T>(id, data);
  }

  Future<bool?> updateWidget({
    String? name,
    String? androidName,
    String? iOSName,
    String? qualifiedAndroidName,
  }) {
    return HomeWidget.updateWidget(
      name: name,
      androidName: androidName,
      iOSName: iOSName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
  }

  Future<Uri?> initiallyLaunchedFromHomeWidget() {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  Stream<Uri?> get widgetClicked => HomeWidget.widgetClicked;
}

class HomeWidgetService {
  HomeWidgetService({HomeWidgetWrapper? wrapper})
    : _wrapper = wrapper ?? const HomeWidgetWrapper();

  final HomeWidgetWrapper _wrapper;

  /// Updates all 3 native home screen widgets (Small, Medium, Large)
  /// with actual attendance data.
  Future<void> updateWidgets(SemesterAttendanceSummary? summary) async {
    try {
      if (summary == null) {
        await _saveEmptyState();
      } else {
        await _saveSummaryData(summary);
      }

      await _wrapper.updateWidget(androidName: 'SmallAttendanceWidgetProvider');
      await _wrapper.updateWidget(
        androidName: 'MediumAttendanceWidgetProvider',
      );
      await _wrapper.updateWidget(androidName: 'LargeAttendanceWidgetProvider');
    } catch (e) {
      debugPrint('HomeWidget update error (non-fatal): $e');
    }
  }

  Future<void> _saveEmptyState() async {
    await _wrapper.saveWidgetData<String>('semester_name', 'Attendly');
    await _wrapper.saveWidgetData<String>('overall_percentage', '—');
    await _wrapper.saveWidgetData<int>('overall_percentage_int', 0);
    await _wrapper.saveWidgetData<int>('threshold_percent', 75);
    await _wrapper.saveWidgetData<int>('target_goal_percent', 85);
    await _wrapper.saveWidgetData<String>('threshold_status', 'none');
    await _wrapper.saveWidgetData<String>('status_label', 'No Semester');
    await _wrapper.saveWidgetData<int>('total_present', 0);
    await _wrapper.saveWidgetData<int>('total_absent', 0);
    await _wrapper.saveWidgetData<int>('total_conducted', 0);
    await _wrapper.saveWidgetData<String>(
      'goal_advice',
      'Create a semester in Attendly to track attendance',
    );
    await _wrapper.saveWidgetData<bool>('meets_goal', false);
    await _wrapper.saveWidgetData<int>('subject_count', 0);
  }

  Future<void> _saveSummaryData(SemesterAttendanceSummary summary) async {
    final statusType = summary.meetsThreshold
        ? 'meeting'
        : summary.isBelowThreshold
        ? 'below'
        : 'none';

    final statusLabel = summary.meetsThreshold
        ? 'Above ${summary.thresholdPercent}%'
        : summary.isBelowThreshold
        ? 'Below ${summary.thresholdPercent}%'
        : 'No Records';

    String goalAdvice;
    if (summary.totalConducted == 0) {
      goalAdvice =
          'Record attendance to track your ${summary.targetGoalPercent}% goal';
    } else if (summary.meetsGoal) {
      goalAdvice =
          'Goal Met! Beating your ${summary.targetGoalPercent}% personal target 🎉';
    } else if (summary.calculationMethod ==
        AttendanceCalculationMethod.componentAverage) {
      goalAdvice = 'Goal recovery requires scenario simulation';
    } else if (summary.goalRecoveryResult.isImpossible) {
      goalAdvice = '100% goal impossible due to past absences';
    } else if (summary.goalRecoveryResult.requiredConsecutivePresents != null) {
      final n = summary.goalRecoveryResult.requiredConsecutivePresents!;
      final unit = n == 1 ? 'class' : 'classes';
      goalAdvice =
          'Attend next $n $unit with no absences for ${summary.targetGoalPercent}% goal';
    } else {
      goalAdvice = 'Personal attendance goal: ${summary.targetGoalPercent}%';
    }

    await _wrapper.saveWidgetData<String>(
      'semester_name',
      summary.semesterName,
    );
    await _wrapper.saveWidgetData<String>(
      'overall_percentage',
      summary.formattedPercentage,
    );
    await _wrapper.saveWidgetData<int>(
      'overall_percentage_int',
      summary.roundedPercentage ?? 0,
    );
    await _wrapper.saveWidgetData<int>(
      'threshold_percent',
      summary.thresholdPercent,
    );
    await _wrapper.saveWidgetData<int>(
      'target_goal_percent',
      summary.targetGoalPercent,
    );
    await _wrapper.saveWidgetData<String>('threshold_status', statusType);
    await _wrapper.saveWidgetData<String>('status_label', statusLabel);
    await _wrapper.saveWidgetData<int>('total_present', summary.totalPresent);
    await _wrapper.saveWidgetData<int>('total_absent', summary.totalAbsent);
    await _wrapper.saveWidgetData<int>(
      'total_conducted',
      summary.totalConducted,
    );
    await _wrapper.saveWidgetData<String>('goal_advice', goalAdvice);
    await _wrapper.saveWidgetData<bool>('meets_goal', summary.meetsGoal);

    // Save up to top 4 subjects
    final count = math.min(4, summary.subjectSummaries.length);
    await _wrapper.saveWidgetData<int>('subject_count', count);

    for (var i = 0; i < count; i++) {
      final subj = summary.subjectSummaries[i];
      final num = i + 1;
      await _wrapper.saveWidgetData<String>(
        'subject_${num}_name',
        subj.subjectName,
      );
      await _wrapper.saveWidgetData<String>(
        'subject_${num}_stats',
        '${subj.totalPresent}/${subj.totalConducted}',
      );
      await _wrapper.saveWidgetData<String>(
        'subject_${num}_pct',
        subj.formattedPercentage,
      );
      await _wrapper.saveWidgetData<bool>(
        'subject_${num}_meeting',
        subj.meetsThreshold,
      );
    }
  }

  /// Listens to clicks on widgets and deep links
  StreamSubscription<Uri?> listenToWidgetClicks(void Function(Uri? uri) onUri) {
    return _wrapper.widgetClicked.listen(onUri);
  }

  /// Checks if the app was initially launched by tapping a widget
  Future<Uri?> checkInitialLaunchUri() {
    return _wrapper.initiallyLaunchedFromHomeWidget();
  }
}

final homeWidgetWrapperProvider = Provider<HomeWidgetWrapper>((ref) {
  return const HomeWidgetWrapper();
});

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  final wrapper = ref.watch(homeWidgetWrapperProvider);
  return HomeWidgetService(wrapper: wrapper);
});
