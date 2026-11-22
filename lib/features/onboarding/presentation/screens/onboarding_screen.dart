import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/core/services/notification_service.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_theme_colors.dart';
import 'package:attendly/core/theme/app_motion.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).requestPermissions();
    });
  }

  List<_OnboardingPageData> _getPages(AppThemeColors colors) {
    return [
      _OnboardingPageData(
        title: 'Track Lectures & Labs',
        subtitle:
            'Record attendance for theory classes and practical labs independently with one quick tap.',
        accentColor: colors.brandPrimary,
        secondaryColor: colors.brandPrimary.withValues(alpha: 0.16),
        icon: AppIcons.lecture,
        tagText: 'Independent Components',
      ),
      _OnboardingPageData(
        title: 'Know Your Safe Absences',
        subtitle:
            'Stay above your college threshold. Always know how many sessions you can safely miss.',
        accentColor: colors.accentGreen,
        secondaryColor: colors.accentGreen.withValues(alpha: 0.16),
        icon: AppIcons.insights,
        tagText: 'Smart Calculations',
      ),
      _OnboardingPageData(
        title: 'Review & Correct History',
        subtitle:
            'Keep a transparent timeline. Correct past records anytime with 100% offline local privacy.',
        accentColor: colors.accentOrange,
        secondaryColor: colors.accentOrange.withValues(alpha: 0.16),
        icon: AppIcons.history,
        tagText: '100% Offline & Private',
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/semester-setup');
    }
  }

  void _nextPage(int pageCount) {
    if (_currentPage < pageCount - 1) {
      _pageController.nextPage(
        duration: AppMotion.duration(
          context,
          const Duration(milliseconds: 260),
        ),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pages = _getPages(colors);
    final isLastPage = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Brand and Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Application name with Apple-inspired typography (matching dashboard)
                  Semantics(
                    label: 'Attendly',
                    child: Text(
                      'attendly',
                      style: AppTypography.title2.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: AppTypography.labelLarge.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Custom visual illustration container
                        _OnboardingVisual(page: page),
                        const SizedBox(height: 36),
                        // Pill tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceSubtle.withValues(
                              alpha: colors.isDark ? 0.6 : 0.8,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.border.withValues(
                                alpha: colors.isDark ? 0.4 : 0.6,
                              ),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            page.tagText,
                            style: AppTypography.labelSmall.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          page.title,
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 24,
                            color: colors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          page.subtitle,
                          style: AppTypography.bodyMuted.copyWith(
                            fontSize: 15,
                            height: 1.45,
                            color: colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Progress Dots
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Dot indicators
                  Row(
                    children: List.generate(pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: AppMotion.duration(
                          context,
                          const Duration(milliseconds: 200),
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colors.brandPrimary
                              : colors.track,
                          borderRadius: AppRadius.pillBorder,
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Action button
                  AppButton(
                    label: isLastPage ? 'Get Started' : 'Next',
                    onPressed: () => _nextPage(pages.length),
                    size: AppButtonSize.medium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.secondaryColor,
    required this.icon,
    required this.tagText,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final Color secondaryColor;
  final dynamic icon;
  final String tagText;
}

class _OnboardingVisual extends StatelessWidget {
  const _OnboardingVisual({required this.page});

  final _OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: colors.surfaceSubtle.withValues(
          alpha: colors.isDark ? 0.4 : 0.6,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.border.withValues(
            alpha: colors.isDark ? 0.35 : 0.5,
          ),
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.border.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : page.accentColor.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AppIcon(
          page.icon,
          size: 52,
          color: page.accentColor,
        ),
      ),
    );
  }
}
