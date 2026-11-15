import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/app_segmented_control.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/insights/presentation/widgets/insights_content.dart';
import 'package:attendly/features/simulator/presentation/screens/simulator_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.screenTop,
            bottom: AppSpacing.dockClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTab == 0 ? 'Insights' : 'Simulator',
                        style: AppTypography.screenTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedTab == 0
                            ? 'Attendance analytics & patterns'
                            : 'What-if hypothetical modeling',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Segmented Switcher: [Insights] [Simulator]
              AppSegmentedControl<int>(
                selectedValue: _selectedTab,
                onChanged: (val) => setState(() => _selectedTab = val),
                items: const [
                  SegmentItem(
                    value: 0,
                    label: 'Insights',
                    icon: AppIcon(AppIcons.insights, size: 16),
                  ),
                  SegmentItem(
                    value: 1,
                    label: 'Simulator',
                    icon: AppIcon(AppIcons.calendar, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Active Tab Content
              if (_selectedTab == 0)
                const InsightsContent()
              else
                const SimulatorContent(),
            ],
          ),
        ),
      ),
    );
  }
}
