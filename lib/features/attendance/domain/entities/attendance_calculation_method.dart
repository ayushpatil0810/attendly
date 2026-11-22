enum AttendanceCalculationMethod {
  rawCombined(
    'raw_combined',
    'Equal weight',
    'Every lecture and lab counts the same.',
  ),
  componentAverage(
    'component_average',
    '50/50 Lecture & Lab',
    'Lecture and lab each count for 50%.',
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
