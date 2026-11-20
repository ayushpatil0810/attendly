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
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onNavigateToSubjects});

  final VoidCallback onNavigateToSubjects;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
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

    Color? getDayDotColor(DateTime date) {
      final dateKey = formatDateOnly(date);
      final daySessions = allSessions.where((s) => s.sessionDate == dateKey).toList();
      if (daySessions.isEmpty) return null;
      final hasAbsent = daySessions.any((s) => s.status == AttendanceStatus.absent);
      if (hasAbsent) return colors.accentCoral;
      return colors.accentMint;
    }

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
                bottom: AppSpacing.dockClearance,
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

                    // Apple Week Strip with day momentum status dots
                    AppleWeekStrip(
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      dayDotColorBuilder: getDayDotColor,
                    ),
                    const SizedBox(height: 12),

                    // Daily Class Schedule Card for selected date
                    DashboardDayScheduleCard(selectedDate: _selectedDate),
                    const SizedBox(height: 24),

                    // Subjects overview preview
                    DashboardSubjectPreview(
                      semesterId: activeSemester.id,
                      subjects: summary.subjectSummaries,
                      threshold: activeSemester.attendanceThreshold,
                      onNavigateToSubjects: widget.onNavigateToSubjects,
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
                      trendPoints: summary.trendPoints,
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
                        onNavigateToSubjects: widget.onNavigateToSubjects,
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
