import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/backup/backup_validator.dart';
import 'package:attendly/core/backup/sample_data.dart';

void main() {
  test('SampleData generates valid backup and matches calculated expectations', () {
    final sample = SampleData.getSampleBackupData();
    expect(sample.semesters.length, 1);
    expect(sample.subjects.length, 4);
    expect(sample.attendanceSessions.length, 76);
    expect(sample.dayNotes.length, 3);

    final jsonStr = SampleData.getSampleBackupJson();
    final validation = BackupValidator.validate(jsonStr);
    expect(validation.isValid, isTrue);
    expect(validation.error, isNull);

    // Validate calculations
    final sessions = sample.attendanceSessions;
    // Subject 1: DSA
    final s1Sessions = sessions.where((s) => s.subjectId == 1).toList();
    expect(s1Sessions.length, 24);
    final s1Present = s1Sessions.where((s) => s.status == 'present').length;
    final s1Absent = s1Sessions.where((s) => s.status == 'absent').length;
    expect(s1Present, 21);
    expect(s1Absent, 3);
    // 21 / 24 = 87.5%

    // Subject 2: OS
    final s2Sessions = sessions.where((s) => s.subjectId == 2).toList();
    expect(s2Sessions.length, 20);
    final s2Present = s2Sessions.where((s) => s.status == 'present').length;
    final s2Absent = s2Sessions.where((s) => s.status == 'absent').length;
    expect(s2Present, 12);
    expect(s2Absent, 8);
    // 12 / 20 = 60.0%

    // Subject 3: CN
    final s3Sessions = sessions.where((s) => s.subjectId == 3).toList();
    expect(s3Sessions.length, 16);
    final s3Present = s3Sessions.where((s) => s.status == 'present').length;
    final s3Absent = s3Sessions.where((s) => s.status == 'absent').length;
    expect(s3Present, 12);
    expect(s3Absent, 4);
    // 12 / 16 = 75.0%

    // Subject 4: ML
    final s4Sessions = sessions.where((s) => s.subjectId == 4).toList();
    expect(s4Sessions.length, 16);
    final s4Present = s4Sessions.where((s) => s.status == 'present').length;
    final s4Absent = s4Sessions.where((s) => s.status == 'absent').length;
    expect(s4Present, 15);
    expect(s4Absent, 1);
    // 15 / 16 = 93.75% -> 93.8%

    // Total Overall
    final totalPresent = s1Present + s2Present + s3Present + s4Present;
    final totalAbsent = s1Absent + s2Absent + s3Absent + s4Absent;
    expect(totalPresent, 60);
    expect(totalAbsent, 16);
    expect(totalPresent + totalAbsent, 76);
    final overallPct = (totalPresent / 76) * 100;
    expect(overallPct.toStringAsFixed(1), '78.9');
  });
}
