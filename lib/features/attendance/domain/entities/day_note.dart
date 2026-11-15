class DayNote {
  const DayNote({
    required this.id,
    required this.semesterId,
    required this.date,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int semesterId;
  final String date; // YYYY-MM-DD
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  DayNote copyWith({
    int? id,
    int? semesterId,
    String? date,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DayNote(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      date: date ?? this.date,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayNote &&
        other.id == id &&
        other.semesterId == semesterId &&
        other.date == date &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        semesterId,
        date,
        content,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'DayNote(id: $id, semesterId: $semesterId, date: $date, content: $content)';
}
