import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/semesters/domain/entities/semester_qr_payload.dart';

void main() {
  group('SemesterQrPayload Serialization & Deserialization', () {
    test(
      'serializes and deserializes a complete semester payload roundtrip',
      () {
        const payload = SemesterQrPayload(
          semesterName: 'Fall 2026',
          attendanceThreshold: 0.80,
          calculationMethod: AttendanceCalculationMethod.componentAverage,
          subjects: [
            SubjectQrPayload(
              name: 'Distributed Systems',
              lectureEnabled: true,
              labEnabled: true,
              sortOrder: 0,
            ),
            SubjectQrPayload(
              name: 'Linear Algebra',
              lectureEnabled: true,
              labEnabled: false,
              sortOrder: 1,
            ),
          ],
        );

        final encoded = payload.toEncodedString();
        final decoded = SemesterQrPayload.tryParse(encoded);

        expect(decoded, isNotNull);
        expect(decoded!.semesterName, equals('Fall 2026'));
        expect(decoded.attendanceThreshold, equals(0.80));
        expect(decoded.thresholdPercent, equals(80));
        expect(
          decoded.calculationMethod,
          equals(AttendanceCalculationMethod.componentAverage),
        );
        expect(decoded.subjects.length, equals(2));
        expect(decoded.subjects[0].name, equals('Distributed Systems'));
        expect(decoded.subjects[0].hasBothComponents, isTrue);
        expect(decoded.subjects[1].name, equals('Linear Algebra'));
        expect(decoded.subjects[1].labEnabled, isFalse);
      },
    );

    test('rejects payload with wrong app identifier', () {
      final json = {
        'app': 'other_app',
        'v': 1,
        'type': 'semester_template',
        'name': 'Semester 4',
        'threshold': 0.75,
        'calc_method': 'raw_combined',
        'subjects': [
          {'name': 'Math', 'lecture': true, 'lab': false},
        ],
      };

      expect(
        () => SemesterQrPayload.fromJson(json),
        throwsA(isA<FormatException>()),
      );
      expect(SemesterQrPayload.tryParse(jsonEncode(json)), isNull);
      expect(
        SemesterQrPayload.validateRaw(jsonEncode(json)),
        contains('not an Attendly package'),
      );
    });

    test('rejects payload with empty semester name', () {
      final json = {
        'app': 'attendly',
        'v': 1,
        'type': 'semester_template',
        'name': '   ',
        'threshold': 0.75,
        'calc_method': 'raw_combined',
        'subjects': [
          {'name': 'Math', 'lecture': true, 'lab': false},
        ],
      };

      expect(
        SemesterQrPayload.validateRaw(jsonEncode(json)),
        contains('Semester name cannot be empty'),
      );
    });

    test('rejects payload with invalid threshold', () {
      final json = {
        'app': 'attendly',
        'v': 1,
        'type': 'semester_template',
        'name': 'Semester 1',
        'threshold': 1.5,
        'calc_method': 'raw_combined',
        'subjects': [
          {'name': 'Math', 'lecture': true, 'lab': false},
        ],
      };

      expect(
        SemesterQrPayload.validateRaw(jsonEncode(json)),
        contains('Invalid threshold'),
      );
    });

    test('rejects payload with empty subjects list', () {
      final json = {
        'app': 'attendly',
        'v': 1,
        'type': 'semester_template',
        'name': 'Semester 1',
        'threshold': 0.75,
        'calc_method': 'raw_combined',
        'subjects': <Map<String, dynamic>>[],
      };

      expect(
        SemesterQrPayload.validateRaw(jsonEncode(json)),
        contains('no subjects to import'),
      );
    });

    test('rejects subject with both lecture and lab disabled', () {
      final json = {
        'app': 'attendly',
        'v': 1,
        'type': 'semester_template',
        'name': 'Semester 1',
        'threshold': 0.75,
        'calc_method': 'raw_combined',
        'subjects': [
          {'name': 'Ghost Course', 'lecture': false, 'lab': false},
        ],
      };

      expect(
        SemesterQrPayload.validateRaw(jsonEncode(json)),
        contains('at least one component enabled'),
      );
    });

    test('validateRaw returns clear error for non-json input', () {
      expect(
        SemesterQrPayload.validateRaw('https://google.com'),
        equals('Corrupted or unreadable QR code data'),
      );
    });
  });
}
