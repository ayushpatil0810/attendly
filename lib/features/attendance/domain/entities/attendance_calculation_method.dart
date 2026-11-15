enum AttendanceCalculationMethod {
  rawCombined(
    'raw_combined',
    'Raw Combined',
    'All lecture and lab sessions carry equal weight.',
  ),
  componentAverage(
    'component_average',
    'Component Average (50/50)',
    'Lecture and Lab percentages are calculated separately and averaged.',
  );

  const AttendanceCalculationMethod(
    this.dbValue,
    this.displayName,
    this.description,
  );

  final String dbValue;
  final String displayName;
  final String description;

  static AttendanceCalculationMethod fromDbValue(String value) {
    switch (value) {
      case 'component_average':
        return AttendanceCalculationMethod.componentAverage;
      case 'raw_combined':
      default:
        return AttendanceCalculationMethod.rawCombined;
    }
  }
}
