enum AttendanceStatus {
  present('present', 'Present'),
  absent('absent', 'Absent');

  const AttendanceStatus(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static AttendanceStatus fromDbValue(String value) {
    switch (value.toLowerCase()) {
      case 'absent':
        return AttendanceStatus.absent;
      case 'present':
      default:
        return AttendanceStatus.present;
    }
  }
}
