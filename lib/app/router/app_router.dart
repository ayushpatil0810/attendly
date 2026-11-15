import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:attendly/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:attendly/features/semesters/presentation/screens/semester_setup_screen.dart';
import 'package:attendly/features/shell/presentation/screens/main_shell_screen.dart';
import 'package:attendly/features/simulator/presentation/screens/simulator_screen.dart';

import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splashPath,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboardingPath,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.semesterSetupPath,
        name: RouteNames.semesterSetup,
        builder: (context, state) => const SemesterSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.homePath,
        name: RouteNames.home,
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: RouteNames.simulatorPath,
        name: RouteNames.simulator,
        builder: (context, state) => const SimulatorScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
  );
});
