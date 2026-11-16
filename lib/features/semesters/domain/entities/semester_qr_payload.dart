import 'dart:convert';

import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';

class SubjectQrPayload {
  const SubjectQrPayload({
    required this.name,
    this.lectureEnabled = true,
    this.labEnabled = false,
    this.sortOrder = 0,
  });

  final String name;
  final bool lectureEnabled;
  final bool labEnabled;
  final int sortOrder;

  bool get hasBothComponents => lectureEnabled && labEnabled;

  Map<String, dynamic> toJson() => {
    'name': name,
    'lecture': lectureEnabled,
    'lab': labEnabled,
    'sort_order': sortOrder,
  };

  factory SubjectQrPayload.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim() ?? '';
    final lecture = json['lecture'] as bool? ?? true;
    final lab = json['lab'] as bool? ?? false;
    final sortOrder = (json['sort_order'] as num?)?.toInt() ?? 0;

    if (name.isEmpty) {
      throw const FormatException('Subject name cannot be empty');
    }
    if (!lecture && !lab) {
      throw FormatException(
        'Subject "$name" must have at least one component enabled',
      );
    }

    return SubjectQrPayload(
      name: name,
      lectureEnabled: lecture,
      labEnabled: lab,
      sortOrder: sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectQrPayload &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          lectureEnabled == other.lectureEnabled &&
          labEnabled == other.labEnabled &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      name.hashCode ^
      lectureEnabled.hashCode ^
      labEnabled.hashCode ^
      sortOrder.hashCode;
}

class SemesterQrPayload {
  const SemesterQrPayload({
    required this.semesterName,
    required this.attendanceThreshold,
    required this.calculationMethod,
    required this.subjects,
    this.targetGoal = 0.85,
  });

  static const String appIdentifier = 'attendly';
  static const int currentVersion = 1;
  static const String payloadType = 'semester_template';

  final String semesterName;
  final double attendanceThreshold;
  final AttendanceCalculationMethod calculationMethod;
  final List<SubjectQrPayload> subjects;
  final double targetGoal;

  int get thresholdPercent => (attendanceThreshold * 100).round();
  int get targetGoalPercent => (targetGoal * 100).round();

  Map<String, dynamic> toJson() => {
    'app': appIdentifier,
    'v': currentVersion,
    'type': payloadType,
    'name': semesterName,
    'threshold': attendanceThreshold,
    'calc_method': calculationMethod.dbValue,
    'goal': targetGoal,
    'subjects': subjects.map((s) => s.toJson()).toList(),
  };

  String toEncodedString() => jsonEncode(toJson());

  factory SemesterQrPayload.fromJson(Map<String, dynamic> json) {
    if (json['app'] != appIdentifier) {
      throw const FormatException('QR code is not an Attendly package');
    }
    final version = (json['v'] as num?)?.toInt();
    if (version == null || version > currentVersion) {
      throw FormatException('Unsupported QR code version: $version');
    }
    if (json['type'] != payloadType) {
      throw const FormatException('QR code is not a semester template');
    }

    final name = (json['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      throw const FormatException('Semester name cannot be empty');
    }

    final threshold = (json['threshold'] as num?)?.toDouble() ?? 0.75;
    if (threshold <= 0.0 || threshold > 1.0) {
      throw FormatException('Invalid threshold: ${(threshold * 100).round()}%');
    }

    final calcMethodStr = json['calc_method'] as String? ?? 'raw_combined';
    final calcMethod = AttendanceCalculationMethod.fromDbValue(calcMethodStr);

    final goal = (json['goal'] as num?)?.toDouble() ?? 0.85;

    final subjectsRaw = json['subjects'];
    if (subjectsRaw is! List || subjectsRaw.isEmpty) {
      throw const FormatException('Semester has no subjects to import');
    }

    final subjects = subjectsRaw
        .map(
          (e) => SubjectQrPayload.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    return SemesterQrPayload(
      semesterName: name,
      attendanceThreshold: threshold,
      calculationMethod: calcMethod,
      subjects: subjects,
      targetGoal: goal,
    );
  }

  static SemesterQrPayload? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is! Map<String, dynamic>) {
        if (decoded is Map) {
          return SemesterQrPayload.fromJson(Map<String, dynamic>.from(decoded));
        }
        return null;
      }
      return SemesterQrPayload.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static String? validateRaw(String raw) {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw.trim());
    } catch (_) {
      return 'Corrupted or unreadable QR code data';
    }

    if (decoded is! Map) {
      return 'QR code is not an Attendly semester template';
    }

    try {
      SemesterQrPayload.fromJson(Map<String, dynamic>.from(decoded));
      return null;
    } on FormatException catch (e) {
      return e.message;
    } catch (_) {
      return 'Corrupted or unreadable QR code data';
    }
  }
}
