import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_empty_state.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_switcher_sheet.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';
import 'package:attendly/features/subjects/presentation/widgets/subject_form_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onNavigateToSubjects});

  final VoidCallback onNavigateToSubjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSemester = ref.watch(activeSemesterProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);

    if (activeSemester == null) {
      return Scaffold(
        backgroundColor: AppColors.warmWhite,
        body: SafeArea(
          child: AppEmptyState(
            title: 'No Active Semester',
            description:
                'Create or select a semester to see your attendance setup.',
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
              // Header: Greeting & Semester Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'College Attendance',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.mutedInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () {
                          showAppBottomSheet(
                            context: context,
                            title: 'Semesters',
                            child: const SemesterSwitcherSheet(),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activeSemester.name,
                              style: AppTypography.screenTitle.copyWith(
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: AppColors.brandViolet,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      showAppBottomSheet(
                        context: context,
                        title: 'Semesters',
                        child: const SemesterSwitcherSheet(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.softLavender,
                        shape: BoxShape.circle,
                      ),
                      child: const AppIcon(
                        AppIcons.settings,
                        size: 20,
                        color: AppColors.brandViolet,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Setup Completion / Foundation Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.softLavender, AppColors.softMint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.xlBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandViolet,
                            borderRadius: AppRadius.pillBorder,
                          ),
                          child: Text(
                            'Phase 1 Foundation Ready',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${activeSemester.thresholdPercent}% Threshold',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome to your personal Attendance Tracker',
                      style: AppTypography.sectionTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Calculation Method: ${activeSemester.calculationMethod.displayName}.\nAll data is stored locally on this device. Attendance session logging will be introduced in Phase 2.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ink,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Semester Configuration Details
              Text('Configuration', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ConfigMetricTile(
                      label: 'Target Threshold',
                      value: '${activeSemester.thresholdPercent}%',
                      subtitle: 'Required minimum',
                      color: AppColors.brandViolet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ConfigMetricTile(
                      label: 'Calculation',
                      value:
                          activeSemester.calculationMethod ==
                              AttendanceCalculationMethod.rawCombined
                          ? 'Raw'
                          : '50/50',
                      subtitle: activeSemester.calculationMethod.displayName,
                      color: AppColors.brandMint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Subjects Preview Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Enrolled Subjects', style: AppTypography.sectionTitle),
                  TextButton(
                    onPressed: onNavigateToSubjects,
                    child: Text(
                      'View All',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.brandViolet,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Real subjects preview from database
              subjectsAsync.when(
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: AppRadius.lgBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const AppIcon(
                            AppIcons.subjects,
                            size: 28,
                            color: AppColors.mutedInk,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No subjects added yet',
                            style: AppTypography.itemTitle,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add your courses to complete your semester setup.',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Add Subject',
                            icon: const AppIcon(
                              AppIcons.add,
                              size: 16,
                              color: AppColors.pureWhite,
                            ),
                            size: AppButtonSize.small,
                            onPressed: () {
                              showAppBottomSheet(
                                context: context,
                                title: 'Add Subject',
                                child: SubjectFormSheet(
                                  semesterId: activeSemester.id,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  // Preview up to 3 subjects
                  final previewList = subjects.take(3).toList();
                  return Column(
                    children: [
                      ...previewList.map((subject) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: AppColors.softLavender,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const AppIcon(
                                  AppIcons.subjects,
                                  size: 18,
                                  color: AppColors.brandViolet,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject.name,
                                      style: AppTypography.itemTitle,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (subject.lectureEnabled) 'Lecture',
                                        if (subject.labEnabled) 'Lab',
                                      ].join(' • '),
                                      style: AppTypography.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Pending Phase 2',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.subtleInk,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (subjects.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Center(
                            child: Text(
                              '+ ${subjects.length - 3} more subjects',
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigMetricTile extends StatelessWidget {
  const _ConfigMetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.metricLarge.copyWith(
              color: color,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.labelSmall.copyWith(color: AppColors.mutedInk),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
