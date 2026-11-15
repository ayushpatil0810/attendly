import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:intl/intl.dart';

class AttendanceCalendar extends ConsumerWidget {
  const AttendanceCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final sessionsAsync = ref.watch(sessionsForMonthProvider);

    final sessionsByDate = <String, List<AttendanceSession>>{};
    sessionsAsync.whenData((sessions) {
      for (final s in sessions) {
        sessionsByDate.putIfAbsent(s.sessionDate, () => []).add(s);
      }
    });

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
        color: AppColors.pureWhite,
        borderRadius: AppRadius.xlBorder,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month navigation header
          Row(
            children: [
              IconButton(
                icon: const AppIcon(
                  AppIcons.back,
                  size: 20,
                  color: AppColors.ink,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  ref.read(currentMonthProvider.notifier).previousMonth();
                },
              ),
              Expanded(
                child: Text(
                  monthTitle,
                  style: AppTypography.itemTitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const AppIcon(
                  AppIcons.forward,
                  size: 20,
                  color: AppColors.ink,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  ref.read(currentMonthProvider.notifier).nextMonth();
                },
              ),
              if (!isCurrentMonth)
                TextButton(
                  onPressed: () {
                    ref.read(currentMonthProvider.notifier).currentMonth();
                    ref.read(selectedDateProvider.notifier).selectToday();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(40, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Today',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.brandViolet,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                return const Expanded(child: SizedBox(height: 38));
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

              return Expanded(
                child: _CalendarDayCell(
                  dayNumber: dayNumber,
                  isToday: isToday,
                  isSelected: isSelected,
                  isFuture: isFuture,
                  hasPresent: hasPresent,
                  hasAbsent: hasAbsent,
                  onTap: isFuture
                      ? null
                      : () {
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
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.mutedInk,
            fontWeight: FontWeight.w600,
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
    required this.onTap,
  });

  final int dayNumber;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final bool hasPresent;
  final bool hasAbsent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (isFuture) {
      textColor = AppColors.divider;
    } else if (isSelected) {
      textColor = AppColors.pureWhite;
    } else if (isToday) {
      textColor = AppColors.brandViolet;
    } else {
      textColor = AppColors.ink;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Number container
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandViolet
                    : isToday
                    ? AppColors.softLavender
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.brandViolet, width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$dayNumber',
                style: AppTypography.bodySmall.copyWith(
                  color: textColor,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 2),

            // Indicator dots: Mint for present, Coral for absent.
            // When no records exist: completely clean! Never show red for unrecorded.
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
                      decoration: const BoxDecoration(
                        color: AppColors.brandMint,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasAbsent)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        color: AppColors.brandCoral,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
