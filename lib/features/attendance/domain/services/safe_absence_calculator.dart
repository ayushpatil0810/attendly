import 'dart:math' as math;

import '../entities/attendance_calculation_method.dart';
import '../entities/safe_absence_result.dart';

class SafeAbsenceCalculator {
  const SafeAbsenceCalculator();

  /// Calculates safe additional absences for Raw Combined or reports that
  /// Component Average requires a scenario.
  SafeAbsenceResult calculate({
    required int present,
    required int conducted,
    required double threshold,
    required AttendanceCalculationMethod calculationMethod,
  }) {
    if (conducted == 0) {
      return const SafeAbsenceResult.notAvailable();
    }

    if (calculationMethod == AttendanceCalculationMethod.componentAverage) {
      return const SafeAbsenceResult.componentAverageScenarioRequired();
    }

    final thresholdPercent = (threshold * 100).round();

    // Check if currently below threshold
    // Use floating point epsilon for boundary precision
    final currentRatio = present / conducted;
    if (currentRatio < threshold - 1e-9) {
      return SafeAbsenceResult.belowThreshold(
        message:
            'Currently below $thresholdPercent% target. Prioritize recovery.',
      );
    }

    // At threshold = 1.0 (100%)
    if (threshold >= 1.0 - 1e-9) {
      return const SafeAbsenceResult(
        safeAbsences: 0,
        isAvailable: true,
        message:
            'At 100% threshold, any absence will drop attendance below 100%.',
        requiresScenario: false,
      );
    }

    // Target threshold <= 0% allows any number of absences
    if (threshold <= 0.0) {
      return const SafeAbsenceResult(
        safeAbsences: 999,
        isAvailable: true,
        message: 'At 0% target threshold, any number of absences is permitted.',
        requiresScenario: false,
      );
    }

    // Formula: max(0, floor(A / t - C))
    final rawX = (present / threshold) - conducted;
    var x = math.max(0, rawX.floor());

    // Boundary check verification:
    // 1. present / (conducted + x) >= threshold
    while (x > 0 && ((present / (conducted + x)) < threshold - 1e-9)) {
      x--;
    }
    // 2. present / (conducted + x + 1) < threshold (maximal x)
    while ((present / (conducted + x + 1)) >= threshold - 1e-9) {
      x++;
    }

    final String message;
    if (x == 0) {
      message =
          'At target threshold. Any additional absence will drop attendance below $thresholdPercent%.';
    } else {
      final unit = x == 1 ? 'class' : 'classes';
      message =
          'You can miss up to $x $unit while staying at or above $thresholdPercent%.';
    }

    return SafeAbsenceResult(
      safeAbsences: x,
      isAvailable: true,
      message: message,
      requiresScenario: false,
    );
  }
}
