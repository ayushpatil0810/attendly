import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../attendance/domain/entities/attendance_session.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
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

    final isToday = _isSameDay(selectedDate, DateTime.now());
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
            Semantics(
              button: true,
              label: 'Log class for $title',
              child: Material(
                color: colors.surfaceSubtle.withValues(
                  alpha: colors.isDark ? 0.6 : 0.8,
                ),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showSessionFormSheet(
                      context: context,
                      prefilledDate: selectedDate,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.border.withValues(
                          alpha: colors.isDark ? 0.4 : 0.6,
                        ),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                          AppIcons.add,
                          size: 14,
                          color: colors.isDark
                              ? const Color(0xFF5E81F4)
                              : const Color(0xFF3F5BF6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Log Class',
                          style: AppTypography.caption1.copyWith(
                            color: colors.isDark
                                ? const Color(0xFF5E81F4)
                                : const Color(0xFF3F5BF6),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                  onTap: () {
                    HapticFeedback.selectionClick();
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
                                'No classes recorded for this date',
                                style: AppTypography.subhead.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to quickly record a lecture or lab.',
                                style: AppTypography.footnote.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppIcon(
                          AppIcons.forward,
                          size: 14,
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
                        indent: 56,
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
          HapticFeedback.selectionClick();
          showSessionFormSheet(
            context: context,
            sessionToEdit: session,
          );
        },
        borderRadius: isFirst && isLast
            ? BorderRadius.circular(18)
            : isFirst
                ? const BorderRadius.vertical(top: Radius.circular(18))
                : isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(18))
                    : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Squircle / Circle status badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color:
                      isPresent ? colors.accentMintSoft : colors.accentCoralSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  isPresent ? AppIcons.check : AppIcons.close,
                  size: 16,
                  color: isPresent ? colors.accentMint : colors.accentCoral,
                ),
              ),
              const SizedBox(width: 12),

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
                AppIcons.forward,
                size: 14,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
