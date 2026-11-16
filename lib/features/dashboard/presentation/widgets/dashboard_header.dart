import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/app/router/route_names.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_switcher_sheet.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.semester});

  final Semester semester;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Application name in lowercase (replaces "College Attendance")
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'attendly',
              style: AppTypography.screenTitle.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: AppColors.brandViolet,
              ),
            ),
          ),
        ),

        // Centre: Active semester switcher
        Expanded(
          flex: 2,
          child: Center(
            child: Semantics(
              button: true,
              label: 'Switch active semester, currently ${semester.name}',
              child: Material(
                color: AppColors.softLavender.withValues(alpha: 0.6),
                borderRadius: AppRadius.pillBorder,
                child: InkWell(
                  onTap: () {
                    showAppBottomSheet(
                      context: context,
                      title: 'Semesters',
                      child: const SemesterSwitcherSheet(),
                    );
                  },
                  borderRadius: AppRadius.pillBorder,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            semester.name,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const AppIcon(
                          AppIcons.arrowDown,
                          size: 16,
                          color: AppColors.inkViolet,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Right: Settings icon action (comfortably sized)
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              label: 'Open settings',
              button: true,
              child: Tooltip(
                message: 'Settings',
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {
                      context.pushNamed(RouteNames.settings);
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: const AppIcon(
                        AppIcons.settings,
                        size: 23,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
