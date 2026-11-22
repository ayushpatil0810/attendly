import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../../features/attendance/presentation/widgets/day_status_dots.dart';

/// Horizontal week strip inspired by Apple Calendar and Health routines.
///
/// Displays a 7-day strip (Sun–Sat) with short day initials and day
/// numbers, highlighting the selected date with a vibrant rounded capsule.
class AppleWeekStrip extends StatelessWidget {
  const AppleWeekStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.startDate,
    this.markedDates,
    this.dayDotColorBuilder,
    this.dayStatusBuilder,
    this.startWithMonday = true,
    this.now,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? startDate;
  final Set<DateTime>? markedDates;
  final Color? Function(DateTime date)? dayDotColorBuilder;
  final DayAttendanceStatus? Function(DateTime date)? dayStatusBuilder;
  final bool startWithMonday;
  final DateTime? now;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime> _generateWeekDays() {
    final base = startDate ?? selectedDate;
    if (startWithMonday) {
      // Align to Monday as week start (matching academic schedule and AttendanceCalendar)
      final diff = base.weekday - 1; // Mon = 1 -> 0; Sun = 7 -> 6
      final monday = DateTime(base.year, base.month, base.day).subtract(Duration(days: diff));
      return List.generate(7, (index) => monday.add(Duration(days: index)));
    } else {
      final diff = base.weekday % 7; // Sunday = 7 % 7 = 0; Mon = 1; Sat = 6
      final sunday = DateTime(base.year, base.month, base.day).subtract(Duration(days: diff));
      return List.generate(7, (index) => sunday.add(Duration(days: index)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final weekDays = _generateWeekDays();
    final effectiveNow = now ?? DateTime.now();
    final today =
        DateTime(effectiveNow.year, effectiveNow.month, effectiveNow.day);

    return Semantics(
      container: true,
      label: 'Week calendar day selector',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays.map((date) {
            final cellDate = DateTime(date.year, date.month, date.day);
            final isFuture = cellDate.isAfter(today);
            final isToday = _isSameDay(date, effectiveNow);
            final isSelected = !isFuture && _isSameDay(date, selectedDate);
            final dayInitial = DateFormat('E').format(date); // Sun, Mon, etc.
            final dayNumber = DateFormat('d').format(date);

            // Active pill background color
            final activeBg = colors.brandPrimary;

            Color initialColor;
            Color numberColor;
            if (isFuture) {
              initialColor = colors.textTertiary;
              numberColor = colors.textTertiary;
            } else if (isSelected) {
              initialColor = Colors.white.withValues(alpha: 0.90);
              numberColor = Colors.white;
            } else if (isToday) {
              initialColor = colors.textSecondary;
              numberColor = colors.brandPrimary;
            } else {
              initialColor = colors.textSecondary;
              numberColor = colors.textPrimary;
            }

            Color? dotColor;
            if (isFuture) {
              dotColor = null;
            } else if (dayDotColorBuilder != null) {
              dotColor = dayDotColorBuilder!(date);
            } else if (markedDates != null &&
                markedDates!.any((d) => _isSameDay(d, date))) {
              dotColor = colors.accentGreen;
            }

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Semantics(
                  button: !isFuture,
                  selected: isSelected,
                  label:
                      '$dayInitial $dayNumber${isToday ? ", today" : (isFuture ? ", future date" : "")}',
                  child: InkWell(
                    onTap: isFuture
                        ? null
                        : () {
                            onDateSelected(date);
                          },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? activeBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayInitial,
                            style: AppTypography.caption1.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: initialColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dayNumber,
                            style: AppTypography.headline.copyWith(
                              fontSize: 16,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: numberColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isFuture)
                            const SizedBox(height: 4.5)
                          else if (dayStatusBuilder != null)
                            DayStatusDots(
                              status: dayStatusBuilder!(date) ??
                                  const DayAttendanceStatus(),
                              isSelected: isSelected,
                              dotSize: 4.5,
                              spacing: 2.0,
                            )
                          else
                            Container(
                              width: 4.5,
                              height: 4.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dotColor != null
                                    ? (isSelected ? Colors.white : dotColor)
                                    : Colors.transparent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
