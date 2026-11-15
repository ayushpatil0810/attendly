class SafeAbsenceResult {
  const SafeAbsenceResult({
    this.safeAbsences,
    required this.isAvailable,
    required this.message,
    this.requiresScenario = false,
  });

  final int? safeAbsences;
  final bool isAvailable;
  final String message;
  final bool requiresScenario;

  const SafeAbsenceResult.notAvailable({
    this.message = 'Safe absences will appear once sessions are logged.',
    this.requiresScenario = false,
  }) : safeAbsences = null,
       isAvailable = false;

  const SafeAbsenceResult.belowThreshold({
    this.message =
        'Currently below target threshold. Recovery required instead.',
  }) : safeAbsences = 0,
       isAvailable = true,
       requiresScenario = false;

  const SafeAbsenceResult.componentAverageScenarioRequired({
    this.message = 'Safe absences depend on whether future classes are Lecture or Lab. Use the simulator for precise scenarios.',
  }) : safeAbsences = null,
       isAvailable = false,
       requiresScenario = true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafeAbsenceResult &&
          runtimeType == other.runtimeType &&
          safeAbsences == other.safeAbsences &&
          isAvailable == other.isAvailable &&
          message == other.message &&
          requiresScenario == other.requiresScenario;

  @override
  int get hashCode =>
      safeAbsences.hashCode ^
      isAvailable.hashCode ^
      message.hashCode ^
      requiresScenario.hashCode;
}
