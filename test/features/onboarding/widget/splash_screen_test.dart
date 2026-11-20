import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/core/shared/widgets/attendly_brand_mark.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:attendly/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:attendly/features/semesters/data/repositories/semester_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: SplashScreen()),
    );
  }

  testWidgets('SplashScreen renders brand mark and attendly wordmark', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AttendlyBrandMark), findsOneWidget);
    expect(find.text('attendly'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('cleared data leaves the splash screen for onboarding', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Text('Onboarding'),
        ),
        GoRoute(
          path: '/semester-setup',
          builder: (context, state) => const Text('Semester setup'),
        ),
        GoRoute(path: '/home', builder: (context, state) => const Text('Home')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Onboarding'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('restored semesters leave the splash screen for home', (
    tester,
  ) async {
    await prefs.setBool('has_completed_onboarding_v1', true);
    final semesters = SemesterRepositoryImpl(db);
    await semesters.createSemester(name: 'Fall 2026');

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Text('Onboarding'),
        ),
        GoRoute(
          path: '/semester-setup',
          builder: (context, state) => const Text('Semester setup'),
        ),
        GoRoute(path: '/home', builder: (context, state) => const Text('Home')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets(
    'SplashScreen stays visible during minDisplayDuration before navigating',
    (tester) async {
      await prefs.setBool('has_completed_onboarding_v1', true);
      final semesters = SemesterRepositoryImpl(db);
      await semesters.createSemester(name: 'Fall 2026');

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Text('Home'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      // At 500ms, splash should still be visible and not yet navigated to Home
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('attendly'), findsOneWidget);
      expect(find.text('Home'), findsNothing);

      // After full min duration and exit transition, Home is visible
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );
}
