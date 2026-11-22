import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/attendance/presentation/widgets/attendance_calendar.dart';
import 'package:attendly/features/attendance/presentation/widgets/day_note_banner.dart';
import 'package:attendly/features/attendance/presentation/widgets/log_class_button.dart';
import 'package:attendly/features/attendance/presentation/widgets/session_form_sheet.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final selectedDate = ref.watch(selectedDateProvider);
    final sessionsAsync = ref.watch(sessionsForSelectedDateProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);

    final subjectsMap = <int, Subject>{};
    subjectsAsync.whenData((subjects) {
      for (final s in subjects) {
        subjectsMap[s.id] = s;
      }
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = selectedDate.isAtSameMomentAs(today);
    final isFuture = selectedDate.isAfter(today);
    final formattedSelectedDate = DateFormat('EEEE, d MMMM yyyy')
        .format(selectedDate);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.screenTop,
            bottom: AppSpacing.safeDockClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen header
              Text(
                'History',
                style: AppTypography.title1.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Calendar & Attendance Timeline',
                style: AppTypography.footnote.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Calendar widget
              const AttendanceCalendar(),
              const SizedBox(height: 24),

              // Selected Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      isToday
                          ? 'Today, ${DateFormat('d MMMM yyyy').format(selectedDate)}'
                          : formattedSelectedDate,
                      style: AppTypography.headline.copyWith(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  LogAttendanceButton(
                    selectedDate: selectedDate,
                    semanticLabel: 'Log attendance for ${isToday ? 'Today' : formattedSelectedDate}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DayNoteBanner(dateStr: formatDateOnly(selectedDate)),
              const SizedBox(height: 14),

              // Session list for selected date
              sessionsAsync.when(
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colors.brandPrimary,
                    ),
                  ),
                ),
                error: (err, _) => AppErrorState(
                  message: 'Sessions for this day could not load.',
                  onRetry: () =>
                      ref.invalidate(sessionsForSelectedDateProvider),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return _NoSessionsPlaceholder(isFuture: isFuture);
                  }

                  return AppleInsetGroup(
                    margin: EdgeInsets.zero,
                    dividerIndent: 60.0,
                    children: sessions.map((session) {
                      final subject = subjectsMap[session.subjectId];
                      return _SessionTile(
                        key: ValueKey(session.id),
                        session: session,
                        subjectName: subject?.name ?? 'Subject',
                        onEdit: () {
                          showSessionFormSheet(
                            context: context,
                            sessionToEdit: session,
                          );
                        },
                        onDelete: () async {
                          try {
                            await ref
                                .read(attendanceControllerProvider.notifier)
                                .deleteSession(session);

                            if (context.mounted) {
                              AppToast.showSuccess(
                                context,
                                message: 'Session deleted',
                                actionLabel: 'Undo',
                                onAction: () async {
                                  await ref
                                      .read(
                                        attendanceControllerProvider
                                            .notifier,
                                      )
                                      .undo();
                                  if (context.mounted) {
                                    AppToast.showInfo(
                                      context,
                                      message: 'Session restored',
                                    );
                                  }
                                },
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.showError(
                                context,
                                message: e is AppFailure
                                    ? e.message
                                    : 'The session could not be deleted. Try again.',
                              );
                            }
                          }
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSessionsPlaceholder extends StatelessWidget {
  const _NoSessionsPlaceholder({this.isFuture = false});

  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppleInsetGroup(
      margin: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  AppIcons.calendar,
                  size: 26,
                  color: colors.textTertiary,
                ),
                const SizedBox(height: 10),
                Text(
                  isFuture
                      ? 'Future date'
                      : 'No sessions recorded for this date',
                  style: AppTypography.subhead.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  isFuture
                      ? 'Attendance cannot be logged in advance.'
                      : 'Classes not entered are unrecorded and never treated as absences.',
                  style: AppTypography.footnote.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    super.key,
    required this.session,
    required this.subjectName,
    required this.onEdit,
    required this.onDelete,
  });

  final AttendanceSession session;
  final String subjectName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPresent = session.status == AttendanceStatus.present;
    final statusColor = isPresent ? colors.present : colors.absent;

    final semanticLabel = StringBuffer(session.status.displayName)
      ..write(' session for ')
      ..write(subjectName)
      ..write(', ')
      ..write(session.component.displayName);
    if (session.note != null && session.note!.isNotEmpty) {
      semanticLabel.write('. Note: ${session.note}');
    }
    semanticLabel.write('. Tap to edit, swipe left to delete.');

    return Dismissible(
      key: Key('session_dismissible_${session.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: colors.absent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(
              AppIcons.delete,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              'Delete',
              style: AppTypography.subhead.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async => true,
      onDismissed: (_) => onDelete(),
      child: Semantics(
        container: true,
        button: true,
        label: semanticLabel.toString(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('session_tile_${session.id}'),
            onTap: onEdit,
            splashColor: colors.brandPrimary.withValues(alpha: 0.08),
            highlightColor: colors.brandPrimary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
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

                  // Subject & component info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          style: AppTypography.subhead.copyWith(
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
                                fontWeight: FontWeight.w500,
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

                  const SizedBox(width: 8),

                  // Subtle disclosure chevron indicating tappability for editing
                  AppIcon(
                    AppIcons.caretRight,
                    size: 18,
                    color: colors.textTertiary.withValues(
                      alpha: colors.isDark ? 0.6 : 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
