enum SessionComponent {
  lecture('lecture', 'Lecture'),
  lab('lab', 'Lab');

  const SessionComponent(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static SessionComponent fromDbValue(String value) {
    switch (value.toLowerCase()) {
      case 'lab':
        return SessionComponent.lab;
      case 'lecture':
      default:
        return SessionComponent.lecture;
    }
  }
}
