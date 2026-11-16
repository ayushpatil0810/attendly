import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/errors/app_failure.dart';
import 'package:attendly/core/services/preferences_service.dart';
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
import 'package:attendly/features/attendance/presentation/widgets/day_note_banner.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

class QuickLogSheet extends ConsumerStatefulWidget {
  const QuickLogSheet({
    super.key,
    this.initialDate,
    this.initialSubjectId,
    this.title,
  });

  final DateTime? initialDate;
  final int? initialSubjectId;
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
    _selectedDate =
        widget.initialDate ?? DateTime(now.year, now.month, now.day);
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.inkViolet,
              onPrimary: AppColors.pureWhite,
              onSurface: AppColors.ink,
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
    final dateStr = formatDateOnly(_selectedDate);

    try {
      await ref.read(attendanceControllerProvider.notifier).recordSession(
            subjectId: subject.id,
            sessionDate: dateStr,
            component: component,
            status: status,
          );

      AppHaptics.lightImpact(ref);

      if (!mounted) return;

      final statusLabel =
          status == AttendanceStatus.present ? 'Present' : 'Absent';
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
      AppHaptics.lightImpact(ref);

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
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final dateStr = formatDateOnly(_selectedDate);
    final isToday = dateStr == formatDateOnly(DateTime.now());
    final formattedDate = DateFormat('EEE, d MMM').format(_selectedDate);
    final sessionsForDateAsync = ref.watch(
      sessionsForDateFamilyProvider(dateStr),
    );

    return Column(
      children: [
        // Drag Handle
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.divider,
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
                  widget.title ?? 'Quick Attendance Log',
                  style: AppTypography.sectionTitle,
                ),
              ),
              AppCloseButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: subjectsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brandViolet),
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
                        decoration: const BoxDecoration(
                          color: AppColors.softPeach,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const AppIcon(
                          AppIcons.subjects,
                          size: 28,
                          color: AppColors.inkPeach,
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

              // Sort subjects so initialSubjectId (if any) is at the top
              final sortedSubjects = [...subjects];
              if (widget.initialSubjectId != null) {
                final idx = sortedSubjects.indexWhere(
                  (s) => s.id == widget.initialSubjectId,
                );
                if (idx > 0) {
                  final target = sortedSubjects.removeAt(idx);
                  sortedSubjects.insert(0, target);
                }
              }

              final sessions = sessionsForDateAsync.value ?? [];
              final totalLoggedOnDate = sessions.length;

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
                                  const AppIcon(
                                    AppIcons.calendar,
                                    size: 15,
                                    color: AppColors.brandViolet,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isToday
                                        ? 'Today ($formattedDate)'
                                        : formattedDate,
                                    style: AppTypography.itemTitle.copyWith(
                                      color: AppColors.inkViolet,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const AppIcon(
                                    AppIcons.arrowDown,
                                    size: 13,
                                    color: AppColors.brandViolet,
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
                              color: AppColors.mutedInk,
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
                  const Divider(height: 1, color: AppColors.divider),

                  // Vertical Subject List
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      itemCount: sortedSubjects.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final subject = sortedSubjects[index];
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
                    decoration: const BoxDecoration(
                      color: AppColors.pureWhite,
                      border: Border(
                        top: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: AppButton(
                      label: 'Done Logging',
                      size: AppButtonSize.large,
                      isFullWidth: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubjectLogCard extends StatelessWidget {
  const _SubjectLogCard({
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(
          color: isInitial ? AppColors.brandViolet : AppColors.border,
          width: isInitial ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Subject Name & Total Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    subject.name,
                    style: AppTypography.itemTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.softLavender,
                      borderRadius: AppRadius.pillBorder,
                    ),
                    child: Text(
                      totalCount == 1 ? '1 class' : '$totalCount classes',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.inkViolet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Component rows
          if (subject.lectureEnabled)
            _ComponentSubRow(
              subject: subject,
              component: SessionComponent.lecture,
              sessions: lectureSessions,
              inFlightKeys: inFlightKeys,
              onRecord: onRecord,
              onDeleteSession: onDeleteSession,
            ),

          if (subject.hasBothComponents)
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppColors.divider,
            ),

          if (subject.labEnabled)
            _ComponentSubRow(
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

class _ComponentSubRow extends StatelessWidget {
  const _ComponentSubRow({
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
    final isLecture = component == SessionComponent.lecture;
    final componentIcon = isLecture ? AppIcons.lecture : AppIcons.lab;
    final componentLabel =
        isLecture ? 'Theory Lecture' : 'Practical Lab';
    final componentColor =
        isLecture ? AppColors.brandViolet : AppColors.inkMint;

    final presentKey = '${subject.id}_${component.name}_present';
    final absentKey = '${subject.id}_${component.name}_absent';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Component label row
          Row(
            children: [
              AppIcon(componentIcon, size: 14, color: componentColor),
              const SizedBox(width: 6),
              Text(
                componentLabel,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              if (sessions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '(${sessions.length} logged)',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mutedInk,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),

          // Logged session chips
          if (sessions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (var i = 0; i < sessions.length; i++)
                  _SessionChip(
                    session: sessions[i],
                    index: i,
                    subjectName: subject.name,
                    isDeleting: inFlightKeys.contains('delete_${sessions[i].id}'),
                    onDelete: () => onDeleteSession(sessions[i], subject.name),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),

          // Action buttons: + Present and + Absent
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  label: '+ Present',
                  icon: AppIcons.check,
                  backgroundColor: AppColors.brandMint,
                  borderColor: AppColors.inkMint,
                  textColor: AppColors.ink,
                  semanticLabel:
                      'Mark Present for ${subject.name} $componentLabel',
                  isLoading: inFlightKeys.contains(presentKey),
                  onTap: () => onRecord(
                    subject,
                    component,
                    AttendanceStatus.present,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  label: '+ Absent',
                  icon: AppIcons.close,
                  backgroundColor: AppColors.brandCoral,
                  borderColor: AppColors.inkCoral,
                  textColor: AppColors.ink,
                  semanticLabel:
                      'Mark Absent for ${subject.name} $componentLabel',
                  isLoading: inFlightKeys.contains(absentKey),
                  onTap: () => onRecord(
                    subject,
                    component,
                    AttendanceStatus.absent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionChip extends StatelessWidget {
  const _SessionChip({
    required this.session,
    required this.index,
    required this.subjectName,
    required this.isDeleting,
    required this.onDelete,
  });

  final AttendanceSession session;
  final int index;
  final String subjectName;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPresent = session.isPresent;
    final prefix =
        session.component == SessionComponent.lecture ? 'Lec' : 'Lab';
    final statusText = isPresent ? 'Present' : 'Absent';
    final bgColor = isPresent ? AppColors.softMint : AppColors.softCoral;
    final textColor = isPresent ? AppColors.inkMint : AppColors.inkCoral;
    final borderColor = isPresent
        ? AppColors.inkMint.withValues(alpha: 0.3)
        : AppColors.inkCoral.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            isPresent ? AppIcons.check : AppIcons.close,
            size: 13,
            color: textColor,
          ),
          const SizedBox(width: 5),
          Text(
            '$prefix ${index + 1}: $statusText',
            style: AppTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: 'Remove $prefix ${index + 1} $statusText',
            child: InkWell(
              onTap: isDeleting ? null : onDelete,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: isDeleting
                      ? SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: textColor,
                          ),
                        )
                      : AppIcon(
                          AppIcons.close,
                          size: 13,
                          color: textColor,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
    this.isLoading = false,
    this.semanticLabel,
  });

  final String label;
  final dynamic icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool isLoading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isLoading,
      label: semanticLabel ?? label,
      child: Material(
        color: backgroundColor,
        borderRadius: AppRadius.mdBorder,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: AppRadius.mdBorder,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(icon, size: 16, color: textColor),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: AppTypography.labelLarge.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

void showQuickLogSheet({
  required BuildContext context,
  DateTime? initialDate,
  int? initialSubjectId,
  String? title,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.pureWhite,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.88,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: mediaQuery.viewInsets.bottom,
            ),
            child: QuickLogSheet(
              initialDate: initialDate,
              initialSubjectId: initialSubjectId,
              title: title,
            ),
          ),
        ),
      );
    },
  );
}
