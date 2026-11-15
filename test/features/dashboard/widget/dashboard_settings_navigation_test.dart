import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/app/router/route_names.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';

void main() {
  testWidgets('DashboardHeader settings button navigates to settings route', (
    tester,
  ) async {
    var navigatedToSettings = false;

    final testRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: DashboardHeader(
              semester: Semester(
                id: 1,
                name: 'Spring 2026',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.settingsPath,
          name: RouteNames.settings,
          builder: (context, state) {
            navigatedToSettings = true;
            return const Scaffold(body: Text('Settings Destination Screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: testRouter)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spring 2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Open settings'), findsOneWidget);

    // Tap settings button
    await tester.tap(find.bySemanticsLabel('Open settings'));
    await tester.pumpAndSettle();

    expect(navigatedToSettings, isTrue);
    expect(find.text('Settings Destination Screen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
