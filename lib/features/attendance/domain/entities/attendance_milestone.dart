enum AttendanceMilestone {
  seventyFive(
    percentage: 75,
    title: 'Solid Baseline',
    badgeName: '75%',
    description: 'Safe above the standard university threshold.',
    celebrationMessage: 'You crossed 75% attendance! Steady and on track.',
  ),
  eighty(
    percentage: 80,
    title: 'Silver Pacer',
    badgeName: '80%',
    description: 'Building strong momentum across your subjects.',
    celebrationMessage: '80% attendance achieved! Great consistency.',
  ),
  eightyFive(
    percentage: 85,
    title: 'Gold Achiever',
    badgeName: '85%',
    description: 'Comfortably surpassing typical academic requirements.',
    celebrationMessage: '85% attendance milestone! Outstanding commitment.',
  ),
  ninety(
    percentage: 90,
    title: 'Platinum Scholar',
    badgeName: '90%',
    description: 'Elite attendance consistency and dedication.',
    celebrationMessage: '90% attendance unlocked! Exceptional discipline.',
  ),
  ninetyFive(
    percentage: 95,
    title: 'Diamond Vanguard',
    badgeName: '95%',
    description: 'Remarkable dedication with virtually zero missed sessions.',
    celebrationMessage:
        '95% attendance! You are leading with near-perfect attendance.',
  ),
  hundred(
    percentage: 100,
    title: 'Century Legend',
    badgeName: '100%',
    description: 'Flawless attendance record with zero absences.',
    celebrationMessage: '100% Perfect Attendance! Flawless dedication.',
  );

  const AttendanceMilestone({
    required this.percentage,
    required this.title,
    required this.badgeName,
    required this.description,
    required this.celebrationMessage,
  });

  final int percentage;
  final String title;
  final String badgeName;
  final String description;
  final String celebrationMessage;

  /// Returns all milestones achieved for a given overall percentage (0.0 to 100.0).
  static List<AttendanceMilestone> achievedFor(double? currentPercentage) {
    if (currentPercentage == null) return const [];
    return AttendanceMilestone.values
        .where((m) => currentPercentage >= (m.percentage - 1e-9))
        .toList();
  }

  /// Returns the next upcoming milestone to conquer.
  static AttendanceMilestone? nextMilestoneFor(double? currentPercentage) {
    if (currentPercentage == null) return AttendanceMilestone.seventyFive;
    for (final m in AttendanceMilestone.values) {
      if (currentPercentage < (m.percentage - 1e-9)) {
        return m;
      }
    }
    return null; // Already at 100%
  }
}
