class Subject {
  const Subject({
    required this.id,
    required this.semesterId,
    required this.name,
    this.lectureEnabled = true,
    this.labEnabled = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int semesterId;
  final String name;
  final bool lectureEnabled;
  final bool labEnabled;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasBothComponents => lectureEnabled && labEnabled;

  Subject copyWith({
    int? id,
    int? semesterId,
    String? name,
    bool? lectureEnabled,
    bool? labEnabled,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      lectureEnabled: lectureEnabled ?? this.lectureEnabled,
      labEnabled: labEnabled ?? this.labEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          semesterId == other.semesterId &&
          name == other.name &&
          lectureEnabled == other.lectureEnabled &&
          labEnabled == other.labEnabled &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^
      semesterId.hashCode ^
      name.hashCode ^
      lectureEnabled.hashCode ^
      labEnabled.hashCode ^
      sortOrder.hashCode;
}
