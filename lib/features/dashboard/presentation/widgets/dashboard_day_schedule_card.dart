import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../attendance/domain/entities/attendance_session.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../attendance/presentation/widgets/log_class_button.dart';
import '../../../attendance/presentation/widgets/session_form_sheet.dart';
import '../../../subjects/presentation/providers/subjects_provider.dart';

/// Dashboard card displaying the class schedule and recorded attendance sessions
/// for the selected date on the AppleWeekStrip.
class DashboardDayScheduleCard extends ConsumerWidget {
  const DashboardDayScheduleCard({
    super.key,
    required this.selectedDate,
  });

  final DateTime selectedDate;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dateKey = formatDateOnly(selectedDate);
    final sessionsAsync = ref.watch(sessionsForDateFamilyProvider(dateKey));
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);

    final subjectsMap = {
      for (final s in subjectsAsync.asData?.value ?? []) s.id: s,
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
            .isAfter(today);
    final isToday = _isSameDay(selectedDate, now);
    final title = isToday
        ? "Today's Schedule"
        : DateFormat('EEEE, MMM d').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.5,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            LogAttendanceButton(
              selectedDate: selectedDate,
              semanticLabel: 'Log attendance for $title',
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Session list or empty placeholder
        sessionsAsync.when(
          loading: () => Container(
            height: 64,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: isFuture
                      ? null
                      : () {
                          showSessionFormSheet(
                            context: context,
                            prefilledDate: selectedDate,
                          );
                        },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
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
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.surfaceSubtle.withValues(
                              alpha: colors.isDark ? 0.6 : 0.8,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: AppIcon(
                            AppIcons.calendar,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isFuture
                                    ? 'Future date'
                                    : 'No classes recorded for this date',
                                style: AppTypography.subhead.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isFuture
                                    ? 'Attendance cannot be logged in advance.'
                                    : 'Tap to quickly record a lecture or lab.',
                                style: AppTypography.footnote.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isFuture)
                          AppIcon(
                            AppIcons.caretRight,
                            size: 16,
                            color: colors.textTertiary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
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
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < sessions.length; i++) ...[
                    _DailySessionRow(
                      session: sessions[i],
                      subjectName: subjectsMap[sessions[i].subjectId]?.name ??
                          'Subject',
                      isFirst: i == 0,
                      isLast: i == sessions.length - 1,
                    ),
                    if (i < sessions.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 54,
                        endIndent: 16,
                        color: colors.divider.withValues(
                          alpha: colors.isDark ? 0.5 : 0.7,
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DailySessionRow extends StatelessWidget {
  const _DailySessionRow({
    required this.session,
    required this.subjectName,
    required this.isFirst,
    required this.isLast,
  });

  final AttendanceSession session;
  final String subjectName;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPresent = session.status == AttendanceStatus.present;
    final statusColor = isPresent ? colors.present : colors.absent;

    return Material(
      color: Colors.transparent,
      borderRadius: isFirst && isLast
          ? BorderRadius.circular(18)
          : isFirst
              ? const BorderRadius.vertical(top: Radius.circular(18))
              : isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(18))
                  : BorderRadius.zero,
      child: InkWell(
        onTap: () {
          showSessionFormSheet(
            context: context,
            sessionToEdit: session,
          );
        },
        splashColor: colors.brandPrimary.withValues(alpha: 0.08),
        highlightColor: colors.brandPrimary.withValues(alpha: 0.05),
        borderRadius: isFirst && isLast
            ? BorderRadius.circular(18)
            : isFirst
                ? const BorderRadius.vertical(top: Radius.circular(18))
                : isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(18))
                    : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Apple-inspired crisp 24dp solid filled status circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  isPresent ? AppIcons.check : AppIcons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),

              // Subject and component
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName,
                      style: AppTypography.headline.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          session.component.displayName,
                          style: AppTypography.caption1.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (session.note != null &&
                            session.note!.isNotEmpty) ...[
                          Text(
                            ' · ',
                            style: AppTypography.caption1.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              session.note!,
                              style: AppTypography.caption1.copyWith(
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing disclosure caret
              AppIcon(
                AppIcons.caretRight,
                size: 16,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
