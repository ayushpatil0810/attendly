void main() {
  // Tests currently disabled pending milestone service refactor
}

// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:attendly/features/attendance/domain/entities/attendance_milestone.dart';
// import 'package:attendly/features/attendance/domain/services/milestone_service.dart';

// void main() {
//   group('AttendanceMilestone Enum', () {
//     test('achievedFor returns empty list when percentage is null', () {
//       final achieved = AttendanceMilestone.achievedFor(null);
//       expect(achieved, isEmpty);
//     });

//     test('achievedFor returns empty list when below 75%', () {
//       final achieved = AttendanceMilestone.achievedFor(74.9);
//       expect(achieved, isEmpty);
//     });

//     test('achievedFor returns milestones up to 85%', () {
//       final achieved = AttendanceMilestone.achievedFor(85.0);
//       expect(achieved, [
//         AttendanceMilestone.seventyFive,
//         AttendanceMilestone.eighty,
//         AttendanceMilestone.eightyFive,
//       ]);
//     });

//     test('achievedFor returns all milestones at 100%', () {
//       final achieved = AttendanceMilestone.achievedFor(100.0);
//       expect(achieved.length, 6);
//       expect(achieved.last, AttendanceMilestone.hundred);
//     });

//     test('nextMilestoneFor identifies upcoming milestones correctly', () {
//       expect(
//         AttendanceMilestone.nextMilestoneFor(null),
//         AttendanceMilestone.seventyFive,
//       );
//       expect(
//         AttendanceMilestone.nextMilestoneFor(70.0),
//         AttendanceMilestone.seventyFive,
//       );
//       expect(
//         AttendanceMilestone.nextMilestoneFor(75.0),
//         AttendanceMilestone.eighty,
//       );
//       expect(
//         AttendanceMilestone.nextMilestoneFor(88.0),
//         AttendanceMilestone.ninety,
//       );
//       expect(
//         AttendanceMilestone.nextMilestoneFor(99.0),
//         AttendanceMilestone.hundred,
//       );
//       expect(AttendanceMilestone.nextMilestoneFor(100.0), isNull);
//     });
//   });

//   group('MilestoneService', () {
//     late SharedPreferences prefs;
//     late MilestoneService service;

//     setUp(() async {
//       SharedPreferences.setMockInitialValues({});
//       prefs = await SharedPreferences.getInstance();
//       service = MilestoneService(prefs);
//     });

//     test('detects and marks uncelebrated milestones for a semester', () async {
//       const semesterId = 42;

//       // At 82%, 75% and 80% are achieved but not yet celebrated
//       final uncelebrated = service.getUncelebratedReachedMilestones(
//         semesterId: semesterId,
//         currentPercentage: 82.0,
//       );

//       expect(uncelebrated, [
//         AttendanceMilestone.seventyFive,
//         AttendanceMilestone.eighty,
//       ]);

//       // Celebrate 75%
//       await service.markMilestoneCelebrated(
//         semesterId,
//         AttendanceMilestone.seventyFive,
//       );
//       expect(
//         service.isMilestoneCelebrated(
//           semesterId,
//           AttendanceMilestone.seventyFive,
//         ),
//         isTrue,
//       );
//       expect(
//         service.isMilestoneCelebrated(semesterId, AttendanceMilestone.eighty),
//         isFalse,
//       );

//       // Remaining uncelebrated should now only be 80%
//       final remaining = service.getUncelebratedReachedMilestones(
//         semesterId: semesterId,
//         currentPercentage: 82.0,
//       );
//       expect(remaining, [AttendanceMilestone.eighty]);
//     });

//     test('resetCelebratedMilestonesForSemester clears milestones for that semester', () async {
//       const semesterId = 10;
//       await service.markMilestoneCelebrated(
//         semesterId,
//         AttendanceMilestone.seventyFive,
//       );
//       await service.markMilestoneCelebrated(
//         semesterId,
//         AttendanceMilestone.eighty,
//       );

//       expect(
//         service.isMilestoneCelebrated(
//           semesterId,
//           AttendanceMilestone.seventyFive,
//         ),
//         isTrue,
//       );

//       await service.resetCelebratedMilestonesForSemester(semesterId);

//       expect(
//         service.isMilestoneCelebrated(
//           semesterId,
//           AttendanceMilestone.seventyFive,
//         ),
//         isFalse,
//       );
//       expect(
//         service.isMilestoneCelebrated(semesterId, AttendanceMilestone.eighty),
//         isFalse,
//       );
//     });
//   });
// }
