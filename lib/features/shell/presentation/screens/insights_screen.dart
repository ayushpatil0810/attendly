import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.screenTop,
            bottom: AppSpacing.dockClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Insights', style: AppTypography.screenTitle),
              const SizedBox(height: 4),
              Text('Analytics & Projections', style: AppTypography.bodySmall),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: AppRadius.xlBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.softMint,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const AppIcon(
                        AppIcons.insights,
                        size: 32,
                        color: AppColors.brandMint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analytics & Simulator (Phases 3 & 4)',
                      style: AppTypography.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'In-depth attendance visualizations, safe-absence calculators, and the What-if Simulator will be enabled once attendance logging is established.',
                      style: AppTypography.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _InsightBullet(
                      icon: AppIcons.insights,
                      text: 'Overall attendance donut with threshold target indicators',
                    ),
                    const SizedBox(height: 12),
                    _InsightBullet(
                      icon: AppIcons.lecture,
                      text:
                          'Independent Lecture vs Lab performance comparisons',
                    ),
                    const SizedBox(height: 12),
                    _InsightBullet(
                      icon: AppIcons.check,
                      text: 'Safe absences and required consecutive recovery days',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightBullet extends StatelessWidget {
  const _InsightBullet({required this.icon, required this.text});

  final dynamic icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.track,
            borderRadius: AppRadius.smBorder,
          ),
          child: AppIcon(icon, size: 16, color: AppColors.ink),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTypography.bodySmall)),
      ],
    );
  }
}
