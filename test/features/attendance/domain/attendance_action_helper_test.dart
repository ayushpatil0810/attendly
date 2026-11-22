import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/features/attendance/domain/services/attendance_action_helper.dart';

void main() {
  group('AttendanceActionHelper Tests', () {
    test('returns null when 0 sessions conducted', () {
      final result = AttendanceActionHelper.calculateActionableInsight(
        present: 0,
        conducted: 0,
        threshold: 0.75,
      );
      expect(result, isNull);
    });

    group('Above or at target threshold', () {
      test('computes safe absences buffer when comfortably above target', () {
        // 80 present out of 100 conducted at 75% target -> 6 safe absences
        final result = AttendanceActionHelper.calculateActionableInsight(
          present: 80,
          conducted: 100,
          threshold: 0.75,
        );
        expect(result, isNotNull);
        expect(result!.isAboveOrAtTarget, isTrue);
        expect(result.count, 6);
        expect(result.headlineText, 'Can miss 6 classes');
        expect(
          result.subjectSubtext,
          'Can miss 6 classes while staying at 75%',
        );
      });

      test('handles 1 safe absence singular grammar correctly', () {
        // 76 present out of 100 conducted at 75% target
        // 76 / 101 = 75.24% >= 75%; 76 / 102 = 74.5% < 75% -> 1 safe absence
        final result = AttendanceActionHelper.calculateActionableInsight(
          present: 76,
          conducted: 100,
          threshold: 0.75,
        );
        expect(result, isNotNull);
        expect(result!.isAboveOrAtTarget, isTrue);
        expect(result.count, 1);
        expect(result.headlineText, 'Can miss 1 class');
        expect(
          result.subjectSubtext,
          'Can miss 1 class while staying at 75%',
        );
      });

      test('handles exact target threshold (0 safe absences)', () {
        // 75 present out of 100 conducted at 75% target
        // Any absence drops below 75% -> 0 safe absences
        final result = AttendanceActionHelper.calculateActionableInsight(
          present: 75,
          conducted: 100,
          threshold: 0.75,
        );
        expect(result, isNotNull);
        expect(result!.isAboveOrAtTarget, isTrue);
        expect(result.count, 0);
        expect(result.headlineText, 'Can miss 0 classes');
        expect(
          result.subjectSubtext,
          'Can miss 0 classes (on track at 75%)',
        );
      });

      test('handles 100% target threshold when 100% attended', () {
        final result = AttendanceActionHelper.calculateActionableInsight(
          present: 10,
          conducted: 10,
          threshold: 1.0,
        );
        expect(result, isNotNull);
        expect(result!.isAboveOrAtTarget, isTrue);
        expect(result.count, 0);
        expect(result.headlineText, 'Can miss 0 classes');
      });
    });

    group('Below target threshold', () {
      test('computes consecutive classes needed to recover', () {
        // 6 present out of 10 conducted at 75% target (60%)
        // Needs 6 consecutive presents: (6 + 6) / (10 + 6) = 12 / 16 = 75.0%
        final result = AttendanceActionHelper.calculateActionableInsight(
          present: 6,
          conducted: 10,
          threshold: 0.75,
        );
        expect(result, isNotNull);
        expect(result!.isAboveOrAtTarget, isFalse);
        expect(result.count, 6);
        expect(result.headlineText, 'Attend next 6 classes');
        expect(
          result.subjectSubtext,
          'Attend next 6 classes to reach 75%',
        );
      });

      test('computes consecutive classes for 74% target from prompt example', () {
        // e.g. 10 present out of 16 conducted at 74% target
        // (10 + 7) / (16 + 7) = 17 / 23 = 73.91% (below)
        // (10 + 8) / (16 + 8) = 18 / 24 = 75.0% >= 74% -> 8 classes
        // Let's test with present 15, conducted 23 at 74%:
        // 0.74 * 23 = 17.02 - 15 = 2.02 / 0.26 = 7.76 -> 8
        // Let's test present: 5, conducted: 8 (62.5%) at 74% target:
        // (0.74 * 8 - 5) / (1 - 0.74) = 0.92 / 0.26 = 3.53 -> 4
        // (5 + 4) / (8 + 4) = 9 / 12 = 75% >= 74%
        final result = AttendanceActionHelper.calculateActionableInsight(
          present: 5,
          conducted: 8,
          threshold: 0.74,
        );
        expect(result, isNotNull);
        expect(result!.isAboveOrAtTarget, isFalse);
        expect(result.count, 4);
        expect(result.headlineText, 'Attend next 4 classes');
        expect(
          result.subjectSubtext,
          'Attend next 4 classes to reach 74%',
        );
      });

      test('handles 1 class recovery singular grammar correctly', () {
        // 74 present out of 100 conducted at 75% target (74%)
        // 1 present: 75 / 101 = 74.25% < 75%
        // 2 presents: 76 / 102 = 74.5%
        // Let's check 74/99 at 75%: 74/99 = 74.74%.
        // (74 + 1) / (99 + 1) = 75 / 100 = 75% -> exactly 1 class!
        final result = AttendanceActionHelper.calculateActionableInsight(
          present: 74,
          conducted: 99,
          threshold: 0.75,
        );
        expect(result, isNotNull);
        expect(result!.isAboveOrAtTarget, isFalse);
        expect(result.count, 1);
        expect(result.headlineText, 'Attend next 1 class');
        expect(
          result.subjectSubtext,
          'Attend next 1 class to reach 75%',
        );
      });

      test('handles 100% target when impossible to reach', () {
        // Past absence at 100% threshold makes 100% impossible
        final result = AttendanceActionHelper.calculateActionableInsight(
          present: 9,
          conducted: 10,
          threshold: 1.0,
        );
        expect(result, isNotNull);
        expect(result!.isAboveOrAtTarget, isFalse);
        expect(result.headlineText, 'Cannot reach 100%');
        expect(result.subjectSubtext, 'Cannot reach 100% target');
      });
    });
  });
}
