import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/app/router/route_names.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_motion.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  String? _errorMessage;
  bool _reducedMotionApplied = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _animController.forward();
    // The router is still applying the initial splash route during initState.
    // Navigating now is ignored, which leaves a fresh or restored install
    // on this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeApp();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotionApplied || !AppMotion.reduced(context)) return;
    _reducedMotionApplied = true;
    _animController.duration = Duration.zero;
    _animController.value = 1;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      final hasCompletedOnboarding = ref.read(onboardingCompletedProvider);

      if (!hasCompletedOnboarding) {
        if (mounted) context.go(RouteNames.onboardingPath);
        return;
      }

      // Check if any semesters exist
      final semesterRepo = ref.read(semesterRepositoryProvider);
      final semesters = await semesterRepo.getSemesters(includeArchived: false);

      if (!mounted) return;

      if (semesters.isEmpty) {
        context.go(RouteNames.semesterSetupPath);
      } else {
        context.go(RouteNames.homePath);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Attendly could not open your data.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(scale: _scaleAnimation, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Official Attendly primary splash logo
              Semantics(
                label: 'Attendly Logo',
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 280,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Personal & Offline',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutedInk,
                  letterSpacing: 0.5,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkCoral,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() => _errorMessage = null);
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
