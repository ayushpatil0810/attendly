import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_progress.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/attendance/presentation/widgets/quick_log_sheet.dart';
import 'package:attendly/features/subjects/domain/entities/subject.dart';

/// Modal bottom sheet presenting in-depth analytics, component breakdowns,
/// and safe-absence/recovery calculations for a specific subject.
class SubjectDetailSheet extends StatelessWidget {
  const SubjectDetailSheet({
    super.key,
    required this.subject,
    required this.summary,
    required this.threshold,
    required this.calculationMethod,
    required this.onEdit,
    required this.onDelete,
  });

  final Subject subject;
  final SubjectAttendanceSummary? summary;
  final double threshold;
  final AttendanceCalculationMethod calculationMethod;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _getStatusColor() {
    if (summary == null || summary!.totalConducted == 0) {
      return AppColors.mutedInk;
    }
    if (summary!.isProvisional) return AppColors.brandPeach;
    switch (summary!.thresholdStatus) {
      case ThresholdStatus.meeting:
        return AppColors.brandMint;
      case ThresholdStatus.below:
        return AppColors.brandCoral;
      case ThresholdStatus.notAvailable:
        return AppColors.mutedInk;
    }
  }

  String _getStatusText() {
    if (summary == null || summary!.totalConducted == 0) {
      return 'No records yet';
    }
    if (summary!.isProvisional) return 'Provisional';
    switch (summary!.thresholdStatus) {
      case ThresholdStatus.meeting:
        return 'Meeting Target';
      case ThresholdStatus.below:
        return 'Below Target';
      case ThresholdStatus.notAvailable:
        return 'No records';
    }
  }

