enum AttendanceAvailability {
  available,
  provisional,
  notAvailable;

  bool get isAvailable => this == AttendanceAvailability.available;
  bool get isProvisional => this == AttendanceAvailability.provisional;
  bool get isNotAvailable => this == AttendanceAvailability.notAvailable;
}
