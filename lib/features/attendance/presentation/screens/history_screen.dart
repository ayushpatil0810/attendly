import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
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
              const Text(
                'Calendar & Attendance Timeline',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),

              // Calendar widget
              const AttendanceCalendar(),
              const SizedBox(height: 24),

              // Selected Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? 'Today' : 'Selected Date',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.brandViolet,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedSelectedDate,
                          style: AppTypography.sectionTitle.copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Failed to load sessions: $err',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.brandCoral,
                    ),
                  ),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return _NoSessionsPlaceholder(
                      onAddSession: () {
                        showSessionFormSheet(
                          context: context,
                          prefilledDate: selectedDate,
                        );
                      },
                    );
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
                                        : 'Failed to delete session',
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
  const _NoSessionsPlaceholder({required this.onAddSession});

  final VoidCallback onAddSession;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.track,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const AppIcon(
              AppIcons.calendar,
              size: 22,
              color: AppColors.mutedInk,
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
          const SizedBox(height: 16),
          AppButton(
            label: 'Record Session',
            icon: const AppIcon(AppIcons.add, size: 16, color: AppColors.ink),
            variant: AppButtonVariant.outline,
            onPressed: onAddSession,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status indicator pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPresent ? AppColors.softMint : AppColors.softCoral,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: isPresent
                    ? AppColors.brandMint.withValues(alpha: 0.5)
                    : AppColors.brandCoral.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  isPresent ? AppIcons.check : AppIcons.close,
                  size: 16,
                  color: isPresent ? AppColors.ink : AppColors.brandCoral,
                ),
                const SizedBox(width: 4),
                Text(
                  session.status.displayName,
                  style: AppTypography.labelSmall.copyWith(
                    color: isPresent ? AppColors.ink : AppColors.brandCoral,
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.softLavender,
                        borderRadius: AppRadius.smBorder,
                      ),
                      child: Text(
                        session.component.displayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandViolet,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (session.note != null && session.note!.isNotEmpty) ...[
                      const SizedBox(width: 8),
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

          // Edit button
          IconButton(
            key: Key('edit_session_${session.id}'),
            icon: const AppIcon(AppIcons.edit, size: 18, color: AppColors.ink),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onEdit,
          ),

          // Delete button
          IconButton(
            key: Key('delete_session_${session.id}'),
            icon: const AppIcon(
              AppIcons.delete,
              size: 18,
              color: AppColors.brandCoral,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
