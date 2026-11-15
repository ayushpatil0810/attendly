import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_empty_state.dart';
import 'package:attendly/core/shared/widgets/app_loading_state.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/dashboard/presentation/widgets/compact_attendance_stats.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_empty_state.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_subject_preview.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_trend_card.dart';
import 'package:attendly/features/dashboard/presentation/widgets/overall_attendance_hero.dart';
import 'package:attendly/features/dashboard/presentation/widgets/safe_absence_recovery_card.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_switcher_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onNavigateToSubjects});

  final VoidCallback onNavigateToSubjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSemester = ref.watch(activeSemesterProvider);

    if (activeSemester == null) {
      return Scaffold(
        backgroundColor: AppColors.warmWhite,
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

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: summaryAsync.when(
          data: (summary) {
            if (summary == null) {
              return const Center(child: AppLoadingState());
            }

            final hasConductedSessions = summary.totalConducted > 0;

            return SingleChildScrollView(
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
                  const SizedBox(height: 20),

                  // Overall Attendance Hero Banner (large % & progress ring)
                  OverallAttendanceHero(summary: summary),
                  const SizedBox(height: 16),

                  if (!hasConductedSessions) ...[
                    // Empty dashboard guide when no sessions recorded yet
                    DashboardEmptyState(
                      semester: activeSemester,
                      hasSubjects: summary.subjectSummaries.isNotEmpty,
                    ),
                    const SizedBox(height: 24),

                    // Subjects Preview
                    DashboardSubjectPreview(
                      semesterId: activeSemester.id,
                      subjects: summary.subjectSummaries,
                      threshold: activeSemester.attendanceThreshold,
                      onNavigateToSubjects: onNavigateToSubjects,
                    ),
                  ] else ...[
                    // Compact session counts (conducted, present, absent + components)
                    CompactAttendanceStats(summary: summary),
                    const SizedBox(height: 16),

                    // Safe Absence / Recovery insight card
                    SafeAbsenceRecoveryCard(summary: summary),
                    const SizedBox(height: 24),

                    // Subjects overview preview
                    DashboardSubjectPreview(
                      semesterId: activeSemester.id,
                      subjects: summary.subjectSummaries,
                      threshold: activeSemester.attendanceThreshold,
                      onNavigateToSubjects: onNavigateToSubjects,
                    ),
                    const SizedBox(height: 24),

                    // Attendance trend visualization
                    DashboardTrendCard(
                      trendPoints: summary.trendPoints,
                      threshold: activeSemester.attendanceThreshold,
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: AppLoadingState()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Could not load dashboard data: $error',
                style: const TextStyle(color: AppColors.brandCoral),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
