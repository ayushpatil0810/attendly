import 'dart:math' as math;

class ActionableClassCount {
  const ActionableClassCount({
    required this.count,
    required this.isAboveOrAtTarget,
    required this.headlineText,
    required this.subjectSubtext,
  });

  /// The number of classes that can be missed or must be attended.
  final int count;

  /// True if currently at or above target threshold, false if below.
  final bool isAboveOrAtTarget;

  /// Headline actionable insight text (e.g. "Can miss 2 classes" or "Attend next 5 classes").
  final String headlineText;

  /// Detailed subtext for subject rows (e.g. "Attend next 5 classes to reach 74%").
  final String subjectSubtext;
}

abstract final class AttendanceActionHelper {
  /// Computes actionable "Can Miss" / "Must Attend" consecutive class counts.
  ///
  /// - If [conducted] is 0, returns null.
  /// - If above or at [threshold]: computes consecutive classes that can be missed
  ///   while remaining at or above [threshold] (e.g. "Can miss 2 classes").
  /// - If below [threshold]: computes consecutive classes that must be attended
  ///   consecutively with no absences to reach [threshold] (e.g. "Attend next 5 classes").
  static ActionableClassCount? calculateActionableInsight({
    required int present,
    required int conducted,
    required double threshold,
  }) {
    if (conducted == 0) return null;

    final thresholdPercent = (threshold * 100).round();
    final currentRatio = present / conducted;

    if (currentRatio >= threshold - 1e-9) {
      // At or above target
      int safe;
      if (threshold >= 1.0 - 1e-9) {
        safe = 0;
      } else {
        final rawX = (present / threshold) - conducted;
        var x = math.max(0, rawX.floor());
        while (x > 0 && ((present / (conducted + x)) < threshold - 1e-9)) {
          x--;
        }
        while ((present / (conducted + x + 1)) >= threshold - 1e-9) {
          x++;
        }
        safe = x;
      }

      final unit = safe == 1 ? 'class' : 'classes';
      final headline = 'Can miss $safe $unit';
      final subtext = safe > 0
          ? 'Can miss $safe $unit while staying at $thresholdPercent%'
          : 'Can miss 0 classes (on track at $thresholdPercent%)';

      return ActionableClassCount(
        count: safe,
        isAboveOrAtTarget: true,
        headlineText: headline,
        subjectSubtext: subtext,
      );
    } else {
      // Below target -> Recovery required
      if (threshold >= 1.0 - 1e-9) {
        return const ActionableClassCount(
          count: 0,
          isAboveOrAtTarget: false,
          headlineText: 'Cannot reach 100%',
          subjectSubtext: 'Cannot reach 100% target',
        );
      }

      final rawX = ((threshold * conducted) - present) / (1.0 - threshold);
      var x = math.max(1, rawX.ceil());
      while (((present + x) / (conducted + x)) < threshold - 1e-9) {
        x++;
      }
      while (x > 1 &&
          (((present + x - 1) / (conducted + x - 1)) >= threshold - 1e-9)) {
        x--;
      }

      final unit = x == 1 ? 'class' : 'classes';
      final headline = 'Attend next $x $unit';
      final subtext = 'Attend next $x $unit to reach $thresholdPercent%';

      return ActionableClassCount(
        count: x,
        isAboveOrAtTarget: false,
        headlineText: headline,
        subjectSubtext: subtext,
      );
    }
  }
}
