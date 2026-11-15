import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/services/safe_absence_calculator.dart';

void main() {
  const calculator = SafeAbsenceCalculator();

  group('SafeAbsenceCalculator - Raw Combined', () {
    test('returns not available when no sessions conducted (0/0)', () {
      final result = calculator.calculate(
        present: 0,
        conducted: 0,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isFalse);
      expect(result.safeAbsences, isNull);
      expect(result.requiresScenario, isFalse);
    });

    test('returns 6 safe absences for 80/100 at 75% threshold', () {
      final result = calculator.calculate(
        present: 80,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.safeAbsences, 6);
      expect(80 / (100 + 6), greaterThanOrEqualTo(0.75));
      expect(80 / (100 + 7), lessThan(0.75));
    });

    test(
      'returns 0 safe absences when exactly at threshold (75/100 at 75%)',
      () {
        final result = calculator.calculate(
          present: 75,
          conducted: 100,
          threshold: 0.75,
          calculationMethod: AttendanceCalculationMethod.rawCombined,
        );

        expect(result.isAvailable, isTrue);
        expect(result.safeAbsences, 0);
        expect(75 / 100, greaterThanOrEqualTo(0.75));
        expect(75 / 101, lessThan(0.75));
      },
    );

    test('returns 20 safe absences for 90/100 at 75% threshold', () {
      final result = calculator.calculate(
        present: 90,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.safeAbsences, 20);
      expect(90 / (100 + 20), greaterThanOrEqualTo(0.75));
      expect(90 / (100 + 21), lessThan(0.75));
    });

    test('returns 33 safe absences for 100/100 at 75% threshold', () {
      final result = calculator.calculate(
        present: 100,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.safeAbsences, 33);
      expect(100 / (100 + 33), greaterThanOrEqualTo(0.75));
      expect(100 / (100 + 34), lessThan(0.75));
    });

    test(
      'returns 1 safe absence when just above threshold (76/100 at 75%)',
      () {
        final result = calculator.calculate(
          present: 76,
          conducted: 100,
          threshold: 0.75,
          calculationMethod: AttendanceCalculationMethod.rawCombined,
        );

        expect(result.isAvailable, isTrue);
        expect(result.safeAbsences, 1);
        expect(76 / (100 + 1), greaterThanOrEqualTo(0.75));
        expect(76 / (100 + 2), lessThan(0.75));
      },
    );

    test('returns 0 safe absences and belowThreshold when just below threshold (74/100 at 75%)', () {
      final result = calculator.calculate(
        present: 74,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.safeAbsences, 0);
      expect(result.message, contains('below 75% target'));
    });

    test('returns 0 safe absences when all absent (0/10 at 75%)', () {
      final result = calculator.calculate(
        present: 0,
        conducted: 10,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.safeAbsences, 0);
    });

    test('handles 100% threshold when all present (10/10 at 100%)', () {
      final result = calculator.calculate(
        present: 10,
        conducted: 10,
        threshold: 1.0,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.safeAbsences, 0);
      expect(result.message, contains('100%'));
    });

    test('handles 100% threshold when an absence exists (9/10 at 100%)', () {
      final result = calculator.calculate(
        present: 9,
        conducted: 10,
        threshold: 1.0,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.safeAbsences, 0);
    });
  });

  group('SafeAbsenceCalculator - Component Average', () {
    test('reports scenario is required for Component Average', () {
      final result = calculator.calculate(
        present: 80,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      expect(result.isAvailable, isFalse);
      expect(result.safeAbsences, isNull);
      expect(result.requiresScenario, isTrue);
      expect(result.message, contains('Lecture or Lab'));
    });
  });
}
