import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_empty_state.dart';
import 'package:attendly/core/shared/widgets/app_loading_state.dart';
import 'package:attendly/core/shared/widgets/apple/apple.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_session.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/attendance/presentation/widgets/day_status_dots.dart';
import 'package:attendly/features/dashboard/presentation/providers/dashboard_scope_provider.dart';
import 'package:attendly/features/dashboard/presentation/widgets/compact_attendance_stats.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_day_schedule_card.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_empty_state.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_scope_toggle.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_subject_preview.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_trend_card.dart';
import 'package:attendly/features/dashboard/presentation/widgets/overall_attendance_hero.dart';
import 'package:attendly/features/dashboard/presentation/widgets/safe_absence_recovery_card.dart';
import 'package:attendly/features/insights/presentation/widgets/subject_comparison_card.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_switcher_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onNavigateToSubjects});

  final VoidCallback onNavigateToSubjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeSemestersAsync = ref.watch(activeSemestersStreamProvider);
    final activeSemester = ref.watch(activeSemesterProvider);

    if (activeSemestersAsync.isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: AppLoadingState()),
      );
    }

    if (activeSemester == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: AppEmptyState(
            title: 'No Active Semester',
            description:
                'Create or select a semester to see your attendance dashboard.',
            icon: const AppIcon(AppIcons.home, size: 28),
            actionLabel: 'Select Semester',
            onAction: () {
              showAppBottomSheet(
                context: context,
                title: 'Semesters',
                child: const SemesterSwitcherSheet(),
              );
            },
          ),
        ),
      );
    }

    final summaryAsync = ref.watch(semesterAttendanceSummaryProvider);
    final activeSummaryAsync = ref.watch(
      activeDashboardAttendanceSummaryProvider,
    );
    final scope = ref.watch(dashboardAttendanceScopeProvider);
    final semesterSessionsAsync = ref.watch(activeSemesterSessionsStreamProvider);
    final allSessions = semesterSessionsAsync.asData?.value ?? [];
    final dayNotesAsync = ref.watch(dayNotesForMonthProvider);
    final dayNotesMap = dayNotesAsync.value ?? {};

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: summaryAsync.when(
          data: (summary) {
            if (summary == null) {
              return const Center(child: AppLoadingState());
            }

            final hasConductedSessions = summary.totalConducted > 0;
            final displaySummary = activeSummaryAsync.value ?? summary;

            return SingleChildScrollView(
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
                  // Header: Greeting, Semester Name, Switcher & Settings
                  DashboardHeader(semester: activeSemester),
                  const SizedBox(height: 12),

                  if (hasConductedSessions) ...[
                    // Scope Selector (Overall vs This Month)
                    Center(
                      child: DashboardScopeToggle(
                        selectedScope: scope,
                        onScopeChanged: (newScope) {
                          ref
                              .read(dashboardAttendanceScopeProvider.notifier)
                              .setScope(newScope);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Overall Attendance Hero Banner (circular gauge & large %)
                    OverallAttendanceHero(summary: displaySummary, scope: scope),
                    const SizedBox(height: 16),

                    // Compact session counts (conducted, present, absent + components)
                    CompactAttendanceStats(summary: displaySummary),

                    // Safe Absence / Recovery insight card (only for overall semester targets when applicable)
                    if (scope == DashboardAttendanceScope.overall &&
                        displaySummary.totalConducted > 0 &&
                        displaySummary.calculationMethod !=
                            AttendanceCalculationMethod.componentAverage) ...[
                      const SizedBox(height: 12),
                      SafeAbsenceRecoveryCard(summary: displaySummary),
                    ],
                    const SizedBox(height: 24),

                    // Isolated Day Section: Week strip + Daily schedule
                    _DashboardDaySection(
                      allSessions: allSessions,
                      dayNotesMap: dayNotesMap,
                    ),
                    const SizedBox(height: 24),

                    // Subjects overview preview
                    DashboardSubjectPreview(
                      semesterId: activeSemester.id,
                      subjects: summary.subjectSummaries,
                      threshold: activeSemester.attendanceThreshold,
                      onNavigateToSubjects: onNavigateToSubjects,
                    ),
                    const SizedBox(height: 24),

                    // Analytics Section Header
                    Text(
                      'Analytics',
                      style: AppTypography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Attendance trend visualization
                    DashboardTrendCard(
                      trendPoints: displaySummary.trendPoints,
                      threshold: activeSemester.attendanceThreshold,
                    ),
                    const SizedBox(height: 16),

                    // Vertical Bar Comparison Chart for Subjects
                    SubjectComparisonCard(
                      subjectSummaries: summary.subjectSummaries,
                      threshold: activeSemester.attendanceThreshold,
                    ),
                  ] else ...[
                    // Overall Attendance Hero Banner
                    OverallAttendanceHero(summary: displaySummary, scope: scope),
                    const SizedBox(height: 20),

                    // Empty dashboard guide when no sessions recorded yet
                    DashboardEmptyState(
                      semester: activeSemester,
                      hasSubjects: summary.subjectSummaries.isNotEmpty,
                    ),

                    // Subjects Preview - only display when subjects exist to avoid duplicate empty state cards
                    if (summary.subjectSummaries.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      DashboardSubjectPreview(
                        semesterId: activeSemester.id,
                        subjects: summary.subjectSummaries,
                        threshold: activeSemester.attendanceThreshold,
                        onNavigateToSubjects: onNavigateToSubjects,
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: AppLoadingState()),
          error: (error, _) => Center(
            child: AppErrorState(
              message: 'Attendance could not load.',
              onRetry: () => ref.invalidate(semesterAttendanceSummaryProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardDaySection extends StatefulWidget {
  const _DashboardDaySection({
    required this.allSessions,
    required this.dayNotesMap,
  });

  final List<AttendanceSession> allSessions;
  final Map<String, String> dayNotesMap;

  @override
  State<_DashboardDaySection> createState() => _DashboardDaySectionState();
}

class _DashboardDaySectionState extends State<_DashboardDaySection> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  DayAttendanceStatus _getDayStatus(DateTime date) {
    final dateKey = formatDateOnly(date);
    final daySessions =
        widget.allSessions.where((s) => s.sessionDate == dateKey).toList();
    final note = widget.dayNotesMap[dateKey];
    return DayAttendanceStatus.fromSessions(
      sessions: daySessions,
      note: note,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppleWeekStrip(
          selectedDate: _selectedDate,
          onDateSelected: (date) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            if (DateTime(date.year, date.month, date.day).isAfter(today)) {
              return;
            }
            setState(() {
              _selectedDate = date;
            });
          },
          dayStatusBuilder: _getDayStatus,
        ),
        const SizedBox(height: 12),
        DashboardDayScheduleCard(selectedDate: _selectedDate),
      ],
    );
  }
}
