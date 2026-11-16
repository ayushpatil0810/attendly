import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_milestone.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

class GoalMilestonesCard extends ConsumerWidget {
  const GoalMilestonesCard({
    super.key,
    required this.summary,
    required this.semester,
  });

  final SemesterAttendanceSummary summary;
  final Semester semester;

  void _showEditGoalSheet(BuildContext context, WidgetRef ref) {
    AppHaptics.selectionClick(ref);
    showAppBottomSheet(
      context: context,
      title: 'Personal Attendance Goal',
      child: _EditGoalSheetContent(semester: semester),
    );
  }

  void _showMilestoneDetailSheet(
    BuildContext context,
    WidgetRef ref,
    AttendanceMilestone milestone,
    bool isAchieved,
  ) {
    AppHaptics.selectionClick(ref);
    showAppBottomSheet(
      context: context,
      title: milestone.title,
      child: _MilestoneDetailSheetContent(
        milestone: milestone,
        isAchieved: isAchieved,
        currentPercentage: summary.overallPercentage,
        isPersonalGoal: summary.targetGoalPercent == milestone.percentage,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPct = summary.overallPercentage;
    final hasSessions = summary.totalConducted > 0 && currentPct != null;
    final meetsGoal = summary.meetsGoal;
    final goalPercent = summary.targetGoalPercent;

    return Semantics(
      container: true,
      label:
          'Personal attendance goal: $goalPercent%. Current attendance: ${summary.formattedPercentage}.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title, Target Pill & Edit Action
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: meetsGoal
                        ? AppColors.softMint
                        : AppColors.softLavender,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(
                    meetsGoal ? AppIcons.trophy : AppIcons.target,
                    size: 18,
                    color: meetsGoal ? AppColors.inkMint : AppColors.inkViolet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          const Text(
                            'Personal Goal',
                            style: AppTypography.itemTitle,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softLavender,
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: Text(
                              '$goalPercent%',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.inkViolet,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meetsGoal
                            ? 'You are beating your target!'
                            : 'Aim higher than university threshold',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showEditGoalSheet(context, ref),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: const Size(48, 36),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: Text(
                    'Edit',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.inkViolet,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Visual Progress Bar towards Personal Goal
            if (hasSessions) ...[
              _GoalProgressBar(
                currentPercentage: currentPct,
                threshold: summary.thresholdPercent.toDouble(),
                goal: goalPercent.toDouble(),
              ),
              const SizedBox(height: 14),
            ],

            // Advice / Insight Box
            _GoalAdviceBox(summary: summary),
            const SizedBox(height: 16),

            // Milestones Section
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Milestones',
                  style: AppTypography.itemTitle.copyWith(fontSize: 13),
                ),
                Text(
                  '${AttendanceMilestone.achievedFor(currentPct).length} / ${AttendanceMilestone.values.length} Unlocked',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontal Milestone Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: AttendanceMilestone.values.map((milestone) {
                  final isAchieved =
                      hasSessions &&
                      currentPct >= (milestone.percentage - 1e-9);
                  final isPersonalGoal = milestone.percentage == goalPercent;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _MilestoneChip(
                      milestone: milestone,
                      isAchieved: isAchieved,
                      isPersonalGoal: isPersonalGoal,
                      onTap: () => _showMilestoneDetailSheet(
                        context,
                        ref,
                        milestone,
                        isAchieved,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressBar extends StatelessWidget {
  const _GoalProgressBar({
    required this.currentPercentage,
    required this.threshold,
    required this.goal,
  });

  final double currentPercentage;
  final double threshold;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final progress = (currentPercentage / 100.0).clamp(0.0, 1.0);
    final goalRatio = (goal / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Current: ${currentPercentage.toStringAsFixed(1)}%',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: currentPercentage >= goal
                    ? AppColors.inkMint
                    : AppColors.ink,
              ),
            ),
            Text(
              'Goal: ${goal.toInt()}%',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.inkViolet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background track
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.track,
                borderRadius: AppRadius.pillBorder,
              ),
            ),
            // Progress fill
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: currentPercentage >= goal
                      ? AppColors.brandMint
                      : AppColors.brandViolet,
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
            ),
            // Goal indicator marker tick
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final markerOffset = constraints.maxWidth * goalRatio - 1.5;
                  return Stack(
                    children: [
                      Positioned(
                        left: markerOffset.clamp(0.0, constraints.maxWidth - 3),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: AppColors.inkViolet,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoalAdviceBox extends StatelessWidget {
  const _GoalAdviceBox({required this.summary});

  final SemesterAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.totalConducted == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.softLavender,
          borderRadius: AppRadius.mdBorder,
        ),
        child: Row(
          children: [
            const AppIcon(
              AppIcons.info,
              size: 16,
              color: AppColors.brandViolet,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Record attendance to calculate consecutive classes needed for your ${summary.targetGoalPercent}% goal.',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedInk,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (summary.calculationMethod ==
        AttendanceCalculationMethod.componentAverage) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.softLavender,
          borderRadius: AppRadius.mdBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: AppIcon(
                AppIcons.info,
                size: 16,
                color: AppColors.brandViolet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Component Average Method',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Goal recovery depends on the future ratio of Lectures vs Labs. Use the Simulator to model precise recovery scenarios.',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.mutedInk,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (summary.meetsGoal) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.softMint,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.brandMint.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: AppIcon(
                AppIcons.check,
                size: 16,
                color: AppColors.inkMint,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Goal Met! 🎉',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.inkMint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You are at ${summary.formattedPercentage}, comfortably beating your ${summary.targetGoalPercent}% goal. Keep up the flawless consistency!',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.inkMint,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final goalRecovery = summary.goalRecoveryResult;

    if (goalRecovery.isImpossible) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.softCoral,
          borderRadius: AppRadius.mdBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: AppIcon(
                AppIcons.alert,
                size: 16,
                color: AppColors.inkCoral,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'A 100% goal cannot be reached because past absences occurred. Consider adjusting your personal goal to 90% or 95%.',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.inkCoral,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final needed = goalRecovery.requiredConsecutivePresents ?? 0;
    final unit = needed == 1 ? 'class' : 'classes';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softLavender,
        borderRadius: AppRadius.mdBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: AppIcon(
              AppIcons.target,
              size: 16,
              color: AppColors.inkViolet,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reach Your ${summary.targetGoalPercent}% Goal',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Attend the next $needed consecutive $unit with no absences to reach your goal.',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assumption: All upcoming sessions are attended without absences.',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.subtleInk,
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({
    required this.milestone,
    required this.isAchieved,
    required this.isPersonalGoal,
    required this.onTap,
  });

  final AttendanceMilestone milestone;
  final bool isAchieved;
  final bool isPersonalGoal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isAchieved
        ? AppColors.softMint
        : isPersonalGoal
        ? AppColors.softLavender
        : AppColors.track.withValues(alpha: 0.5);

    final borderColor = isPersonalGoal
        ? AppColors.brandViolet
        : isAchieved
        ? AppColors.brandMint
        : Colors.transparent;

    final textColor = isAchieved
        ? AppColors.inkMint
        : isPersonalGoal
        ? AppColors.inkViolet
        : AppColors.mutedInk;

    return Semantics(
      button: true,
      label:
          'Milestone ${milestone.badgeName}: ${isAchieved ? "Achieved" : "Locked"}${isPersonalGoal ? ", Personal goal" : ""}',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(
              color: borderColor,
              width: isPersonalGoal ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                isAchieved
                    ? AppIcons.check
                    : isPersonalGoal
                    ? AppIcons.target
                    : AppIcons.award,
                size: 14,
                color: textColor,
              ),
              const SizedBox(width: 5),
              Text(
                milestone.badgeName,
                style: AppTypography.labelSmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (isPersonalGoal) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inkViolet,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Text(
                    'Goal',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.pureWhite,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneDetailSheetContent extends StatelessWidget {
  const _MilestoneDetailSheetContent({
    required this.milestone,
    required this.isAchieved,
    required this.currentPercentage,
    required this.isPersonalGoal,
  });

  final AttendanceMilestone milestone;
  final bool isAchieved;
  final double? currentPercentage;
  final bool isPersonalGoal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isAchieved
                      ? AppColors.softMint
                      : AppColors.softLavender,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  isAchieved ? AppIcons.trophy : AppIcons.award,
                  size: 24,
                  color: isAchieved ? AppColors.inkMint : AppColors.inkViolet,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${milestone.badgeName} Milestone',
                          style: AppTypography.itemTitle.copyWith(fontSize: 17),
                        ),
                        if (isPersonalGoal) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softLavender,
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: Text(
                              'Your Goal',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.inkViolet,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAchieved
                          ? 'Unlocked & Achieved! 🎉'
                          : 'In progress towards ${milestone.badgeName}',
                      style: AppTypography.labelSmall.copyWith(
                        color: isAchieved
                            ? AppColors.inkMint
                            : AppColors.mutedInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            milestone.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isAchieved
                  ? AppColors.softMint
                  : AppColors.track.withValues(alpha: 0.5),
              borderRadius: AppRadius.mdBorder,
            ),
            child: Text(
              isAchieved
                  ? milestone.celebrationMessage
                  : currentPercentage != null
                  ? 'You are at ${currentPercentage!.toStringAsFixed(1)}%. Keep attending classes consistently to unlock this milestone.'
                  : 'Record attendance in your semester to track progress towards this milestone.',
              style: AppTypography.labelSmall.copyWith(
                color: isAchieved ? AppColors.inkMint : AppColors.mutedInk,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _EditGoalSheetContent extends ConsumerStatefulWidget {
  const _EditGoalSheetContent({required this.semester});

  final Semester semester;

  @override
  ConsumerState<_EditGoalSheetContent> createState() =>
      _EditGoalSheetContentState();
}

class _EditGoalSheetContentState extends ConsumerState<_EditGoalSheetContent> {
  late double _selectedGoal;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.semester.targetGoal;
  }

  @override
  Widget build(BuildContext context) {
    final goalPercent = (_selectedGoal * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize your personal target. This gives you extra motivation above the university requirement (${(widget.semester.attendanceThreshold * 100).round()}%).',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.mutedInk,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Target Goal', style: AppTypography.itemTitle),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(
                    color: AppColors.brandMint.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '$goalPercent%',
                  style: AppTypography.metricMedium.copyWith(
                    fontSize: 16,
                    color: AppColors.inkMint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.inkMint,
              inactiveTrackColor: AppColors.track,
              thumbColor: AppColors.inkMint,
              overlayColor: AppColors.brandMint.withValues(alpha: 0.15),
              trackHeight: 6,
            ),
            child: Slider(
              value: _selectedGoal,
              min: 0.50,
              max: 1.00,
              divisions: 50,
              onChanged: (val) {
                setState(() {
                  _selectedGoal = (val * 100).round() / 100.0;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [80, 85, 90, 95].map((preset) {
              final isSel = (goalPercent == preset);
              return ChoiceChip(
                label: Text('$preset%'),
                selected: isSel,
                onSelected: (_) {
                  AppHaptics.selectionClick(ref);
                  setState(() {
                    _selectedGoal = preset / 100.0;
                  });
                },
                selectedColor: AppColors.softMint,
                backgroundColor: AppColors.track.withValues(alpha: 0.5),
                labelStyle: TextStyle(
                  color: isSel ? AppColors.inkMint : AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                AppHaptics.lightImpact(ref);
                final updated = widget.semester.copyWith(
                  targetGoal: _selectedGoal,
                );
                await ref
                    .read(semesterControllerProvider.notifier)
                    .updateSemester(updated);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inkViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.pillBorder,
                ),
                elevation: 0,
              ),
              child: Text(
                'Save Goal',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
