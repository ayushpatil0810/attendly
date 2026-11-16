import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';

import '../entities/attendance_milestone.dart';

class MilestoneService {
  MilestoneService(this._prefs);

  final SharedPreferences _prefs;

  static String _key(int semesterId, int percent) =>
      'attendly_milestone_celebrated_${semesterId}_$percent';

  bool isMilestoneCelebrated(int semesterId, AttendanceMilestone milestone) {
    return _prefs.getBool(_key(semesterId, milestone.percentage)) ?? false;
  }

  Future<void> markMilestoneCelebrated(
    int semesterId,
    AttendanceMilestone milestone,
  ) async {
    await _prefs.setBool(_key(semesterId, milestone.percentage), true);
  }

  /// Checks if any milestones have been reached by [currentPercentage]
  /// that have NOT yet been celebrated for this [semesterId].
  List<AttendanceMilestone> getUncelebratedReachedMilestones({
    required int semesterId,
    required double? currentPercentage,
  }) {
    if (currentPercentage == null) return const [];
    final achieved = AttendanceMilestone.achievedFor(currentPercentage);
    return achieved
        .where((m) => !isMilestoneCelebrated(semesterId, m))
        .toList();
  }

  /// Marks a list of milestones as celebrated.
  Future<void> markMilestonesCelebrated(
    int semesterId,
    Iterable<AttendanceMilestone> milestones,
  ) async {
    for (final m in milestones) {
      await markMilestoneCelebrated(semesterId, m);
    }
  }

  /// Resets celebration records for a semester if attendance drops below or resets.
  Future<void> resetCelebratedMilestonesForSemester(int semesterId) async {
    for (final m in AttendanceMilestone.values) {
      await _prefs.remove(_key(semesterId, m.percentage));
    }
  }
}

final milestoneServiceProvider = Provider<MilestoneService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MilestoneService(prefs);
});
