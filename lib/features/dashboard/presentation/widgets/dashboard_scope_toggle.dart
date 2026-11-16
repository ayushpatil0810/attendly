import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import '../providers/dashboard_scope_provider.dart';

class DashboardScopeToggle extends StatelessWidget {
  const DashboardScopeToggle({
    super.key,
    required this.selectedScope,
    required this.onScopeChanged,
  });

  final DashboardAttendanceScope selectedScope;
  final ValueChanged<DashboardAttendanceScope> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Attendance scope filter: ${selectedScope == DashboardAttendanceScope.overall ? "Overall" : "This Month"} selected',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.softLavender.withValues(alpha: 0.5),
          borderRadius: AppRadius.pillBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ScopePillButton(
              label: 'Overall',
              isSelected: selectedScope == DashboardAttendanceScope.overall,
              onTap: () => onScopeChanged(DashboardAttendanceScope.overall),
            ),
            _ScopePillButton(
              label: 'This Month',
              isSelected: selectedScope == DashboardAttendanceScope.thisMonth,
              onTap: () => onScopeChanged(DashboardAttendanceScope.thisMonth),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopePillButton extends StatelessWidget {
  const _ScopePillButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.pillBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pillBorder,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.pureWhite : Colors.transparent,
              borderRadius: AppRadius.pillBorder,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.inkViolet : AppColors.mutedInk,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
