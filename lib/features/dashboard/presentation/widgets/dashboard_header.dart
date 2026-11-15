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
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.mutedInk,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () {
                  showAppBottomSheet(
                    context: context,
                    title: 'Semesters',
                    child: const SemesterSwitcherSheet(),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        semester.name,
                        style: AppTypography.screenTitle.copyWith(fontSize: 22),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 22,
                      color: AppColors.brandViolet,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          label: 'Open settings',
          button: true,
          child: GestureDetector(
            onTap: () {
              context.pushNamed(RouteNames.settings);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.softLavender,
                shape: BoxShape.circle,
              ),
              child: const AppIcon(
                AppIcons.settings,
                size: 20,
                color: AppColors.brandViolet,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
