import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_switcher_sheet.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.semester});

  final Semester semester;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Application name with Apple-inspired typography
          Text(
            'attendly',
            style: AppTypography.title2.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),

          // Right: Active semester switcher in a clean iOS capsule pill
          Flexible(
            child: Semantics(
              button: true,
              label: 'Switch active semester, currently ${semester.name}',
              child: Material(
                color: colors.surfaceSubtle.withValues(
                  alpha: colors.isDark ? 0.6 : 0.8,
                ),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    showAppBottomSheet(
                      context: context,
                      title: 'Semesters',
                      child: const SemesterSwitcherSheet(),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
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
                        Flexible(
                          child: Text(
                            semester.name,
                            style: AppTypography.subhead.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AppIcon(
                          AppIcons.arrowDown,
                          size: 13,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
