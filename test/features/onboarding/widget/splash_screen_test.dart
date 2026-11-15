import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendly/core/database/app_database.dart';
import 'package:attendly/core/providers/database_provider.dart';
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

  testWidgets('SplashScreen renders logo and personal offline caption', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Personal & Offline'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('cleared data leaves the splash screen for onboarding', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Text('Onboarding'),
        ),
        GoRoute(
          path: '/semester-setup',
          builder: (context, state) => const Text('Semester setup'),
        ),
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
    await tester.pump();
    await tester.pump();

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
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Text('Onboarding'),
        ),
        GoRoute(
          path: '/semester-setup',
          builder: (context, state) => const Text('Semester setup'),
        ),
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
    await tester.pump();
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
