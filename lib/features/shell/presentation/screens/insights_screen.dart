import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/app/router/route_names.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/insights/presentation/widgets/insights_content.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.screenTop,
            bottom: AppSpacing.dockClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Insights', style: AppTypography.screenTitle),
                        const SizedBox(height: 2),
                        Text(
                          'Attendance analytics & patterns',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.mutedInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(RouteNames.simulatorPath),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: AppColors.inkViolet,
                    ),
                    child: const Text('What-if'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const InsightsContent(),
            ],
          ),
        ),
      ),
    );
  }
}
