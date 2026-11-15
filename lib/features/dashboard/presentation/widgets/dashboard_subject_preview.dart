import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_progress.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';
import 'package:attendly/features/attendance/domain/entities/threshold_status.dart';
import 'package:attendly/features/subjects/presentation/widgets/subject_form_sheet.dart';

class DashboardSubjectPreview extends StatelessWidget {
  const DashboardSubjectPreview({
    super.key,
    required this.semesterId,
    required this.subjects,
    required this.threshold,
    required this.onNavigateToSubjects,
  });

  final int semesterId;
  final List<SubjectAttendanceSummary> subjects;
  final double threshold;
  final VoidCallback onNavigateToSubjects;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Subjects Overview',
                style: AppTypography.sectionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (subjects.isNotEmpty)
              Semantics(
                button: true,
                label: 'View all subjects',
                child: TextButton(
                  onPressed: onNavigateToSubjects,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    minimumSize: const Size(48, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.inkViolet,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Subject list or empty state
        if (subjects.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
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
                  'Add courses to your semester to start tracking attendance.',
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
                      child: SubjectFormSheet(semesterId: semesterId),
                    );
                  },
                ),
              ],
            ),
          )
        else
          Container(
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
                // Render up to 4 subjects
                ...subjects.take(4).map((subject) {
                  final isLast =
                      subject == subjects.take(4).last && subjects.length <= 4;
                  return Column(
                    children: [
                      InkWell(
                        onTap: onNavigateToSubjects,
                        borderRadius: isLast
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              )
                            : (subject == subjects.first
                                  ? const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    )
                                  : BorderRadius.zero),
                        child: _SubjectPreviewRow(
                          subject: subject,
                          threshold: threshold,
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.divider,
                        ),
                    ],
                  );
                }),
                if (subjects.length > 4) ...[
                  const Divider(height: 1, color: AppColors.divider),
                  Semantics(
                    button: true,
                    label: 'View ${subjects.length - 4} more subjects',
                    child: InkWell(
                      onTap: onNavigateToSubjects,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            '+ ${subjects.length - 4} more subjects',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.inkViolet,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SubjectPreviewRow extends StatelessWidget {
  const _SubjectPreviewRow({required this.subject, required this.threshold});

  final SubjectAttendanceSummary subject;
  final double threshold;

  Color _getProgressColor() {
    if (subject.isProvisional) return AppColors.brandPeach;
    switch (subject.thresholdStatus) {
      case ThresholdStatus.meeting:
        return AppColors.brandMint;
      case ThresholdStatus.below:
        return AppColors.brandCoral;
      case ThresholdStatus.notAvailable:
        return AppColors.track;
    }
  }

  String _formatPct() {
    if (subject.isNotAvailable || subject.percentage == null) {
      return 'Not available';
    }
    final pct = subject.percentage!;
    final pctStr = pct == pct.roundToDouble()
        ? '${pct.toInt()}%'
        : '${pct.toStringAsFixed(1)}%';

    if (subject.isProvisional) {
      return '$pctStr (Provisional)';
    }
    return pctStr;
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = _getProgressColor();
    final progress = subject.percentage != null
        ? (subject.percentage! / 100.0).clamp(0.0, 1.0)
        : 0.0;
    final formattedPct = _formatPct();

    return Semantics(
      button: true,
      label:
          '${subject.subjectName}, $formattedPct. ${subject.totalConducted > 0 ? '${subject.totalPresent} of ${subject.totalConducted} attended' : 'No sessions recorded yet'}',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Percentage Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    subject.subjectName,
                    style: AppTypography.itemTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formattedPct,
                        style: AppTypography.labelLarge.copyWith(
                          color: subject.isNotAvailable
                              ? AppColors.mutedInk
                              : (subject.thresholdStatus ==
                                        ThresholdStatus.meeting
                                    ? AppColors.inkMint
                                    : (subject.thresholdStatus ==
                                              ThresholdStatus.below
                                          ? AppColors.inkCoral
                                          : AppColors.ink)),
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Progress bar
            AppProgressBar(
              progress: progress,
              height: 5,
              color: progressColor,
              trackColor: AppColors.track,
            ),
            const SizedBox(height: 8),

            // Metadata row (Components & Counts)
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      if (subject.lectureEnabled) 'Lecture',
                      if (subject.labEnabled) 'Lab',
                    ].join(' • '),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.mutedInk,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subject.totalConducted > 0
                        ? '${subject.totalPresent}/${subject.totalConducted} attended'
                        : 'No sessions yet',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.mutedInk,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontStyle: subject.totalConducted > 0
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