  String _formatPct(double? pct) {
    if (pct == null) return 'N/A';
    return pct == pct.roundToDouble()
        ? '${pct.toInt()}%'
        : '${pct.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    final hasData = summary != null && summary!.totalConducted > 0;
    final pctValue = summary?.percentage;

    final targetPctInt = (threshold * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Subject name, status badge, 3-dot menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: AppTypography.screenTitle.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: AppRadius.pillBorder,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: AppTypography.labelSmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Subject options',
                icon: const AppIcon(
                  AppIcons.more,
                  size: 20,
                  color: AppColors.mutedInk,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                onSelected: (val) {
                  Navigator.of(context).pop();
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        AppIcon(AppIcons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Subject'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        AppIcon(
                          AppIcons.delete,
                          size: 16,
                          color: AppColors.inkCoral,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete Subject',
                          style: TextStyle(color: AppColors.inkCoral),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Attendance Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hasData && pctValue != null
                          ? _formatPct(pctValue)
                          : 'Not available',
                      style: AppTypography.heroNumber.copyWith(
                        fontSize: 34,
                        color: hasData ? AppColors.ink : AppColors.mutedInk,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'Target: $targetPctInt%',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppProgressBar(
                  progress: hasData && pctValue != null
                      ? pctValue / 100.0
                      : 0.0,
                  color: statusColor,
                  height: 8,
                ),
                const SizedBox(height: 14),
                // Session counts row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricCell(
                      label: 'Present',
                      value: '${summary?.totalPresent ?? 0}',
                      color: AppColors.inkMint,
                    ),
                    _MetricCell(
                      label: 'Absent',
                      value: '${summary?.totalAbsent ?? 0}',
                      color: AppColors.inkCoral,
                    ),
                    _MetricCell(
                      label: 'Conducted',
                      value: '${summary?.totalConducted ?? 0}',
                      color: AppColors.ink,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Component Breakdown (Lecture / Lab)
          Row(
            children: [
              if (subject.lectureEnabled)
                Expanded(
                  child: _ComponentCard(
                    title: 'Lecture',
                    icon: AppIcons.lecture,
                    color: AppColors.brandViolet,
                    present: summary?.lectureSummary?.presentCount ?? 0,
                    absent: summary?.lectureSummary?.absentCount ?? 0,
                    conducted: summary?.lectureSummary?.conductedCount ?? 0,
                    percentage: summary?.lectureSummary?.percentage,
                  ),
                ),
              if (subject.lectureEnabled && subject.labEnabled)
                const SizedBox(width: 12),
              if (subject.labEnabled)
                Expanded(
                  child: _ComponentCard(
                    title: 'Lab',
                    icon: AppIcons.lab,
                    color: AppColors.inkMint,
                    present: summary?.labSummary?.presentCount ?? 0,
                    absent: summary?.labSummary?.absentCount ?? 0,
                    conducted: summary?.labSummary?.conductedCount ?? 0,
                    percentage: summary?.labSummary?.percentage,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Subject Safe Absences or Recovery Card
          _SubjectInsightCard(summary: summary, threshold: threshold),
          if (summary != null && summary!.totalConducted > 0) ...[
            const SizedBox(height: 12),
            _SubjectGoalCard(summary: summary!),
          ],
          const SizedBox(height: 24),

          // Primary Action: Log attendance for this subject
          AppButton(
            label: 'Log Attendance for ${subject.name}',
            icon: const AppIcon(
              AppIcons.add,
              size: 18,
              color: AppColors.pureWhite,
            ),
            isFullWidth: true,
            size: AppButtonSize.large,
            onPressed: () {
              Navigator.of(context).pop();
              showQuickLogSheet(context: context, initialSubjectId: subject.id);
            },
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.itemTitle.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.mutedInk,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.present,
    required this.absent,
    required this.conducted,
    required this.percentage,
  });

  final String title;
  final dynamic icon;
  final Color color;
  final int present;
  final int absent;
  final int conducted;
  final double? percentage;

  @override
  Widget build(BuildContext context) {
    final pctStr = percentage != null
        ? (percentage == percentage!.roundToDouble()
              ? '${percentage!.toInt()}%'
              : '${percentage!.toStringAsFixed(1)}%')
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.itemTitle.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                pctStr,
                style: AppTypography.itemTitle.copyWith(
                  color: percentage != null ? color : AppColors.mutedInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conducted > 0
                ? '$present / $conducted attended ($absent absent)'
                : 'No $title sessions yet',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.mutedInk,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectInsightCard extends StatelessWidget {
  const _SubjectInsightCard({required this.summary, required this.threshold});

  final SubjectAttendanceSummary? summary;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    if (summary == null || summary!.totalConducted == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.track,
          borderRadius: AppRadius.mdBorder,
        ),
        child: Row(
          children: [
            const AppIcon(AppIcons.info, size: 16, color: AppColors.mutedInk),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Log class sessions to see safe absences or recovery needed for this subject.',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedInk,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final safeResult = summary!.safeAbsenceResult;
    final recoveryResult = summary!.recoveryResult;

    if (safeResult.requiresScenario || recoveryResult.requiresScenario) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.softLavender,
          borderRadius: AppRadius.mdBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIcon(
              AppIcons.info,
              size: 16,
              color: AppColors.brandViolet,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                safeResult.requiresScenario
                    ? safeResult.message
                    : recoveryResult.message,
                style: AppTypography.labelSmall.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
      );
    }

    if (summary!.meetsThreshold) {
      final count = safeResult.safeAbsences ?? 0;
      final text = count == 1 ? '1 session' : '$count sessions';

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.softMint,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.inkMint.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const AppIcon(AppIcons.check, size: 18, color: AppColors.inkMint),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count > 0
                        ? 'You can safely miss $text'
                        : 'On the margin: missing 1 drops below target',
                    style: AppTypography.itemTitle.copyWith(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    safeResult.message,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.mutedInk,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      final count = recoveryResult.requiredConsecutivePresents ?? 0;
      final text = count == 1 ? '1 session' : '$count sessions';

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.softCoral,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.inkCoral.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const AppIcon(AppIcons.alert, size: 18, color: AppColors.inkCoral),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !recoveryResult.isImpossible
                        ? 'Attend next $text consecutively'
                        : 'Recovery impossible with current absences',
                    style: AppTypography.itemTitle.copyWith(
                      color: AppColors.inkCoral,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recoveryResult.message,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.mutedInk,
                      fontSize: 11,
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
}

class _SubjectGoalCard extends StatelessWidget {
  const _SubjectGoalCard({required this.summary});

  final SubjectAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final goalPercent = summary.targetGoalPercent;
    final meetsGoal = summary.meetsGoal;
    final goalRecovery = summary.goalRecoveryResult;

    final bgColor = meetsGoal ? AppColors.softMint : AppColors.softLavender;
    final iconColor = meetsGoal ? AppColors.inkMint : AppColors.inkViolet;

    String message;
    if (meetsGoal) {
      message = 'Meeting your personal goal of $goalPercent% in this subject!';
    } else if (goalRecovery.requiresScenario) {
      message =
          'Recovery towards your $goalPercent% goal depends on Lecture & Lab distribution.';
    } else if (goalRecovery.isImpossible) {
      message = '100% goal cannot be reached through attendance alone due to absences.';
    } else if (goalRecovery.requiredConsecutivePresents != null) {
      final n = goalRecovery.requiredConsecutivePresents!;
      final unit = n == 1 ? 'class' : 'classes';
      message =
          'Attend the next $n consecutive $unit to reach your $goalPercent% goal.';
    } else {
      message =
          'Track your attendance to monitor progress towards your $goalPercent% goal.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(
          color: meetsGoal
              ? AppColors.brandMint.withValues(alpha: 0.4)
              : AppColors.brandViolet.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AppIcon(
              meetsGoal ? AppIcons.trophy : AppIcons.target,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Personal Goal ($goalPercent%)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                    if (meetsGoal) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandMint.withValues(alpha: 0.3),
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: Text(
                          'Achieved',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.inkMint,
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
                  message,
                  style: AppTypography.labelSmall.copyWith(
                    color: meetsGoal ? AppColors.inkMint : AppColors.mutedInk,
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
}

/// Helper to display the subject detail sheet from anywhere in the app.
void showSubjectDetailSheet({
  required BuildContext context,
  required Subject subject,
  required SubjectAttendanceSummary? summary,
  required double threshold,
  required AttendanceCalculationMethod calculationMethod,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.pureWhite,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (context) {
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
              const SizedBox(height: 8),
              SubjectDetailSheet(
                subject: subject,
                summary: summary,
                threshold: threshold,
                calculationMethod: calculationMethod,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      );
    },
  );
}
