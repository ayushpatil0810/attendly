class RecoveryResult {
  const RecoveryResult({
    this.requiredConsecutivePresents,
    required this.isAvailable,
    this.isImpossible = false,
    required this.message,
    this.requiresScenario = false,
  });

  final int? requiredConsecutivePresents;
  final bool isAvailable;
  final bool isImpossible;
  final String message;
  final bool requiresScenario;

  const RecoveryResult.notAvailable({
    this.message = 'Recovery information appears when attendance is recorded.',
    this.requiresScenario = false,
  }) : requiredConsecutivePresents = null,
       isAvailable = false,
       isImpossible = false;

  const RecoveryResult.notNeeded({
    this.message = 'Attendance is currently at or above target threshold.',
  }) : requiredConsecutivePresents = 0,
       isAvailable = true,
       isImpossible = false,
       requiresScenario = false;

  const RecoveryResult.impossible({
    this.message = '100% threshold cannot be reached through attendance alone because of past absences.',
  }) : requiredConsecutivePresents = null,
       isAvailable = true,
       isImpossible = true,
       requiresScenario = false;

  const RecoveryResult.componentAverageScenarioRequired({
    this.message = 'Recovery depends on future Lecture and Lab distribution. Use the simulator for precise scenarios.',
  }) : requiredConsecutivePresents = null,
       isAvailable = false,
       isImpossible = false,
       requiresScenario = true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecoveryResult &&
          runtimeType == other.runtimeType &&
          requiredConsecutivePresents == other.requiredConsecutivePresents &&
          isAvailable == other.isAvailable &&
          isImpossible == other.isImpossible &&
          message == other.message &&
          requiresScenario == other.requiresScenario;

  @override
  int get hashCode =>
      requiredConsecutivePresents.hashCode ^
      isAvailable.hashCode ^
      isImpossible.hashCode ^
      message.hashCode ^
      requiresScenario.hashCode;
}
