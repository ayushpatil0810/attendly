import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/theme/app_colors.dart';
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

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      title: 'Track Lectures & Labs',
      subtitle: 'Record attendance for theory classes and practical labs independently with one quick tap.',
      accentColor: AppColors.brandViolet,
      secondaryColor: AppColors.softLavender,
      icon: AppIcons.lecture,
      tagText: 'Independent Components',
    ),
    _OnboardingPageData(
      title: 'Know Your Safe Absences',
      subtitle: 'Stay above your college threshold. Always know how many sessions you can safely miss.',
      accentColor: AppColors.brandMint,
      secondaryColor: AppColors.softMint,
      icon: AppIcons.insights,
      tagText: 'Smart Calculations',
    ),
    _OnboardingPageData(
      title: 'Review & Correct History',
      subtitle: 'Keep a transparent timeline. Correct past records anytime with 100% offline local privacy.',
      accentColor: AppColors.brandPeach,
      secondaryColor: AppColors.softPeach,
      icon: AppIcons.history,
      tagText: '100% Offline & Private',
    ),
  ];

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

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App identity hint
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.brandViolet,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Attendance Tracker',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.mutedInk,
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
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
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
                            color: page.secondaryColor,
                            borderRadius: AppRadius.pillBorder,
                          ),
                          child: Text(
                            page.tagText,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.ink,
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
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.brandViolet
                              : AppColors.divider,
                          borderRadius: AppRadius.pillBorder,
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Action button
                  AppButton(
                    label: isLastPage ? 'Get Started' : 'Next',
                    onPressed: _nextPage,
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
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: page.secondaryColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: page.accentColor.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AppIcon(page.icon, size: 52, color: page.accentColor),
      ),
    );
  }
}
