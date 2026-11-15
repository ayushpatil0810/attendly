enum InsightObservationType { positive, warning, info, neutral }

/// A short, factual observation derived strictly from recorded attendance data.
class InsightObservation {
  const InsightObservation({
    required this.title,
    required this.message,
    required this.type,
    this.badgeText,
  });

  final String title;
  final String message;
  final InsightObservationType type;
  final String? badgeText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightObservation &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          message == other.message &&
          type == other.type &&
          badgeText == other.badgeText;

  @override
  int get hashCode => Object.hash(title, message, type, badgeText);
}
