import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';

/// Authoritative backup format constants
abstract final class BackupConstants {
  static const String formatIdentifier = 'college-attendance-tracker-backup';
  static const int currentFormatVersion = 1;
}

/// Backup representation of a Semester
class SemesterBackupModel {
  const SemesterBackupModel({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    required this.attendanceThreshold,
    this.targetGoal = 0.85,
    required this.calculationMethod,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final double attendanceThreshold;
  final double targetGoal;
  final String calculationMethod;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startDate': startDate,
    'endDate': endDate,
    'attendanceThreshold': attendanceThreshold,
    'targetGoal': targetGoal,
    'calculationMethod': calculationMethod,
    'isArchived': isArchived,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory SemesterBackupModel.fromJson(Map<String, dynamic> json) {
    return SemesterBackupModel(
      id: json['id'] as int,
      name: json['name'] as String,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      attendanceThreshold: (json['attendanceThreshold'] as num).toDouble(),
      targetGoal: (json['targetGoal'] as num?)?.toDouble() ?? 0.85,
      calculationMethod: json['calculationMethod'] as String,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}

/// Backup representation of a Subject
class SubjectBackupModel {
  const SubjectBackupModel({
    required this.id,
    required this.semesterId,
    required this.name,
    required this.lectureEnabled,
    required this.labEnabled,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int semesterId;
  final String name;
  final bool lectureEnabled;
  final bool labEnabled;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'semesterId': semesterId,
    'name': name,
    'lectureEnabled': lectureEnabled,
    'labEnabled': labEnabled,
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory SubjectBackupModel.fromJson(Map<String, dynamic> json) {
    return SubjectBackupModel(
      id: json['id'] as int,
      semesterId: json['semesterId'] as int,
      name: json['name'] as String,
      lectureEnabled: json['lectureEnabled'] as bool? ?? true,
      labEnabled: json['labEnabled'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}

/// Backup representation of an AttendanceSession
class AttendanceSessionBackupModel {
  const AttendanceSessionBackupModel({
    required this.id,
    required this.subjectId,
    required this.sessionDate,
    required this.component,
    required this.status,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int subjectId;
  final String sessionDate;
  final String component;
  final String status;
  final String? note;
  final int createdAt;
  final int updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'sessionDate': sessionDate,
    'component': component,
    'status': status,
    'note': note,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory AttendanceSessionBackupModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionBackupModel(
      id: json['id'] as int,
      subjectId: json['subjectId'] as int,
      sessionDate: json['sessionDate'] as String,
      component: json['component'] as String,
      status: json['status'] as String,
      note: json['note'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}

/// Backup representation of a DayNote
class DayNoteBackupModel {
  const DayNoteBackupModel({
    required this.id,
    required this.semesterId,
    required this.date,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int semesterId;
  final String date;
  final String content;
  final int createdAt;
  final int updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'semesterId': semesterId,
    'date': date,
    'content': content,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory DayNoteBackupModel.fromJson(Map<String, dynamic> json) {
    return DayNoteBackupModel(
      id: json['id'] as int,
      semesterId: json['semesterId'] as int,
      date: json['date'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}

/// Root data model representing the complete versioned backup
class BackupData {
  const BackupData({
    this.format = BackupConstants.formatIdentifier,
    this.formatVersion = BackupConstants.currentFormatVersion,
    required this.exportedAt,
    required this.semesters,
    required this.subjects,
    required this.attendanceSessions,
    this.dayNotes = const [],
    this.appPreferences,
  });

  final String format;
  final int formatVersion;
  final String exportedAt;
  final List<SemesterBackupModel> semesters;
  final List<SubjectBackupModel> subjects;
  final List<AttendanceSessionBackupModel> attendanceSessions;
  final List<DayNoteBackupModel> dayNotes;
  final Map<String, dynamic>? appPreferences;

  Map<String, dynamic> toJson() => {
    'format': format,
    'formatVersion': formatVersion,
    'exportedAt': exportedAt,
    'data': {
      'semesters': semesters.map((s) => s.toJson()).toList(),
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'attendanceSessions': attendanceSessions.map((s) => s.toJson()).toList(),
      'dayNotes': dayNotes.map((n) => n.toJson()).toList(),
      if (appPreferences != null) 'preferences': appPreferences,
    },
  };

  /// Generates a summary overview of the backup data
  BackupSummary toSummary() {
    DateTime parsedExportDate;
    try {
      parsedExportDate = DateTime.parse(exportedAt);
    } catch (_) {
      parsedExportDate = DateTime.now();
    }

    int presents = 0;
    int absents = 0;
    for (final session in attendanceSessions) {
      if (session.status == AttendanceStatus.present.dbValue) {
        presents++;
      } else if (session.status == AttendanceStatus.absent.dbValue) {
        absents++;
      }
    }

    return BackupSummary(
      exportedAt: parsedExportDate,
      semestersCount: semesters.length,
      semesterNames: semesters.map((s) => s.name).toList(),
      subjectsCount: subjects.length,
      sessionsCount: attendanceSessions.length,
      presentCount: presents,
      absentCount: absents,
      dayNotesCount: dayNotes.length,
    );
  }
}

/// Summary details for displaying to the user before restore confirmation
class BackupSummary {
  const BackupSummary({
    required this.exportedAt,
    required this.semestersCount,
    required this.semesterNames,
    required this.subjectsCount,
    required this.sessionsCount,
    required this.presentCount,
    required this.absentCount,
    this.dayNotesCount = 0,
  });

  final DateTime exportedAt;
  final int semestersCount;
  final List<String> semesterNames;
  final int subjectsCount;
  final int sessionsCount;
  final int presentCount;
  final int absentCount;
  final int dayNotesCount;
}
