import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:intl/intl.dart';

class AttendanceCalendar extends ConsumerWidget {
  const AttendanceCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentMonth = ref.watch(currentMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final sessionsAsync = ref.watch(sessionsForMonthProvider);
    final dayNotesAsync = ref.watch(dayNotesForMonthProvider);

    final sessionsByDate = <String, List<AttendanceSession>>{};
    sessionsAsync.whenData((sessions) {
      for (final s in sessions) {
        sessionsByDate.putIfAbsent(s.sessionDate, () => []).add(s);
      }
    });

    final dayNotesMap = dayNotesAsync.value ?? {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isCurrentMonth =
        currentMonth.year == now.year && currentMonth.month == now.month;

    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      currentMonth.year,
      currentMonth.month,
      1,
    ).weekday; // 1 = Monday, 7 = Sunday

    final monthTitle = DateFormat('MMMM yyyy').format(currentMonth);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.border.withValues(
            alpha: colors.isDark ? 0.4 : 0.6,
          ),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: colors.isDark ? 0.25 : 0.03,
            ),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month navigation header
          Row(
            children: [
              Expanded(
                child: Text(
                  monthTitle,
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (!isCurrentMonth) ...[
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(currentMonthProvider.notifier).currentMonth();
                    ref.read(selectedDateProvider.notifier).selectToday();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: const Size(44, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Today',
                    style: AppTypography.subhead.copyWith(
                      color: colors.isDark
                          ? const Color(0xFF5E81F4)
                          : const Color(0xFF3F5BF6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                tooltip: 'Previous month',
                icon: AppIcon(
                  AppIcons.back,
                  size: 19,
                  color: colors.textPrimary,
                  semanticLabel: 'Previous month',
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(currentMonthProvider.notifier).previousMonth();
                },
              ),
              IconButton(
                tooltip: 'Next month',
                icon: AppIcon(
                  AppIcons.forward,
                  size: 19,
                  color: colors.textPrimary,
                  semanticLabel: 'Next month',
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(currentMonthProvider.notifier).nextMonth();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday headers (Mon - Sun)
          const Row(
            children: [
              _WeekdayHeader('M'),
              _WeekdayHeader('T'),
              _WeekdayHeader('W'),
              _WeekdayHeader('T'),
              _WeekdayHeader('F'),
              _WeekdayHeader('S'),
              _WeekdayHeader('S'),
            ],
          ),
          const SizedBox(height: 8),

          // Calendar days grid
          _buildMonthGrid(
            context,
            ref,
            daysInMonth: daysInMonth,
            firstWeekday: firstWeekday,
            currentMonth: currentMonth,
            selectedDate: selectedDate,
            today: today,
            sessionsByDate: sessionsByDate,
            dayNotesMap: dayNotesMap,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    WidgetRef ref, {
    required int daysInMonth,
    required int firstWeekday,
    required DateTime currentMonth,
    required DateTime selectedDate,
    required DateTime today,
    required Map<String, List<AttendanceSession>> sessionsByDate,
    required Map<String, String> dayNotesMap,
  }) {
    // Offset for Monday-based week: 1 (Mon) -> 0 blanks, 7 (Sun) -> 6 blanks
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rowsCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowsCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - leadingBlanks + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 48));
              }

              final cellDate = DateTime(
                currentMonth.year,
                currentMonth.month,
                dayNumber,
              );
              final isToday = cellDate.isAtSameMomentAs(today);
              final isSelected = cellDate.isAtSameMomentAs(selectedDate);
              final isFuture = cellDate.isAfter(today);

              final dateKey = formatDateOnly(cellDate);
              final sessionsForDay = sessionsByDate[dateKey] ?? [];

              final hasPresent = sessionsForDay.any(
                (s) => s.status == AttendanceStatus.present,
              );
              final hasAbsent = sessionsForDay.any(
                (s) => s.status == AttendanceStatus.absent,
              );
              final hasNote =
                  dayNotesMap.containsKey(dateKey) &&
                  (dayNotesMap[dateKey]?.trim().isNotEmpty ?? false);

              return Expanded(
                child: _CalendarDayCell(
                  dayNumber: dayNumber,
                  isToday: isToday,
                  isSelected: isSelected,
                  isFuture: isFuture,
                  hasPresent: hasPresent,
                  hasAbsent: hasAbsent,
                  hasNote: hasNote,
                  onTap: isFuture
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(selectedDateProvider.notifier)
                              .selectDate(cellDate);
                        },
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: Center(
        child: Text(
          text,
          style: AppTypography.caption1.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.dayNumber,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.hasPresent,
    required this.hasAbsent,
    required this.hasNote,
    required this.onTap,
  });

  final int dayNumber;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final bool hasPresent;
  final bool hasAbsent;
  final bool hasNote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentBlue = colors.isDark
        ? const Color(0xFF4A6BF7)
        : const Color(0xFF3F5BF6);

    Color textColor;
    if (isFuture) {
      textColor = colors.textTertiary;
    } else if (isSelected) {
      textColor = Colors.white;
    } else if (isToday) {
      textColor = accentBlue;
    } else {
      textColor = colors.textPrimary;
    }

    final noteText = hasNote ? ', Has note' : '';
    final statusText = hasPresent && hasAbsent
        ? ', Present and Absent recorded'
        : hasPresent
        ? ', Present recorded'
        : hasAbsent
        ? ', Absent recorded'
        : ', No sessions recorded';

    return Semantics(
      button: !isFuture,
      selected: isSelected,
      label: 'Day $dayNumber$statusText$noteText',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Number container
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentBlue
                      : isToday
                      ? accentBlue.withValues(alpha: 0.12)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: accentBlue, width: 1.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dayNumber',
                  style: AppTypography.footnote.copyWith(
                    color: textColor,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),

              // Indicator dots: Mint for present, Coral for absent, Blue for note.
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasPresent)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: colors.accentMint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasAbsent)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: colors.accentCoral,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasNote)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: accentBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
