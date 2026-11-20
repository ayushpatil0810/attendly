import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_typography.dart';

import '../providers/dashboard_scope_provider.dart';

/// Apple HIG segmented scope control (Overall vs This Month).
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
    final colors = context.colors;

    return Semantics(
      container: true,
      label:
          'Attendance scope filter: ${selectedScope == DashboardAttendanceScope.overall ? "Overall" : "This Month"} selected',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colors.surfaceSubtle.withValues(
            alpha: colors.isDark ? 0.7 : 0.85,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.border.withValues(alpha: colors.isDark ? 0.3 : 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ScopePillButton(
              label: 'Overall',
              isSelected: selectedScope == DashboardAttendanceScope.overall,
              onTap: () {
                HapticFeedback.selectionClick();
                onScopeChanged(DashboardAttendanceScope.overall);
              },
            ),
            _ScopePillButton(
              label: 'This Month',
              isSelected: selectedScope == DashboardAttendanceScope.thisMonth,
              onTap: () {
                HapticFeedback.selectionClick();
                onScopeChanged(DashboardAttendanceScope.thisMonth);
              },
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
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? (colors.isDark ? const Color(0xFF3A3A3C) : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: colors.isDark ? 0.3 : 0.08,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: AppTypography.footnote.copyWith(
                color: isSelected ? colors.textPrimary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
