import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';

/// Represents attendance presence/absence and note status for a given calendar date.
class DayAttendanceStatus {
  const DayAttendanceStatus({
    this.hasPresent = false,
    this.hasAbsent = false,
    this.hasNote = false,
  });

  final bool hasPresent;
  final bool hasAbsent;
  final bool hasNote;

  bool get isEmpty => !hasPresent && !hasAbsent && !hasNote;

  static DayAttendanceStatus fromSessions({
    required List<AttendanceSession> sessions,
    String? note,
  }) {
    final hasPresent = sessions.any((s) => s.status == AttendanceStatus.present);
    final hasAbsent = sessions.any((s) => s.status == AttendanceStatus.absent);
    final hasNote = note != null && note.trim().isNotEmpty;
    return DayAttendanceStatus(
      hasPresent: hasPresent,
      hasAbsent: hasAbsent,
      hasNote: hasNote,
    );
  }
}

/// Shared indicator dots widget representing status of a calendar day.
///
/// Displays Mint for Present, Coral for Absent, and Blue (or White when selected) for notes.
/// If a date has both present and absent records, both indicators are displayed side-by-side.
class DayStatusDots extends StatelessWidget {
  const DayStatusDots({
    super.key,
    required this.status,
    this.isSelected = false,
    this.dotSize = 4.0,
    this.spacing = 2.0,
  });

  final DayAttendanceStatus status;
  final bool isSelected;
  final double dotSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) {
      return SizedBox(height: dotSize + 1);
    }

    final colors = context.colors;
    final accentBlue = colors.brandPrimary;

    return SizedBox(
      height: dotSize + 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (status.hasPresent)
            Container(
              width: dotSize,
              height: dotSize,
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              decoration: BoxDecoration(
                color: colors.present,
                shape: BoxShape.circle,
              ),
            ),
          if (status.hasAbsent)
            Container(
              width: dotSize,
              height: dotSize,
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              decoration: BoxDecoration(
                color: colors.absent,
                shape: BoxShape.circle,
              ),
            ),
          if (status.hasNote)
            Container(
              width: dotSize,
              height: dotSize,
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : accentBlue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
