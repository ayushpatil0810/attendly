import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/simulator/presentation/providers/simulator_providers.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

class SimulatorInputPanel extends ConsumerStatefulWidget {
  const SimulatorInputPanel({super.key});

  @override
  ConsumerState<SimulatorInputPanel> createState() =>
      _SimulatorInputPanelState();
}

class _SimulatorInputPanelState extends ConsumerState<SimulatorInputPanel> {
  int? _selectedSubjectId;
  SessionComponent _selectedComponent = SessionComponent.lecture;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final subjects = subjectsAsync.asData?.value ?? [];

    if (subjects.isEmpty) {
      return Container(
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
        ),
        child: Text(
          'Please create at least one subject to start simulating future attendance.',
          style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
        ),
      );
    }

    // Default to first subject if not set or invalid
    if (_selectedSubjectId == null ||
        !subjects.any((s) => s.id == _selectedSubjectId)) {
      _selectedSubjectId = subjects.first.id;
    }

    final currentSubject = subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => subjects.first,
    );

    // Auto-select valid component
    if (!currentSubject.lectureEnabled && currentSubject.labEnabled) {
      _selectedComponent = SessionComponent.lab;
    } else if (currentSubject.lectureEnabled && !currentSubject.labEnabled) {
      _selectedComponent = SessionComponent.lecture;
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Hypothetical Classes',
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a subject and component, then add future class outcomes.',
            style: AppTypography.footnote.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          // Subject Selection Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: subjects.map((s) {
                final isSelected = s.id == _selectedSubjectId;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSubjectId = s.id;
                        if (!s.lectureEnabled && s.labEnabled) {
                          _selectedComponent = SessionComponent.lab;
                        } else if (s.lectureEnabled && !s.labEnabled) {
                          _selectedComponent = SessionComponent.lecture;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (colors.isDark ? Colors.white : colors.brandPrimary)
                            : colors.surfaceSubtle.withValues(
                                alpha: colors.isDark ? 0.6 : 0.8,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : colors.border.withValues(
                                  alpha: colors.isDark ? 0.4 : 0.6,
                                ),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        s.name,
                        style: AppTypography.caption1.copyWith(
                          color: isSelected
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Component Selection (if both enabled)
          if (currentSubject.lectureEnabled && currentSubject.labEnabled) ...[
            Row(
              children: [
                _ComponentChoicePill(
                  label: 'Lecture',
                  isSelected: _selectedComponent == SessionComponent.lecture,
                  onTap: () => setState(
                    () => _selectedComponent = SessionComponent.lecture,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _ComponentChoicePill(
                  label: 'Lab',
                  isSelected: _selectedComponent == SessionComponent.lab,
                  onTap: () =>
                      setState(() => _selectedComponent = SessionComponent.lab),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Quick Action Add Buttons (+1 Present / +1 Absent)
          Row(
            children: [
              Expanded(
                child: _SimulateActionButton(
                  label: '+1 Present',
                  iconColor: colors.present,
                  icon: AppIcons.check,
                  onTap: () {
                    ref
                        .read(simulatorControllerProvider.notifier)
                        .addSession(
                          subjectId: _selectedSubjectId!,
                          component: _selectedComponent,
                          status: AttendanceStatus.present,
                        );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SimulateActionButton(
                  label: '+1 Absent',
                  iconColor: colors.absent,
                  icon: AppIcons.close,
                  onTap: () {
                    ref
                        .read(simulatorControllerProvider.notifier)
                        .addSession(
                          subjectId: _selectedSubjectId!,
                          component: _selectedComponent,
                          status: AttendanceStatus.absent,
                        );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Batch Add Chips (+3 Present, +5 Present)
          Row(
            children: [
              Text(
                'Batch add:',
                style: AppTypography.caption1.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(width: 8),
              _BatchChip(
                label: '+3 Present',
                onTap: () {
                  ref
                      .read(simulatorControllerProvider.notifier)
                      .addMultipleSessions(
                        subjectId: _selectedSubjectId!,
                        component: _selectedComponent,
                        status: AttendanceStatus.present,
                        count: 3,
                      );
                },
              ),
              const SizedBox(width: 6),
              _BatchChip(
                label: '+5 Present',
                onTap: () {
                  ref
                      .read(simulatorControllerProvider.notifier)
                      .addMultipleSessions(
                        subjectId: _selectedSubjectId!,
                        component: _selectedComponent,
                        status: AttendanceStatus.present,
                        count: 5,
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComponentChoicePill extends StatelessWidget {
  const _ComponentChoicePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? colors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.textPrimary : colors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption1.copyWith(
            color: isSelected ? colors.textPrimary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _SimulateActionButton extends StatelessWidget {
  const _SimulateActionButton({
    required this.label,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surfaceSubtle.withValues(
        alpha: colors.isDark ? 0.6 : 0.8,
      ),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.border.withValues(
                alpha: colors.isDark ? 0.4 : 0.6,
              ),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.subhead.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchChip extends StatelessWidget {
  const _BatchChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surfaceSubtle.withValues(
        alpha: colors.isDark ? 0.6 : 0.8,
      ),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.border.withValues(
                alpha: colors.isDark ? 0.4 : 0.6,
              ),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: colors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
