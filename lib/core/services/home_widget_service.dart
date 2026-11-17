import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
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

  /// Synchronizes theme preferences with native home screen widgets
  Future<void> updateThemeColors({
    required String themeId,
    required bool isDark,
    required int primaryColor,
    required int backgroundColor,
  }) async {
    try {
      await _wrapper.saveWidgetData<String>('theme_id', themeId);
      await _wrapper.saveWidgetData<bool>('theme_is_dark', isDark);
      await _wrapper.saveWidgetData<int>('theme_primary_color', primaryColor);
      await _wrapper.saveWidgetData<int>(
        'theme_background_color',
        backgroundColor,
      );
      await _wrapper.updateWidget(androidName: 'SmallAttendanceWidgetProvider');
      await _wrapper.updateWidget(
        androidName: 'MediumAttendanceWidgetProvider',
      );
      await _wrapper.updateWidget(androidName: 'LargeAttendanceWidgetProvider');
    } catch (e) {
      debugPrint('HomeWidget theme update error (non-fatal): $e');
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
    await _wrapper.saveWidgetData<String>('threshold_badge', 'Req: 75%');
    await _wrapper.saveWidgetData<String>(
      'attendance_advice',
      'Create a semester in Attendly to track attendance',
    );
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

    String attendanceAdvice;
    if (summary.totalConducted == 0) {
      attendanceAdvice =
          'Record attendance to monitor your ${summary.thresholdPercent}% threshold';
    } else if (summary.meetsThreshold) {
      if (summary.safeAbsenceResult.safeAbsences != null &&
          summary.safeAbsenceResult.safeAbsences! > 0) {
        final n = summary.safeAbsenceResult.safeAbsences!;
        final unit = n == 1 ? 'class' : 'classes';
        attendanceAdvice = 'You can safely miss $n $unit';
      } else {
        attendanceAdvice =
            'On track with ${summary.thresholdPercent}% requirement';
      }
    } else if (summary.recoveryResult.requiredConsecutivePresents != null) {
      final n = summary.recoveryResult.requiredConsecutivePresents!;
      final unit = n == 1 ? 'class' : 'classes';
      attendanceAdvice = 'Attend next $n $unit to get back on track';
    } else {
      attendanceAdvice = 'Requirement: ${summary.thresholdPercent}%';
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
    await _wrapper.saveWidgetData<String>(
      'threshold_badge',
      'Req: ${summary.thresholdPercent}%',
    );
    await _wrapper.saveWidgetData<int>('total_present', summary.totalPresent);
    await _wrapper.saveWidgetData<int>('total_absent', summary.totalAbsent);
    await _wrapper.saveWidgetData<int>(
      'total_conducted',
      summary.totalConducted,
    );
    await _wrapper.saveWidgetData<String>(
      'attendance_advice',
      attendanceAdvice,
    );
    await _wrapper.saveWidgetData<String>('goal_advice', attendanceAdvice);
    await _wrapper.saveWidgetData<bool>('meets_goal', summary.meetsThreshold);

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
      await _wrapper.saveWidgetData<int>(
        'subject_${num}_pct_int',
        subj.roundedPercentage ?? 0,
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
