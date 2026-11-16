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

  /// Calculates consecutive Present sessions needed to reach the student's
  /// personal attendance goal, or reports unavailable / scenario required.
  RecoveryResult calculateGoalRecovery({
    required int present,
    required int conducted,
    required double goal,
    required AttendanceCalculationMethod calculationMethod,
  }) {
    if (conducted == 0) {
      return const RecoveryResult.notAvailable(
        message:
            'Goal recovery information appears when attendance is recorded.',
      );
    }

    if (calculationMethod == AttendanceCalculationMethod.componentAverage) {
      return const RecoveryResult.componentAverageScenarioRequired(
        message: 'Goal recovery depends on future Lecture and Lab distribution. Use the simulator for precise scenarios.',
      );
    }

    final goalPercent = (goal * 100).round();

    // Check if already at or above personal goal
    final currentRatio = present / conducted;
    if (currentRatio >= goal - 1e-9) {
      return RecoveryResult.notNeeded(
        message: 'You have reached your personal goal of $goalPercent%!',
      );
    }

    // At 100% goal, if any absence occurred, recovery is impossible
    if (goal >= 1.0 - 1e-9) {
      return const RecoveryResult.impossible(
        message: '100% personal goal cannot be reached through attendance alone because of past absences.',
      );
    }

    // Formula: ceil((g * C - A) / (1 - g))
    final rawX = ((goal * conducted) - present) / (1.0 - goal);
    var x = math.max(1, rawX.ceil());

    while (((present + x) / (conducted + x)) < goal - 1e-9) {
      x++;
    }
    while (x > 1 &&
        (((present + x - 1) / (conducted + x - 1)) >= goal - 1e-9)) {
      x--;
    }

    final unit = x == 1 ? 'class' : 'classes';
    final message =
        'Attend the next $x consecutive $unit with no absences to reach your $goalPercent% goal.';

    return RecoveryResult(
      requiredConsecutivePresents: x,
      isAvailable: true,
      isImpossible: false,
      message: message,
      requiresScenario: false,
    );
  }
}
