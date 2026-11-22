import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';

void main() {
  testWidgets(
    'DashboardHeader renders title and active semester switcher without redundant gear icon',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
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
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('attendly'), findsOneWidget);
      expect(find.text('Spring 2026'), findsOneWidget);
      // Redundant settings icon is removed since Settings is now a top-level dock tab
      expect(find.bySemanticsLabel('Open settings'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );
}
