import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/hypothetical_session.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/simulator/presentation/providers/simulator_providers.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

class HypotheticalSessionList extends ConsumerWidget {
  const HypotheticalSessionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hypotheticalSessions = ref.watch(simulatorControllerProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final subjects = subjectsAsync.asData?.value ?? [];

    final subjectMap = {for (final s in subjects) s.id: s};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Simulated Classes (${hypotheticalSessions.length})',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (hypotheticalSessions.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ref.read(simulatorControllerProvider.notifier).reset();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle.withValues(
                      alpha: colors.isDark ? 0.6 : 0.8,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.border.withValues(
                        alpha: colors.isDark ? 0.4 : 0.6,
                      ),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        AppIcons.delete,
                        size: 13,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset Scenario',
                        style: AppTypography.caption1.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // List or Empty State
        if (hypotheticalSessions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.4 : 0.6,
                ),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: colors.isDark ? 0.25 : 0.03,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(
                    AppIcons.insights,
                    size: 19,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Hypothetical Sessions',
                        style: AppTypography.subhead.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add future classes above to model what happens to your attendance.',
                        style: AppTypography.footnote.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.4 : 0.6,
                ),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: colors.isDark ? 0.25 : 0.03,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hypotheticalSessions.length,
              separatorBuilder: (_, _) =>
                  Divider(color: colors.divider.withValues(alpha: 0.6), height: 12),
              itemBuilder: (context, index) {
                final session = hypotheticalSessions[index];
                final subject = subjectMap[session.subjectId];
                final subjectName = subject?.name ?? 'Subject';

                return _HypotheticalRow(
                  session: session,
                  subjectName: subjectName,
                  onToggleStatus: () {
                    ref
                        .read(simulatorControllerProvider.notifier)
                        .toggleSessionStatus(session.id);
                  },
                  onDelete: () {
                    ref
                        .read(simulatorControllerProvider.notifier)
                        .removeSession(session.id);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _HypotheticalRow extends StatelessWidget {
  const _HypotheticalRow({
    required this.session,
    required this.subjectName,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final HypotheticalSession session;
  final String subjectName;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPresent = session.isPresent;

    return Row(
      children: [
        // Component Icon
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppIcon(
            session.component == SessionComponent.lecture
                ? AppIcons.lecture
                : AppIcons.check,
            size: 16,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: 10),

        // Subject & Component label
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subjectName,
                style: AppTypography.subhead.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                session.component == SessionComponent.lecture
                    ? 'Lecture'
                    : 'Lab',
                style: AppTypography.caption1.copyWith(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Interactive Status Pill (tap to flip Present <-> Absent)
        GestureDetector(
          onTap: onToggleStatus,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle.withValues(
                alpha: colors.isDark ? 0.6 : 0.8,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.4 : 0.6,
                ),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  isPresent ? AppIcons.check : AppIcons.close,
                  size: 13,
                  color: isPresent ? colors.present : colors.absent,
                ),
                const SizedBox(width: 5),
                Text(
                  isPresent ? 'Present' : 'Absent',
                  style: AppTypography.caption1.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Delete button (comfortable touch target)
        IconButton(
          tooltip: 'Delete simulated session',
          onPressed: onDelete,
          icon: AppIcon(AppIcons.delete, size: 16, color: colors.textSecondary),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }
}
