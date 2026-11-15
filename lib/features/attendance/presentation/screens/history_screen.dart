import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/attendance/presentation/widgets/attendance_calendar.dart';
import 'package:attendly/features/attendance/presentation/widgets/delete_session_dialog.dart';
import 'package:attendly/features/attendance/presentation/widgets/session_form_sheet.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final formattedSelectedDate = DateFormat('EEEE, d MMMM yyyy')
        .format(selectedDate);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.screenTop,
            bottom: AppSpacing.dockClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen header
              const Text('History', style: AppTypography.screenTitle),
              const SizedBox(height: 4),
              Text(
                'Calendar & Attendance Timeline',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutedInk,
                ),
              ),
              const SizedBox(height: 20),

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
                      style: AppTypography.sectionTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Add Session',
                    icon: const AppIcon(
                      AppIcons.add,
                      size: 16,
                      color: AppColors.pureWhite,
                    ),
                    variant: AppButtonVariant.primary,
                    onPressed: () {
                      showSessionFormSheet(
                        context: context,
                        prefilledDate: selectedDate,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Session list for selected date
              sessionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandViolet,
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
                    return const _NoSessionsPlaceholder();
                  }

                  return Column(
                    children: sessions.map((session) {
                      final subject = subjectsMap[session.subjectId];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SessionCard(
                          session: session,
                          subjectName: subject?.name ?? 'Subject',
                          onEdit: () {
                            showSessionFormSheet(
                              context: context,
                              sessionToEdit: session,
                            );
                          },
                          onDelete: () async {
                            final confirmed = await showDeleteSessionDialog(
                              context: context,
                              subjectName: subject?.name ?? 'Subject',
                              componentName: session.component.displayName,
                              date: session.sessionDate,
                            );

                            if (confirmed == true && context.mounted) {
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
                            }
                          },
                        ),
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
  const _NoSessionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.softLavender,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const AppIcon(
              AppIcons.calendar,
              size: 24,
              color: AppColors.brandViolet,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No sessions recorded for this date',
            style: AppTypography.itemTitle.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Classes not entered are unrecorded and never treated as absences.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
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
    final isPresent = session.status == AttendanceStatus.present;
    final statusColor = isPresent
        ? AppColors.inkMint
        : AppColors.inkCoral;
    final statusBg = isPresent ? AppColors.softMint : AppColors.softCoral;

    final semanticLabel = StringBuffer(session.status.displayName)
      ..write(' session for ')
      ..write(subjectName)
      ..write(', ')
      ..write(session.component.displayName);
    if (session.note != null && session.note!.isNotEmpty) {
      semanticLabel.write('. Note: ${session.note}');
    }

    return Semantics(
      container: true,
      label: semanticLabel.toString(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.lgBorder,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status indicator pill with high contrast
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: AppRadius.mdBorder,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    isPresent ? AppIcons.check : AppIcons.close,
                    size: 15,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    session.status.displayName,
                    style: AppTypography.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Subject & component info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectName,
                    style: AppTypography.itemTitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        session.component.displayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (session.note != null && session.note!.isNotEmpty) ...[
                        Text(
                          ' · ',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.mutedInk,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            session.note!,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.mutedInk,
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

            // Edit button (comfortable 44x44 touch target, muted color)
            IconButton(
              key: Key('edit_session_${session.id}'),
              tooltip: 'Edit session',
              icon: const AppIcon(
                AppIcons.edit,
                size: 18,
                color: AppColors.mutedInk,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: onEdit,
            ),

            // Delete button (comfortable 44x44 touch target, muted color)
            IconButton(
              key: Key('delete_session_${session.id}'),
              tooltip: 'Delete session',
              icon: const AppIcon(
                AppIcons.delete,
                size: 18,
                color: AppColors.mutedInk,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
