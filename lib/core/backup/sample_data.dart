import 'dart:convert';
import 'backup_format.dart';

class SampleData {
  static const int semesterId = 1;

  static BackupData getSampleBackupData() {
    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;

    final semester = SemesterBackupModel(
      id: semesterId,
      name: 'Fall 2026',
      startDate: '2026-09-01',
      endDate: '2026-12-15',
      attendanceThreshold: 0.75,
      targetGoal: 0.80,
      calculationMethod: 'raw_combined',
      isArchived: false,
      createdAt: nowMs - 20000000,
      updatedAt: nowMs,
    );

    final subjects = [
      SubjectBackupModel(
        id: 1,
        semesterId: semesterId,
        name: 'Data Structures & Algorithms',
        lectureEnabled: true,
        labEnabled: true,
        sortOrder: 0,
        createdAt: nowMs - 19000000,
        updatedAt: nowMs,
      ),
      SubjectBackupModel(
        id: 2,
        semesterId: semesterId,
        name: 'Operating Systems',
        lectureEnabled: true,
        labEnabled: true,
        sortOrder: 1,
        createdAt: nowMs - 18000000,
        updatedAt: nowMs,
      ),
      SubjectBackupModel(
        id: 3,
        semesterId: semesterId,
        name: 'Computer Networks',
        lectureEnabled: true,
        labEnabled: false,
        sortOrder: 2,
        createdAt: nowMs - 17000000,
        updatedAt: nowMs,
      ),
      SubjectBackupModel(
        id: 4,
        semesterId: semesterId,
        name: 'Machine Learning',
        lectureEnabled: true,
        labEnabled: true,
        sortOrder: 3,
        createdAt: nowMs - 16000000,
        updatedAt: nowMs,
      ),
    ];

    final sessions = <AttendanceSessionBackupModel>[];
    int sessionId = 1;

    void addSession({
      required int subjectId,
      required String date,
      required String component,
      required String status,
      String? note,
    }) {
      sessions.add(
        AttendanceSessionBackupModel(
          id: sessionId++,
          subjectId: subjectId,
          sessionDate: date,
          component: component,
          status: status,
          note: note,
          createdAt: nowMs - (sessionId * 10000),
          updatedAt: nowMs - (sessionId * 10000),
        ),
      );
    }

    // 1. Data Structures & Algorithms (Subject 1)
    // 18 Lectures: 16 Present, 2 Absent (Dates Nov 02 - Nov 20)
    // 6 Labs: 5 Present, 1 Absent
    final dsaLectureDates = [
      '2026-11-02', '2026-11-03', '2026-11-04', '2026-11-05', '2026-11-06',
      '2026-11-09', '2026-11-10', '2026-11-11', '2026-11-12', '2026-11-13',
      '2026-11-16', '2026-11-17', '2026-11-18', '2026-11-19', '2026-11-20',
      '2026-11-02', '2026-11-09', '2026-11-16', // extra lectures on Mondays
    ];
    // Absences on Nov 06 and Nov 18
    for (int i = 0; i < dsaLectureDates.length; i++) {
      final isAbsent = i == 4 || i == 12; // 2 absent out of 18
      addSession(
        subjectId: 1,
        date: dsaLectureDates[i],
        component: 'lecture',
        status: isAbsent ? 'absent' : 'present',
      );
    }
    // 6 Labs: Nov 03, 06, 10, 13, 17, 20. Absent on Nov 13 (index 3).
    final dsaLabDates = [
      '2026-11-03', '2026-11-06', '2026-11-10', '2026-11-13', '2026-11-17', '2026-11-20'
    ];
    for (int i = 0; i < dsaLabDates.length; i++) {
      final isAbsent = i == 3;
      addSession(
        subjectId: 1,
        date: dsaLabDates[i],
        component: 'lab',
        status: isAbsent ? 'absent' : 'present',
      );
    }

    // 2. Operating Systems (Subject 2)
    // 14 Lectures: 9 Present, 5 Absent (64.3%)
    // 6 Labs: 3 Present, 3 Absent (50.0%)
    // Total: 12 Present, 8 Absent (60.0%)
    final osLectureDates = [
      '2026-11-02', '2026-11-03', '2026-11-04', '2026-11-05', '2026-11-06',
      '2026-11-09', '2026-11-10', '2026-11-11', '2026-11-12', '2026-11-13',
      '2026-11-16', '2026-11-17', '2026-11-18', '2026-11-19',
    ];
    // 5 Absences: indices 2, 5, 8, 11, 13
    for (int i = 0; i < osLectureDates.length; i++) {
      final isAbsent = i == 2 || i == 5 || i == 8 || i == 11 || i == 13;
      addSession(
        subjectId: 2,
        date: osLectureDates[i],
        component: 'lecture',
        status: isAbsent ? 'absent' : 'present',
      );
    }
    // 6 Labs: 3 Present, 3 Absent (indices 1, 3, 5 absent)
    final osLabDates = [
      '2026-11-04', '2026-11-06', '2026-11-11', '2026-11-13', '2026-11-18', '2026-11-20'
    ];
    for (int i = 0; i < osLabDates.length; i++) {
      final isAbsent = i == 1 || i == 3 || i == 5;
      addSession(
        subjectId: 2,
        date: osLabDates[i],
        component: 'lab',
        status: isAbsent ? 'absent' : 'present',
      );
    }

    // 3. Computer Networks (Subject 3)
    // 16 Lectures (Lab disabled): 12 Present, 4 Absent = 75.0%
    final cnLectureDates = [
      '2026-11-02', '2026-11-03', '2026-11-04', '2026-11-05',
      '2026-11-09', '2026-11-10', '2026-11-11', '2026-11-12',
      '2026-11-16', '2026-11-17', '2026-11-18', '2026-11-19',
      '2026-11-06', '2026-11-13', '2026-11-20', '2026-11-20',
    ];
    // 4 Absences: indices 3, 7, 11, 14
    for (int i = 0; i < cnLectureDates.length; i++) {
      final isAbsent = i == 3 || i == 7 || i == 11 || i == 14;
      addSession(
        subjectId: 3,
        date: cnLectureDates[i],
        component: 'lecture',
        status: isAbsent ? 'absent' : 'present',
      );
    }

    // 4. Machine Learning (Subject 4)
    // 12 Lectures: 12 Present, 0 Absent = 100%
    // 4 Labs: 3 Present, 1 Absent = 75%
    // Total: 15 Present, 1 Absent = 93.8%
    final mlLectureDates = [
      '2026-11-02', '2026-11-04', '2026-11-06',
      '2026-11-09', '2026-11-11', '2026-11-13',
      '2026-11-16', '2026-11-18', '2026-11-20',
      '2026-11-03', '2026-11-10', '2026-11-17',
    ];
    for (int i = 0; i < mlLectureDates.length; i++) {
      addSession(
        subjectId: 4,
        date: mlLectureDates[i],
        component: 'lecture',
        status: 'present',
      );
    }
    // 4 Labs: 3 Present, 1 Absent (Nov 17 absent)
    final mlLabDates = ['2026-11-03', '2026-11-10', '2026-11-17', '2026-11-20'];
    for (int i = 0; i < mlLabDates.length; i++) {
      final isAbsent = i == 2;
      addSession(
        subjectId: 4,
        date: mlLabDates[i],
        component: 'lab',
        status: isAbsent ? 'absent' : 'present',
      );
    }

    // Day Notes on key academic milestones
    final dayNotes = [
      DayNoteBackupModel(
        id: 1,
        semesterId: semesterId,
        date: '2026-11-05',
        content: 'DSA Midterm Examination (Binary Search Trees & Heaps)',
        createdAt: nowMs - 15000000,
        updatedAt: nowMs - 15000000,
      ),
      DayNoteBackupModel(
        id: 2,
        semesterId: semesterId,
        date: '2026-11-12',
        content: 'Operating Systems Lab Evaluation (Virtual Memory Paging)',
        createdAt: nowMs - 10000000,
        updatedAt: nowMs - 10000000,
      ),
      DayNoteBackupModel(
        id: 3,
        semesterId: semesterId,
        date: '2026-11-19',
        content: 'Computer Networks Quiz on TCP Congestion Control',
        createdAt: nowMs - 5000000,
        updatedAt: nowMs - 5000000,
      ),
    ];

    return BackupData(
      format: BackupConstants.formatIdentifier,
      formatVersion: BackupConstants.currentFormatVersion,
      exportedAt: now.toIso8601String(),
      semesters: [semester],
      subjects: subjects,
      attendanceSessions: sessions,
      dayNotes: dayNotes,
      appPreferences: {
        'themeMode': 'system',
      },
    );
  }

  static String getSampleBackupJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(getSampleBackupData().toJson());
  }
}
