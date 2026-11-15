import 'dart:math' as math;

import '../entities/attendance_calculation_method.dart';
import '../entities/recovery_result.dart';

class RecoveryCalculator {
  const RecoveryCalculator();

  /// Calculates consecutive Present sessions needed to recover to threshold
  /// for Raw Combined, or reports that Component Average requires a scenario.
  RecoveryResult calculate({
    required int present,
    required int conducted,
    required double threshold,
    required AttendanceCalculationMethod calculationMethod,
  }) {
    if (conducted == 0) {
      return const RecoveryResult.notAvailable();
    }

    if (calculationMethod == AttendanceCalculationMethod.componentAverage) {
      return const RecoveryResult.componentAverageScenarioRequired();
    }

    final thresholdPercent = (threshold * 100).round();

    // Check if already at or above threshold
    final currentRatio = present / conducted;
    if (currentRatio >= threshold - 1e-9) {
      return const RecoveryResult.notNeeded();
    }

    // At 100% threshold, if any absence occurred, recovery is impossible
    if (threshold >= 1.0 - 1e-9) {
      return const RecoveryResult.impossible();
    }

    // Formula: ceil((t * C - A) / (1 - t))
    final rawX = ((threshold * conducted) - present) / (1.0 - threshold);
    var x = math.max(1, rawX.ceil());

    // Boundary check verification:
    // 1. (present + x) / (conducted + x) >= threshold
    while (((present + x) / (conducted + x)) < threshold - 1e-9) {
      x++;
    }
    // 2. If x > 1, (present + x - 1) / (conducted + x - 1) < threshold (minimal x)
    while (x > 1 &&
        (((present + x - 1) / (conducted + x - 1)) >= threshold - 1e-9)) {
      x--;
    }

    final unit = x == 1 ? 'class' : 'classes';
    final message =
        'Attend the next $x consecutive $unit with no absences to reach $thresholdPercent%.';

    return RecoveryResult(
      requiredConsecutivePresents: x,
      isAvailable: true,
      isImpossible: false,
      message: message,
      requiresScenario: false,
    );
  }
}
