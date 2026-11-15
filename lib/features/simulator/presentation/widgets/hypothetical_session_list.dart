import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
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
            Text(
              'Simulated Classes (${hypotheticalSessions.length})',
              style: AppTypography.sectionTitle,
            ),
            if (hypotheticalSessions.isNotEmpty)
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
                    color: AppColors.softCoral,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        AppIcons.delete,
                        size: 14,
                        color: AppColors.brandCoral,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset Scenario',
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFFD63B48),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // List or Empty State
        if (hypotheticalSessions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: AppRadius.xlBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.softLavender,
                    shape: BoxShape.circle,
                  ),
                  child: const AppIcon(
                    AppIcons.insights,
                    size: 20,
                    color: AppColors.brandViolet,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No Hypothetical Sessions',
                        style: AppTypography.itemTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add future classes above to model what happens to your attendance.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.mutedInk,
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
              color: AppColors.pureWhite,
              borderRadius: AppRadius.xlBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hypotheticalSessions.length,
              separatorBuilder: (_, _) =>
                  Divider(color: AppColors.divider, height: 12),
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
    final isPresent = session.isPresent;

    return Row(
      children: [
        // Component Icon
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.track,
            borderRadius: AppRadius.smBorder,
          ),
          child: AppIcon(
            session.component == SessionComponent.lecture
                ? AppIcons.lecture
                : AppIcons.check,
            size: 16,
            color: AppColors.ink,
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
                style: AppTypography.itemTitle.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                session.component == SessionComponent.lecture
                    ? 'Lecture'
                    : 'Lab',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedInk,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        // Interactive Status Pill (tap to flip Present <-> Absent)
        GestureDetector(
          onTap: onToggleStatus,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPresent ? AppColors.softMint : AppColors.softCoral,
              borderRadius: AppRadius.pillBorder,
              border: Border.all(
                color: isPresent
                    ? AppColors.brandMint.withOpacity(0.5)
                    : AppColors.brandCoral.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  isPresent ? AppIcons.check : AppIcons.close,
                  size: 12,
                  color: isPresent ? AppColors.brandMint : AppColors.brandCoral,
                ),
                const SizedBox(width: 4),
                Text(
                  isPresent ? 'Present' : 'Absent',
                  style: AppTypography.labelSmall.copyWith(
                    color: isPresent
                        ? const Color(0xFF1E826D)
                        : const Color(0xFFD63B48),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Delete button
        IconButton(
          onPressed: onDelete,
          icon: const AppIcon(
            AppIcons.delete,
            size: 16,
            color: AppColors.mutedInk,
          ),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}
