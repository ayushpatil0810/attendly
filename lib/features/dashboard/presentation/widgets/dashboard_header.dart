import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/app/router/route_names.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'College Attendance',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Semantics(
                button: true,
                label: 'Switch active semester, currently ${semester.name}',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showAppBottomSheet(
                        context: context,
                        title: 'Semesters',
                        child: const SemesterSwitcherSheet(),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              semester.name,
                              style: AppTypography.screenTitle.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const AppIcon(
                            AppIcons.arrowDown,
                            size: 18,
                            color: AppColors.brandViolet,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          label: 'Open settings',
          button: true,
          child: Tooltip(
            message: 'Settings',
            child: Material(
              color: AppColors.softLavender,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  context.pushNamed(RouteNames.settings);
                },
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AppIcon(
                      AppIcons.settings,
                      size: 20,
                      color: AppColors.brandViolet,
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
