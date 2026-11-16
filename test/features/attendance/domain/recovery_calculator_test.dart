import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/services/recovery_calculator.dart';

void main() {
  const calculator = RecoveryCalculator();

  group('RecoveryCalculator - Raw Combined', () {
    test('returns not available when no sessions conducted (0/0)', () {
      final result = calculator.calculate(
        present: 0,
        conducted: 0,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isFalse);
      expect(result.requiredConsecutivePresents, isNull);
      expect(result.requiresScenario, isFalse);
    });

    test('returns 0 when already meeting threshold (75/100 at 75%)', () {
      final result = calculator.calculate(
        present: 75,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.requiredConsecutivePresents, 0);
      expect(result.isImpossible, isFalse);
    });

    test('returns 0 when above threshold (80/100 at 75%)', () {
      final result = calculator.calculate(
        present: 80,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.requiredConsecutivePresents, 0);
    });

    test('returns 60 consecutive presents for 60/100 at 75% threshold', () {
      final result = calculator.calculate(
        present: 60,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.requiredConsecutivePresents, 60);
      expect((60 + 60) / (100 + 60), greaterThanOrEqualTo(0.75));
      expect((60 + 59) / (100 + 59), lessThan(0.75));
    });

    test('returns 20 consecutive presents for 70/100 at 75% threshold', () {
      final result = calculator.calculate(
        present: 70,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.requiredConsecutivePresents, 20);
      expect((70 + 20) / (100 + 20), greaterThanOrEqualTo(0.75));
      expect((70 + 19) / (100 + 19), lessThan(0.75));
    });

    test('returns 4 consecutive presents for 74/100 at 75% threshold', () {
      final result = calculator.calculate(
        present: 74,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.requiredConsecutivePresents, 4);
      expect((74 + 4) / (100 + 4), greaterThanOrEqualTo(0.75));
      expect((74 + 3) / (100 + 3), lessThan(0.75));
    });

    test('returns 30 consecutive presents for 0/10 at 75% threshold', () {
      final result = calculator.calculate(
        present: 0,
        conducted: 10,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.requiredConsecutivePresents, 30);
      expect((0 + 30) / (10 + 30), greaterThanOrEqualTo(0.75));
      expect((0 + 29) / (10 + 29), lessThan(0.75));
    });

    test('handles 100% threshold when all present (10/10 at 100%)', () {
      final result = calculator.calculate(
        present: 10,
        conducted: 10,
        threshold: 1.0,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.requiredConsecutivePresents, 0);
      expect(result.isImpossible, isFalse);
    });

    test(
      'reports impossible when 100% threshold has an absence (9/10 at 100%)',
      () {
        final result = calculator.calculate(
          present: 9,
          conducted: 10,
          threshold: 1.0,
          calculationMethod: AttendanceCalculationMethod.rawCombined,
        );

        expect(result.isAvailable, isTrue);
        expect(result.isImpossible, isTrue);
        expect(result.requiredConsecutivePresents, isNull);
        expect(result.message, contains('cannot be reached'));
      },
    );
  });

  group('RecoveryCalculator - Component Average', () {
    test('reports scenario is required for Component Average', () {
      final result = calculator.calculate(
        present: 60,
        conducted: 100,
        threshold: 0.75,
        calculationMethod: AttendanceCalculationMethod.componentAverage,
      );

      expect(result.isAvailable, isFalse);
      expect(result.requiredConsecutivePresents, isNull);
      expect(result.requiresScenario, isTrue);
      expect(result.message, contains('distribution'));
    });
  });

  group('RecoveryCalculator - calculateGoalRecovery', () {
    test('returns not available when 0 conducted', () {
      final result = calculator.calculateGoalRecovery(
        present: 0,
        conducted: 0,
        goal: 0.85,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isFalse);
      expect(result.requiredConsecutivePresents, isNull);
      expect(result.message, contains('appears when attendance is recorded'));
    });

    test(
      'returns scenario required for component average calculation method',
      () {
        final result = calculator.calculateGoalRecovery(
          present: 10,
          conducted: 15,
          goal: 0.85,
          calculationMethod: AttendanceCalculationMethod.componentAverage,
        );

        expect(result.isAvailable, isFalse);
        expect(result.requiresScenario, isTrue);
        expect(result.message, contains('distribution'));
      },
    );

    test('returns not needed when already at or above goal', () {
      final result = calculator.calculateGoalRecovery(
        present: 9,
        conducted: 10,
        goal: 0.85,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.requiredConsecutivePresents, 0);
      expect(result.message, contains('reached your personal goal of 85%'));
    });

    test('returns impossible for 100% goal with any past absences', () {
      final result = calculator.calculateGoalRecovery(
        present: 9,
        conducted: 10,
        goal: 1.0,
        calculationMethod: AttendanceCalculationMethod.rawCombined,
      );

      expect(result.isAvailable, isTrue);
      expect(result.isImpossible, isTrue);
      expect(result.requiredConsecutivePresents, isNull);
      expect(result.message, contains('100% personal goal cannot be reached'));
    });

    test(
      'correctly computes required consecutive presents to reach 85% goal',
      () {
        // 10 / 15 = 66.67%.
        // Formula ceil((0.85 * 15 - 10) / (1 - 0.85)) = ceil((12.75 - 10) / 0.15) = ceil(2.75 / 0.15) = ceil(18.33) = 19.
        // (10 + 19) / (15 + 19) = 29 / 34 = 85.29% >= 85%.
        // (10 + 18) / (15 + 18) = 28 / 33 = 84.85% < 85%.
        final result = calculator.calculateGoalRecovery(
          present: 10,
          conducted: 15,
          goal: 0.85,
          calculationMethod: AttendanceCalculationMethod.rawCombined,
        );

        expect(result.isAvailable, isTrue);
        expect(result.isImpossible, isFalse);
        expect(result.requiredConsecutivePresents, 19);
        expect(
          result.message,
          contains(
            'Attend the next 19 consecutive classes with no absences to reach your 85% goal.',
          ),
        );
      },
    );
  });
}
