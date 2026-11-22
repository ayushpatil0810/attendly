import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/app/router/route_names.dart';
import 'package:attendly/core/shared/widgets/attendly_brand_mark.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_motion.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 1400),
  });

  /// The minimum duration the splash screen remains visible to ensure
  /// a polished branding presentation and prevent instant dismissal.
  final Duration minDisplayDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _exitController;

  late final Animation<Offset> _symbolSlide;
  late final Animation<double> _symbolFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _checkAnimation;

  Timer? _splashTimer;
  String? _errorMessage;
  bool _reducedMotionApplied = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );

    // Symbol slides gently in from left and fades in
    _symbolSlide = Tween<Offset>(
      begin: const Offset(-0.35, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _symbolFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOut),
      ),
    );

    // Wordmark "attendly" slides in from right and meets the symbol
    _textSlide = Tween<Offset>(
      begin: const Offset(0.35, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.70, curve: Curves.easeOutCubic),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.55, curve: Curves.easeOut),
      ),
    );

    // Checkmark draws smoothly once the calendar symbol has settled
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
    // Pre-warm data and initialize navigation once the first frame is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeApp();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotionApplied || !AppMotion.reduced(context)) return;
    _reducedMotionApplied = true;
    _entranceController.duration = Duration.zero;
    _entranceController.value = 1.0;
    _exitController.duration = Duration.zero;
    _exitController.value = 1.0;
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _waitRemaining(DateTime startTime) async {
    final targetDuration = AppMotion.reduced(context)
        ? Duration.zero
        : widget.minDisplayDuration;
    if (targetDuration == Duration.zero) return;

    final elapsed = DateTime.now().difference(startTime);
    final remaining = targetDuration - elapsed;
    if (remaining > Duration.zero) {
      final completer = Completer<void>();
      _splashTimer = Timer(remaining, () {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
    }
  }

  void _prewarmDashboardData() {
    try {
      // Warm up and subscribe to the core streams in the background
      // so their SQLite queries run in parallel during the splash window
      ref.read(activeSemestersStreamProvider);
      ref.read(activeSemesterProvider);
      ref.read(activeSemesterSubjectsProvider);
      ref.read(activeSemesterSessionsStreamProvider);
      ref.read(semesterAttendanceSummaryProvider);
    } catch (_) {
      // Non-fatal: if pre-warming encounters an issue, screens fall back to reactive loading
    }
  }

  Future<void> _initializeApp() async {
    try {
      final startTime = DateTime.now();

      final hasCompletedOnboarding = ref.read(onboardingCompletedProvider);

      if (!hasCompletedOnboarding) {
        await _waitRemaining(startTime);
        if (mounted) context.go(RouteNames.onboardingPath);
        return;
      }

      // Check if any semesters exist
      final semesterRepo = ref.read(semesterRepositoryProvider);
      final semesters = await semesterRepo.getSemesters(includeArchived: false);

      if (!mounted) return;

      if (semesters.isEmpty) {
        await _waitRemaining(startTime);
        if (mounted) context.go(RouteNames.semesterSetupPath);
        return;
      }

      // Pre-warm dashboard streams so data resolves during the splash delay
      _prewarmDashboardData();

      // Wait for minimum splash duration
      await _waitRemaining(startTime);

      if (!mounted) return;

      // Gentle master fade-out transition to seamlessly dissolve into the dashboard
      if (!AppMotion.reduced(context) &&
          widget.minDisplayDuration > Duration.zero) {
        await _exitController.reverse();
      }

      if (mounted) {
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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: FadeTransition(
          opacity: _exitController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Side-by-side brand mark & wordmark lockup coming together
              AnimatedBuilder(
                animation: _entranceController,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Theme-adaptive calendar symbol
                      SlideTransition(
                        position: _symbolSlide,
                        child: FadeTransition(
                          opacity: _symbolFade,
                          child: AttendlyBrandMark(
                            size: 52,
                            checkmarkProgress: _checkAnimation.value,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Styled "attendly" wordmark matching dashboard navbar
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textFade,
                          child: Text(
                            'attendly',
                            style: AppTypography.screenTitle.copyWith(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.4,
                              color: colors.brandPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.accentRed,
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
