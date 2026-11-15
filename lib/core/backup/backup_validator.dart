import 'dart:convert';

import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';

import 'backup_format.dart';

/// Result of validating a backup file
class BackupValidationResult {
  const BackupValidationResult.success({
    required this.data,
    required this.summary,
  }) : isValid = true,
       error = null;

  const BackupValidationResult.failure(this.error)
    : isValid = false,
      data = null,
      summary = null;

  final bool isValid;
  final String? error;
  final BackupData? data;
  final BackupSummary? summary;
}

/// Pure Dart validator for backup files before restore
class BackupValidator {
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB max limit
  static const int maxTotalRecords = 100000;

  /// Validates a raw JSON string content and returns a [BackupValidationResult]
  static BackupValidationResult validate(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return const BackupValidationResult.failure('The backup file is empty.');
    }

    if (rawJson.length > maxFileSizeBytes) {
      return const BackupValidationResult.failure(
        'Backup file exceeds maximum allowed size (25 MB).',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException catch (e) {
      return BackupValidationResult.failure(
        'Invalid JSON format: ${e.message}',
      );
    } catch (e) {
      return BackupValidationResult.failure('Could not parse backup file: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      return const BackupValidationResult.failure(
        'Invalid backup format: root element must be a JSON object.',
      );
    }

    // 1. Verify format identifier
    final format = decoded['format'];
    if (format == null) {
      return const BackupValidationResult.failure(
        'Missing backup format identifier.',
      );
    }
    if (format is! String || format != BackupConstants.formatIdentifier) {
      return BackupValidationResult.failure(
        'Unrecognized backup format "$format". Expected "${BackupConstants.formatIdentifier}".',
      );
    }

    // 2. Verify format version
    final formatVersion = decoded['formatVersion'];
    if (formatVersion == null) {
      return const BackupValidationResult.failure(
        'Missing backup format version.',
      );
    }
    if (formatVersion is! int) {
      return const BackupValidationResult.failure(
        'Backup format version must be an integer.',
      );
    }
    if (formatVersion > BackupConstants.currentFormatVersion) {
      return BackupValidationResult.failure(
        'Unsupported backup version $formatVersion. This app supports backup version ${BackupConstants.currentFormatVersion}. Please update the app.',
      );
    }
    if (formatVersion < 1) {
      return BackupValidationResult.failure(
        'Invalid backup version $formatVersion.',
      );
    }

    // 3. Verify exportedAt timestamp
    final exportedAt = decoded['exportedAt'];
    if (exportedAt == null || exportedAt is! String) {
      return const BackupValidationResult.failure(
        'Missing or invalid export timestamp ("exportedAt").',
      );
    }
    try {
      DateTime.parse(exportedAt);
    } catch (_) {
      return BackupValidationResult.failure(
        'Malformed export timestamp "$exportedAt".',
      );
    }

    // 4. Verify data payload structure
    final dataObj = decoded['data'];
    if (dataObj == null || dataObj is! Map<String, dynamic>) {
      return const BackupValidationResult.failure(
        'Missing or invalid "data" container in backup.',
      );
    }

    final rawSemesters = dataObj['semesters'];
    final rawSubjects = dataObj['subjects'];
    final rawSessions = dataObj['attendanceSessions'];

    if (rawSemesters is! List) {
      return const BackupValidationResult.failure(
        '"data.semesters" must be a list.',
      );
    }
    if (rawSubjects is! List) {
      return const BackupValidationResult.failure(
        '"data.subjects" must be a list.',
      );
    }
    if (rawSessions is! List) {
      return const BackupValidationResult.failure(
        '"data.attendanceSessions" must be a list.',
      );
    }

    final totalRecords =
        rawSemesters.length + rawSubjects.length + rawSessions.length;
    if (totalRecords > maxTotalRecords) {
      return const BackupValidationResult.failure(
        'Backup contains too many records, exceeding safe limits.',
      );
    }

    // 5. Parse and validate semesters
    final parsedSemesters = <SemesterBackupModel>[];
    final semesterIds = <int>{};

    for (var i = 0; i < rawSemesters.length; i++) {
      final s = rawSemesters[i];
      if (s is! Map<String, dynamic>) {
        return BackupValidationResult.failure(
          'Semester at index $i is not a valid object.',
        );
      }

      final id = s['id'];
      if (id is! int) {
        return BackupValidationResult.failure(
          'Semester at index $i has missing or invalid integer "id".',
        );
      }
      if (semesterIds.contains(id)) {
        return BackupValidationResult.failure(
          'Duplicate semester ID $id found in backup.',
        );
      }
      semesterIds.add(id);

      final name = s['name'];
      if (name is! String || name.trim().isEmpty) {
        return BackupValidationResult.failure(
          'Semester $id has an empty or invalid name.',
        );
      }

      final threshold = s['attendanceThreshold'];
      if (threshold is! num || threshold <= 0.0 || threshold > 1.0) {
        return BackupValidationResult.failure(
          'Semester "$name" has an invalid attendance threshold: $threshold (must be > 0 and <= 1.0).',
        );
      }

      final method = s['calculationMethod'];
      if (method is! String ||
          (method != AttendanceCalculationMethod.rawCombined.dbValue &&
              method != AttendanceCalculationMethod.componentAverage.dbValue)) {
        return BackupValidationResult.failure(
          'Semester "$name" has an unsupported calculation method: "$method".',
        );
      }

      final startDate = s['startDate'];
      final endDate = s['endDate'];
      DateTime? parsedStartDate;
      DateTime? parsedEndDate;

      if (startDate != null) {
        if (startDate is! String || !_isValidIsoDate(startDate)) {
          return BackupValidationResult.failure(
            'Semester "$name" has an invalid start date: "$startDate". Expected YYYY-MM-DD.',
          );
        }
        parsedStartDate = DateTime.tryParse(startDate);
      }

      if (endDate != null) {
        if (endDate is! String || !_isValidIsoDate(endDate)) {
          return BackupValidationResult.failure(
            'Semester "$name" has an invalid end date: "$endDate". Expected YYYY-MM-DD.',
          );
        }
        parsedEndDate = DateTime.tryParse(endDate);
      }

      if (parsedStartDate != null &&
          parsedEndDate != null &&
          parsedStartDate.isAfter(parsedEndDate)) {
        return BackupValidationResult.failure(
          'Semester "$name" start date ($startDate) is after end date ($endDate).',
        );
      }

      final isArchived = s['isArchived'];
      if (isArchived != null && isArchived is! bool) {
        return BackupValidationResult.failure(
          'Semester "$name" has non-boolean isArchived value.',
        );
      }

      final createdAt = s['createdAt'];
      final updatedAt = s['updatedAt'];
      if (createdAt is! int || updatedAt is! int) {
        return BackupValidationResult.failure(
          'Semester "$name" has missing or invalid integer timestamps.',
        );
      }

      parsedSemesters.add(
        SemesterBackupModel(
          id: id,
          name: name.trim(),
          startDate: startDate as String?,
          endDate: endDate as String?,
          attendanceThreshold: threshold.toDouble(),
          calculationMethod: method,
          isArchived: isArchived as bool? ?? false,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }

    // 6. Parse and validate subjects
    final parsedSubjects = <SubjectBackupModel>[];
    final subjectIds = <int>{};
    final subjectMap = <int, SubjectBackupModel>{};

    for (var i = 0; i < rawSubjects.length; i++) {
      final sub = rawSubjects[i];
      if (sub is! Map<String, dynamic>) {
        return BackupValidationResult.failure(
          'Subject at index $i is not a valid object.',
        );
      }

      final id = sub['id'];
      if (id is! int) {
        return BackupValidationResult.failure(
          'Subject at index $i has missing or invalid integer "id".',
        );
      }
      if (subjectIds.contains(id)) {
        return BackupValidationResult.failure(
          'Duplicate subject ID $id found in backup.',
        );
      }
      subjectIds.add(id);

      final semesterId = sub['semesterId'];
      if (semesterId is! int || !semesterIds.contains(semesterId)) {
        return BackupValidationResult.failure(
          'Subject at index $i references non-existent semester ID $semesterId.',
        );
      }

      final name = sub['name'];
      if (name is! String || name.trim().isEmpty) {
        return BackupValidationResult.failure(
          'Subject $id has an empty or invalid name.',
        );
      }

      final lectureEnabled = sub['lectureEnabled'] as bool? ?? true;
      final labEnabled = sub['labEnabled'] as bool? ?? false;
      if (!lectureEnabled && !labEnabled) {
        return BackupValidationResult.failure(
          'Subject "$name" must have at least Lecture or Lab enabled.',
        );
      }

      final sortOrder = sub['sortOrder'];
      if (sortOrder != null && sortOrder is! int) {
        return BackupValidationResult.failure(
          'Subject "$name" has invalid sortOrder.',
        );
      }

      final createdAt = sub['createdAt'];
      final updatedAt = sub['updatedAt'];
      if (createdAt is! int || updatedAt is! int) {
        return BackupValidationResult.failure(
          'Subject "$name" has missing or invalid integer timestamps.',
        );
      }

      final model = SubjectBackupModel(
        id: id,
        semesterId: semesterId,
        name: name.trim(),
        lectureEnabled: lectureEnabled,
        labEnabled: labEnabled,
        sortOrder: sortOrder as int? ?? 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      parsedSubjects.add(model);
      subjectMap[id] = model;
    }

    // 7. Parse and validate attendance sessions
    final parsedSessions = <AttendanceSessionBackupModel>[];
    final sessionIds = <int>{};
    final uniqueSessionKeys = <String>{};

    for (var i = 0; i < rawSessions.length; i++) {
      final sess = rawSessions[i];
      if (sess is! Map<String, dynamic>) {
        return BackupValidationResult.failure(
          'Attendance session at index $i is not a valid object.',
        );
      }

      final id = sess['id'];
      if (id is! int) {
        return BackupValidationResult.failure(
          'Attendance session at index $i has missing or invalid integer "id".',
        );
      }
      if (sessionIds.contains(id)) {
        return BackupValidationResult.failure(
          'Duplicate session ID $id found in backup.',
        );
      }
      sessionIds.add(id);

      final subjectId = sess['subjectId'];
      if (subjectId is! int || !subjectMap.containsKey(subjectId)) {
        return BackupValidationResult.failure(
          'Attendance session $id references non-existent subject ID $subjectId.',
        );
      }
      final subject = subjectMap[subjectId]!;

      final sessionDate = sess['sessionDate'];
      if (sessionDate is! String || !_isValidIsoDate(sessionDate)) {
        return BackupValidationResult.failure(
          'Attendance session $id has an invalid date: "$sessionDate". Expected YYYY-MM-DD.',
        );
      }

      final component = sess['component'];
      if (component is! String ||
          (component != SessionComponent.lecture.dbValue &&
              component != SessionComponent.lab.dbValue)) {
        return BackupValidationResult.failure(
          'Attendance session $id has an invalid component: "$component". Must be "lecture" or "lab".',
        );
      }

      // Check component enabled on subject
      if (component == SessionComponent.lecture.dbValue &&
          !subject.lectureEnabled) {
        return BackupValidationResult.failure(
          'Attendance session $id on $sessionDate has component "lecture", but Lecture is disabled for subject "${subject.name}".',
        );
      }
      if (component == SessionComponent.lab.dbValue && !subject.labEnabled) {
        return BackupValidationResult.failure(
          'Attendance session $id on $sessionDate has component "lab", but Lab is disabled for subject "${subject.name}".',
        );
      }

      final status = sess['status'];
      if (status is! String ||
          (status != AttendanceStatus.present.dbValue &&
              status != AttendanceStatus.absent.dbValue)) {
        return BackupValidationResult.failure(
          'Attendance session $id has an invalid status: "$status". Must be "present" or "absent".',
        );
      }

      final note = sess['note'];
      if (note != null && note is! String) {
        return BackupValidationResult.failure(
          'Attendance session $id has an invalid note.',
        );
      }

      final createdAt = sess['createdAt'];
      final updatedAt = sess['updatedAt'];
      if (createdAt is! int || updatedAt is! int) {
        return BackupValidationResult.failure(
          'Attendance session $id has missing or invalid integer timestamps.',
        );
      }

      // Check for duplicate (subjectId, sessionDate, component)
      final uniqueKey = '$subjectId|$sessionDate|$component';
      if (uniqueSessionKeys.contains(uniqueKey)) {
        return BackupValidationResult.failure(
          'Duplicate session in backup for subject "${subject.name}" on $sessionDate for $component.',
        );
      }
      uniqueSessionKeys.add(uniqueKey);

      parsedSessions.add(
        AttendanceSessionBackupModel(
          id: id,
          subjectId: subjectId,
          sessionDate: sessionDate,
          component: component,
          status: status,
          note: note as String?,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }

    final backupData = BackupData(
      format: format,
      formatVersion: formatVersion,
      exportedAt: exportedAt,
      semesters: parsedSemesters,
      subjects: parsedSubjects,
      attendanceSessions: parsedSessions,
      appPreferences: dataObj['preferences'] as Map<String, dynamic>?,
    );

    return BackupValidationResult.success(
      data: backupData,
      summary: backupData.toSummary(),
    );
  }

  /// Validates format YYYY-MM-DD and calendar date truth
  static bool _isValidIsoDate(String dateStr) {
    if (dateStr.length != 10) return false;
    final parts = dateStr.split('-');
    if (parts.length != 3) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;

    try {
      final dt = DateTime(year, month, day);
      return dt.year == year && dt.month == month && dt.day == day;
    } catch (_) {
      return false;
    }
  }
}
