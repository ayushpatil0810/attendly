import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/backup/backup_format.dart';
import 'package:attendly/core/backup/backup_validator.dart';

void main() {
  group('BackupValidator Tests', () {
    Map<String, dynamic> createValidBackupMap() {
      return <String, dynamic>{
        'format': BackupConstants.formatIdentifier,
        'formatVersion': 1,
        'exportedAt': '2026-11-15T12:00:00.000Z',
        'data': <String, dynamic>{
          'semesters': <dynamic>[
            <String, dynamic>{
              'id': 1,
              'name': 'Semester 5',
              'startDate': '2026-08-01',
              'endDate': '2026-12-15',
              'attendanceThreshold': 0.75,
              'calculationMethod': 'raw_combined',
              'isArchived': false,
              'createdAt': 1700000000000,
              'updatedAt': 1700000000000,
            },
          ],
          'subjects': <dynamic>[
            <String, dynamic>{
              'id': 101,
              'semesterId': 1,
              'name': 'Machine Learning',
              'lectureEnabled': true,
              'labEnabled': true,
              'sortOrder': 0,
              'createdAt': 1700000000000,
              'updatedAt': 1700000000000,
            },
          ],
          'attendanceSessions': <dynamic>[
            <String, dynamic>{
              'id': 1001,
              'subjectId': 101,
              'sessionDate': '2026-09-01',
              'component': 'lecture',
              'status': 'present',
              'note': 'Intro lecture',
              'createdAt': 1700000000000,
              'updatedAt': 1700000000000,
            },
            <String, dynamic>{
              'id': 1002,
              'subjectId': 101,
              'sessionDate': '2026-09-01',
              'component': 'lab',
              'status': 'absent',
              'note': null,
              'createdAt': 1700000000000,
              'updatedAt': 1700000000000,
            },
          ],
        },
      };
    }

    test('valid backup parses and produces correct summary', () {
      final jsonStr = jsonEncode(createValidBackupMap());
      final result = BackupValidator.validate(jsonStr);

      expect(result.isValid, isTrue);
      expect(result.error, isNull);
      expect(result.data, isNotNull);
      expect(result.summary, isNotNull);

      final summary = result.summary!;
      expect(summary.semestersCount, 1);
      expect(summary.semesterNames, ['Semester 5']);
      expect(summary.subjectsCount, 1);
      expect(summary.sessionsCount, 2);
      expect(summary.presentCount, 1);
      expect(summary.absentCount, 1);
    });

    test('rejects empty or whitespace json string', () {
      final res1 = BackupValidator.validate('');
      expect(res1.isValid, isFalse);
      expect(res1.error, contains('empty'));

      final res2 = BackupValidator.validate('   ');
      expect(res2.isValid, isFalse);
      expect(res2.error, contains('empty'));
    });

    test('rejects invalid JSON syntax', () {
      final res = BackupValidator.validate('{"format": "incomplete"');
      expect(res.isValid, isFalse);
      expect(res.error, contains('Invalid JSON'));
    });

    test('rejects non-object root JSON', () {
      final res = BackupValidator.validate('["an", "array"]');
      expect(res.isValid, isFalse);
      expect(res.error, contains('root element must be a JSON object'));
    });

    test('rejects missing or wrong format identifier', () {
      final map = createValidBackupMap();
      map.remove('format');
      var res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Missing backup format identifier'));

      map['format'] = 'some-other-format';
      res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Unrecognized backup format'));
    });

    test('rejects missing or unsupported format version', () {
      final map = createValidBackupMap();
      map.remove('formatVersion');
      var res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Missing backup format version'));

      map['formatVersion'] = 2; // Future version
      res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Unsupported backup version 2'));

      map['formatVersion'] = 0;
      res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Invalid backup version 0'));
    });

    test('rejects invalid export timestamp', () {
      final map = createValidBackupMap();
      map['exportedAt'] = 'not-a-timestamp';
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Malformed export timestamp'));
    });

    test('rejects missing data container', () {
      final map = createValidBackupMap();
      map.remove('data');
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Missing or invalid "data" container'));
    });

    test('rejects non-list data collections', () {
      final map = createValidBackupMap();
      (map['data'] as Map)['semesters'] = 'not-a-list';
      var res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('"data.semesters" must be a list'));

      final map2 = createValidBackupMap();
      (map2['data'] as Map)['subjects'] = {};
      res = BackupValidator.validate(jsonEncode(map2));
      expect(res.isValid, isFalse);
      expect(res.error, contains('"data.subjects" must be a list'));

      final map3 = createValidBackupMap();
      (map3['data'] as Map)['attendanceSessions'] = 42;
      res = BackupValidator.validate(jsonEncode(map3));
      expect(res.isValid, isFalse);
      expect(res.error, contains('"data.attendanceSessions" must be a list'));
    });

    test('rejects duplicate semester IDs', () {
      final map = createValidBackupMap();
      final semesters = (map['data'] as Map)['semesters'] as List;
      semesters.add({
        'id': 1, // Duplicate ID
        'name': 'Semester 6',
        'attendanceThreshold': 0.8,
        'calculationMethod': 'raw_combined',
        'createdAt': 1700000000000,
        'updatedAt': 1700000000000,
      });
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Duplicate semester ID 1'));
    });

    test('rejects empty semester name', () {
      final map = createValidBackupMap();
      ((map['data'] as Map)['semesters'] as List)[0]['name'] = '   ';
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('empty or invalid name'));
    });

    test('rejects invalid semester threshold', () {
      final map = createValidBackupMap();
      ((map['data'] as Map)['semesters'] as List)[0]['attendanceThreshold'] =
          1.5;
      var res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('invalid attendance threshold'));

      ((map['data'] as Map)['semesters'] as List)[0]['attendanceThreshold'] =
          0.0;
      res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('invalid attendance threshold'));
    });

    test('rejects unsupported calculation method', () {
      final map = createValidBackupMap();
      ((map['data'] as Map)['semesters'] as List)[0]['calculationMethod'] =
          'weighted_magic';
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('unsupported calculation method'));
    });

    test('rejects invalid semester date formats and order', () {
      final map = createValidBackupMap();
      ((map['data'] as Map)['semesters'] as List)[0]['startDate'] =
          '2026-02-31'; // Invalid calendar date
      var res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('invalid start date'));

      // Start date after end date
      final map2 = createValidBackupMap();
      ((map2['data'] as Map)['semesters'] as List)[0]['startDate'] =
          '2026-12-01';
      ((map2['data'] as Map)['semesters'] as List)[0]['endDate'] = '2026-05-01';
      res = BackupValidator.validate(jsonEncode(map2));
      expect(res.isValid, isFalse);
      expect(res.error, contains('start date (2026-12-01) is after end date'));
    });

    test('rejects duplicate subject IDs', () {
      final map = createValidBackupMap();
      final subjects = (map['data'] as Map)['subjects'] as List;
      subjects.add({
        'id': 101, // Duplicate ID
        'semesterId': 1,
        'name': 'Networks',
        'lectureEnabled': true,
        'labEnabled': false,
        'createdAt': 1700000000000,
        'updatedAt': 1700000000000,
      });
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Duplicate subject ID 101'));
    });

    test('rejects subject referencing non-existent semester', () {
      final map = createValidBackupMap();
      ((map['data'] as Map)['subjects'] as List)[0]['semesterId'] =
          999; // Non-existent
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('references non-existent semester ID 999'));
    });

    test('rejects subject with neither component enabled', () {
      final map = createValidBackupMap();
      ((map['data'] as Map)['subjects'] as List)[0]['lectureEnabled'] = false;
      ((map['data'] as Map)['subjects'] as List)[0]['labEnabled'] = false;
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('must have at least Lecture or Lab enabled'));
    });

    test('rejects duplicate session IDs', () {
      final map = createValidBackupMap();
      final sessions = (map['data'] as Map)['attendanceSessions'] as List;
      sessions[1]['id'] = sessions[0]['id']; // Duplicate ID
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Duplicate session ID'));
    });

    test('rejects session referencing non-existent subject', () {
      final map = createValidBackupMap();
      ((map['data'] as Map)['attendanceSessions'] as List)[0]['subjectId'] =
          888;
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('references non-existent subject ID 888'));
    });

    test('rejects session with invalid calendar date', () {
      final map = createValidBackupMap();
      ((map['data'] as Map)['attendanceSessions'] as List)[0]['sessionDate'] =
          '2026-11-31'; // Nov has 30 days
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('invalid date: "2026-11-31"'));
    });

    test('rejects session with invalid component or status', () {
      final map = createValidBackupMap();
      ((map['data'] as Map)['attendanceSessions'] as List)[0]['component'] =
          'tutorial';
      var res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('invalid component: "tutorial"'));

      final map2 = createValidBackupMap();
      ((map2['data'] as Map)['attendanceSessions'] as List)[0]['status'] =
          'excused';
      res = BackupValidator.validate(jsonEncode(map2));
      expect(res.isValid, isFalse);
      expect(res.error, contains('invalid status: "excused"'));
    });

    test('rejects session when component is disabled on subject', () {
      final map = createValidBackupMap();
      // Subject only has lecture enabled
      ((map['data'] as Map)['subjects'] as List)[0]['labEnabled'] = false;
      // Second session is for lab
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(
        res.error,
        contains('Lab is disabled for subject "Machine Learning"'),
      );
    });

    test('rejects duplicate session for same subject, date, and component', () {
      final map = createValidBackupMap();
      final sessions = (map['data'] as Map)['attendanceSessions'] as List;
      // Add a third session with same (subjectId, sessionDate, component) as first
      sessions.add({
        'id': 1003,
        'subjectId': 101,
        'sessionDate': '2026-09-01',
        'component': 'lecture', // duplicate of session 1001
        'status': 'absent',
        'createdAt': 1700000000000,
        'updatedAt': 1700000000000,
      });
      final res = BackupValidator.validate(jsonEncode(map));
      expect(res.isValid, isFalse);
      expect(res.error, contains('Duplicate session in backup'));
    });
  });
}
