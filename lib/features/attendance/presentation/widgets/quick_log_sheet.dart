import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/attendance/presentation/widgets/attendance_action_button.dart';
import 'package:attendly/features/attendance/presentation/widgets/day_note_banner.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

class QuickLogSheet extends ConsumerStatefulWidget {
  const QuickLogSheet({
    super.key,
    this.initialDate,
    this.initialSubjectId,
    this.onlySubjectId,
    this.title,
  });

  final DateTime? initialDate;
  final int? initialSubjectId;
  final int? onlySubjectId;
  final String? title;

  @override
  ConsumerState<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<QuickLogSheet> {
  late DateTime _selectedDate;
  final Set<String> _inFlightKeys = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = widget.initialDate;
    _selectedDate = (initial != null && !initial.isAfter(today))
        ? initial
        : today;
  }

  Future<void> _selectDate() async {
    final colors = context.colors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedDate.isAfter(today) ? today : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: today,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: colors.isDark
                ? ColorScheme.dark(
                    primary: colors.brandPrimary,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: colors.brandPrimary,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _recordAttendance(
    Subject subject,
    SessionComponent component,
    AttendanceStatus status,
  ) async {
    final key = '${subject.id}_${component.name}_${status.name}';
    if (_inFlightKeys.contains(key)) return;

    setState(() => _inFlightKeys.add(key));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).isAfter(today)) {
      if (mounted) {
        setState(() => _inFlightKeys.remove(key));
        AppToast.showError(context, message: 'Cannot log attendance for future dates.');
      }
      return;
    }
    final dateStr = formatDateOnly(_selectedDate);

    try {
      await ref
          .read(attendanceControllerProvider.notifier)
          .recordSession(
            subjectId: subject.id,
            sessionDate: dateStr,
            component: component,
            status: status,
          );

      if (!mounted) return;

      final statusLabel = status == AttendanceStatus.present
          ? 'Present'
          : 'Absent';
      final componentLabel = component.displayName;

      AppToast.showSuccess(
        context,
        message: 'Marked $statusLabel for ${subject.name} ($componentLabel)',
        actionLabel: 'Undo',
        onAction: () async {
          await ref.read(attendanceControllerProvider.notifier).undo();
          if (mounted) {
            AppToast.showInfo(context, message: 'Attendance entry undone.');
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        message: e is AppFailure ? e.message : 'Could not save attendance.',
      );
    } finally {
      if (mounted) {
        setState(() => _inFlightKeys.remove(key));
      }
    }
  }

  Future<void> _deleteSession(
    AttendanceSession session,
    String subjectName,
  ) async {
    final key = 'delete_${session.id}';
    if (_inFlightKeys.contains(key)) return;

    setState(() => _inFlightKeys.add(key));
    try {
      await ref
          .read(attendanceControllerProvider.notifier)
          .deleteSession(session);

      if (!mounted) return;
      AppToast.showInfo(
        context,
        message: 'Removed ${session.component.displayName} for $subjectName',
        actionLabel: 'Undo',
        onAction: () async {
          await ref.read(attendanceControllerProvider.notifier).undo();
          if (mounted) {
            AppToast.showInfo(context, message: 'Restored session.');
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        message: e is AppFailure ? e.message : 'Could not delete session.',
      );
    } finally {
      if (mounted) {
        setState(() => _inFlightKeys.remove(key));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final dateStr = formatDateOnly(_selectedDate);
    final isToday = dateStr == formatDateOnly(DateTime.now());
    final formattedDate = DateFormat('EEE, d MMM').format(_selectedDate);
    final sessionsForDateAsync = ref.watch(
      sessionsForDateFamilyProvider(dateStr),
    );

    final isSingleSubject = widget.onlySubjectId != null;

    final body = subjectsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colors.brandPrimary),
      ),
      error: (err, _) => Center(
        child: AppErrorState(
          message: 'Subjects could not load.',
          onRetry: () => ref.invalidate(activeSemesterSubjectsProvider),
        ),
      ),
      data: (subjects) {
        if (subjects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.accentOrange.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(
                    AppIcons.subjects,
                    size: 28,
                    color: colors.accentOrange,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No subjects found',
                  style: AppTypography.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please add subjects to your semester before logging attendance.',
                  style: AppTypography.bodyMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Close',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }

        // Filter or sort subjects
        final List<Subject> displayedSubjects;
        if (widget.onlySubjectId != null) {
          displayedSubjects = subjects
              .where((s) => s.id == widget.onlySubjectId)
              .toList();
        } else {
          displayedSubjects = [...subjects];
          if (widget.initialSubjectId != null) {
            final idx = displayedSubjects.indexWhere(
              (s) => s.id == widget.initialSubjectId,
            );
            if (idx > 0) {
              final target = displayedSubjects.removeAt(idx);
              displayedSubjects.insert(0, target);
            }
          }
        }

        if (displayedSubjects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.accentOrange.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(
                    AppIcons.subjects,
                    size: 28,
                    color: colors.accentOrange,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Subject not found',
                  style: AppTypography.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'The selected subject is not available in the current semester.',
                  style: AppTypography.bodyMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Close',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }

        final sessions = sessionsForDateAsync.value ?? [];
        final int totalLoggedOnDate;
        if (widget.onlySubjectId != null) {
          final targetSessions = sessions.where(
            (s) => s.subjectId == widget.onlySubjectId,
          );
          totalLoggedOnDate = targetSessions.length;
        } else {
          totalLoggedOnDate = sessions.length;
        }

        // Group sessions by subjectId and component
        final sessionsBySubjectAndComponent =
            <int, Map<SessionComponent, List<AttendanceSession>>>{};
        for (final s in sessions) {
          sessionsBySubjectAndComponent
              .putIfAbsent(s.subjectId, () => {})
              .putIfAbsent(s.component, () => [])
              .add(s);
        }

        return Column(
          mainAxisSize: isSingleSubject
              ? MainAxisSize.min
              : MainAxisSize.max,
          children: [
            // Distilled Date Strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label:
                        'Change attendance date, currently $formattedDate',
                    child: InkWell(
                      onTap: _selectDate,
                      borderRadius: AppRadius.smBorder,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              AppIcons.calendar,
                              size: 15,
                              color: colors.brandPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isToday
                                  ? 'Today ($formattedDate)'
                                  : formattedDate,
                              style: AppTypography.itemTitle.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AppIcon(
                              AppIcons.arrowDown,
                              size: 13,
                              color: colors.brandPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (totalLoggedOnDate > 0)
                    Text(
                      totalLoggedOnDate == 1
                          ? '1 class logged'
                          : '$totalLoggedOnDate classes logged',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Day Note Banner / Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DayNoteBanner(dateStr: dateStr, isCompact: true),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.divider),

            // Vertical Subject List or Single Subject Card
            if (isSingleSubject)
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final subject in displayedSubjects) ...[
                        Builder(
                          builder: (context) {
                            final subjectSessions =
                                sessionsBySubjectAndComponent[subject.id] ?? {};
                            final lectureSessions =
                                subjectSessions[SessionComponent.lecture] ?? [];
                            final labSessions =
                                subjectSessions[SessionComponent.lab] ?? [];
                            final totalSubjectCount =
                                lectureSessions.length + labSessions.length;

                            return _SubjectLogCard(
                              key: ValueKey(subject.id),
                              subject: subject,
                              isInitial: false,
                              lectureSessions: lectureSessions,
                              labSessions: labSessions,
                              totalCount: totalSubjectCount,
                              inFlightKeys: _inFlightKeys,
                              onRecord: _recordAttendance,
                              onDeleteSession: _deleteSession,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  itemCount: displayedSubjects.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final subject = displayedSubjects[index];
                    final isInitial = subject.id == widget.initialSubjectId;
                    final subjectSessions =
                        sessionsBySubjectAndComponent[subject.id] ?? {};

                    final lectureSessions =
                        subjectSessions[SessionComponent.lecture] ?? [];
                    final labSessions =
                        subjectSessions[SessionComponent.lab] ?? [];
                    final totalSubjectCount =
                        lectureSessions.length + labSessions.length;

                    return _SubjectLogCard(
                      key: ValueKey(subject.id),
                      subject: subject,
                      isInitial: isInitial,
                      lectureSessions: lectureSessions,
                      labSessions: labSessions,
                      totalCount: totalSubjectCount,
                      inFlightKeys: _inFlightKeys,
                      onRecord: _recordAttendance,
                      onDeleteSession: _deleteSession,
                    );
                  },
                ),
              ),

            // Bottom Sticky Done Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.divider)),
              ),
              child: AppButton(
                label: 'Done',
                size: AppButtonSize.large,
                isFullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );

    return Column(
      mainAxisSize: isSingleSubject
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: [
        // Drag Handle
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: colors.divider,
            borderRadius: AppRadius.pillBorder,
          ),
        ),
        const SizedBox(height: 12),

        // Header Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title ?? 'Log Attendance',
                  style: AppTypography.sectionTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              AppCloseButton(onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
        const SizedBox(height: 8),

        isSingleSubject ? Flexible(child: body) : Expanded(child: body),
      ],
    );
  }
}

class _SubjectLogCard extends StatelessWidget {
  const _SubjectLogCard({
    super.key,
    required this.subject,
    required this.isInitial,
    required this.lectureSessions,
    required this.labSessions,
    required this.totalCount,
    required this.inFlightKeys,
    required this.onRecord,
    required this.onDeleteSession,
  });

  final Subject subject;
  final bool isInitial;
  final List<AttendanceSession> lectureSessions;
  final List<AttendanceSession> labSessions;
  final int totalCount;
  final Set<String> inFlightKeys;
  final void Function(Subject, SessionComponent, AttendanceStatus) onRecord;
  final void Function(AttendanceSession, String) onDeleteSession;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInitial
              ? colors.brandPrimary
              : colors.border.withValues(alpha: colors.isDark ? 0.5 : 0.7),
          width: isInitial ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Subject Name & Total Count
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    subject.name,
                    style: AppTypography.headline.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle.withValues(
                        alpha: colors.isDark ? 0.6 : 0.8,
                      ),
                      borderRadius: AppRadius.pillBorder,
                      border: Border.all(
                        color: colors.border.withValues(
                          alpha: colors.isDark ? 0.4 : 0.6,
                        ),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      totalCount == 1 ? '1 logged' : '$totalCount logged',
                      style: AppTypography.caption2.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: colors.divider.withValues(alpha: colors.isDark ? 0.4 : 0.7),
          ),

          // Component rows
          if (subject.lectureEnabled)
            _CompactComponentRow(
              key: ValueKey('${subject.id}_${SessionComponent.lecture.name}'),
              subject: subject,
              component: SessionComponent.lecture,
              sessions: lectureSessions,
              inFlightKeys: inFlightKeys,
              onRecord: onRecord,
              onDeleteSession: onDeleteSession,
            ),

          if (subject.hasBothComponents)
            Divider(
              height: 0.5,
              thickness: 0.5,
              indent: 14,
              endIndent: 14,
              color: colors.divider.withValues(alpha: colors.isDark ? 0.3 : 0.5),
            ),

          if (subject.labEnabled)
            _CompactComponentRow(
              key: ValueKey('${subject.id}_${SessionComponent.lab.name}'),
              subject: subject,
              component: SessionComponent.lab,
              sessions: labSessions,
              inFlightKeys: inFlightKeys,
              onRecord: onRecord,
              onDeleteSession: onDeleteSession,
            ),
        ],
      ),
    );
  }
}

class _CompactComponentRow extends StatelessWidget {
  const _CompactComponentRow({
    super.key,
    required this.subject,
    required this.component,
    required this.sessions,
    required this.inFlightKeys,
    required this.onRecord,
    required this.onDeleteSession,
  });

  final Subject subject;
  final SessionComponent component;
  final List<AttendanceSession> sessions;
  final Set<String> inFlightKeys;
  final void Function(Subject, SessionComponent, AttendanceStatus) onRecord;
  final void Function(AttendanceSession, String) onDeleteSession;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLecture = component == SessionComponent.lecture;
    final componentIcon = isLecture ? AppIcons.lecture : AppIcons.lab;
    final componentLabel = component.displayName;
    final componentColor = isLecture ? colors.brandPrimary : colors.accentGreen;

    final presentSessions = sessions.where((s) => s.isPresent).toList();
    final absentSessions = sessions.where((s) => !s.isPresent).toList();
    final presentCount = presentSessions.length;
    final absentCount = absentSessions.length;

    final presentKey = '${subject.id}_${component.name}_present';
    final absentKey = '${subject.id}_${component.name}_absent';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Component label with icon & live counter summary
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(componentIcon, size: 15, color: componentColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        componentLabel,
                        style: AppTypography.subhead.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sessions.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          presentCount > 0 && absentCount > 0
                              ? '$presentCount P • $absentCount A'
                              : (presentCount > 0
                                  ? '$presentCount present'
                                  : '$absentCount absent'),
                          style: AppTypography.caption2.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: Action buttons (✓ Present and ✕ Absent) with live counters and decrement stepper
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AttendanceActionButton(
                status: AttendanceStatus.present,
                count: presentCount,
                isLoading: inFlightKeys.contains(presentKey),
                semanticSubjectName: subject.name,
                semanticComponentLabel: componentLabel,
                onTap: () => onRecord(subject, component, AttendanceStatus.present),
                onDecrement: presentCount > 0
                    ? () => onDeleteSession(presentSessions.last, subject.name)
                    : null,
              ),
              const SizedBox(width: 6),
              AttendanceActionButton(
                status: AttendanceStatus.absent,
                count: absentCount,
                isLoading: inFlightKeys.contains(absentKey),
                semanticSubjectName: subject.name,
                semanticComponentLabel: componentLabel,
                onTap: () => onRecord(subject, component, AttendanceStatus.absent),
                onDecrement: absentCount > 0
                    ? () => onDeleteSession(absentSessions.last, subject.name)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void showQuickLogSheet({
  required BuildContext context,
  DateTime? initialDate,
  int? initialSubjectId,
  int? onlySubjectId,
  String? title,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final clampedInitialDate = (initialDate != null && initialDate.isAfter(today))
      ? today
      : initialDate;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.88),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: QuickLogSheet(
              initialDate: clampedInitialDate,
              initialSubjectId: initialSubjectId,
              onlySubjectId: onlySubjectId,
              title: title,
            ),
          ),
        ),
      );
    },
  );
}

/// Convenience launcher for logging attendance specifically for a single subject.
void showSubjectAttendanceSheet({
  required BuildContext context,
  required int subjectId,
  DateTime? initialDate,
  String? title,
}) {
  showQuickLogSheet(
    context: context,
    initialDate: initialDate,
    onlySubjectId: subjectId,
    title: title ?? 'Log Attendance',
  );
}
