import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/theme/app_theme.dart';
import 'package:attendly/features/settings/presentation/widgets/about_attendly_sheet.dart';
import 'package:attendly/features/settings/presentation/widgets/about_section.dart';

Widget _buildTestApp({required Widget child, Brightness brightness = Brightness.light}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AboutSection Widget Tests', () {
    testWidgets('renders section header, tile title, subtitle, and disclosure caret', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const SingleChildScrollView(
            child: AboutSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
      expect(find.text('About Attendly'), findsOneWidget);
      expect(find.text('Developer, website & source code'), findsOneWidget);
    });

    testWidgets('tapping tile opens AboutAttendlySheet bottom sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const SingleChildScrollView(
            child: AboutSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('About Attendly'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutAttendlySheet), findsOneWidget);
      expect(find.text('Ayush Patil'), findsOneWidget);
      expect(find.text('ayushpatil.in'), findsOneWidget);
      expect(find.text('@ayushpatil0810'), findsOneWidget);
      expect(find.text('ayushpatil0810/attendly'), findsOneWidget);
    });
  });

  group('AboutAttendlySheet Widget Tests', () {
    testWidgets('renders developer attribution, website, and github links', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          child: const SingleChildScrollView(
            child: AboutAttendlySheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendly'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);

      expect(find.text('DEVELOPER'), findsOneWidget);
      expect(find.text('Ayush Patil'), findsOneWidget);
      expect(find.text('Creator & Developer'), findsOneWidget);
      expect(find.text('Website'), findsOneWidget);
      expect(find.text('ayushpatil.in'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('@ayushpatil0810'), findsOneWidget);

      expect(find.text('OPEN SOURCE'), findsOneWidget);
      expect(find.text('Source Code'), findsOneWidget);
      expect(find.text('ayushpatil0810/attendly'), findsOneWidget);
      expect(find.text('License'), findsOneWidget);
      expect(find.text('MIT License'), findsOneWidget);

      expect(find.text('100% Offline & Private • Zero Trackers'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark theme without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          brightness: Brightness.dark,
          child: const SingleChildScrollView(
            child: AboutAttendlySheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ayush Patil'), findsOneWidget);
      expect(find.text('ayushpatil.in'), findsOneWidget);
    });

    testWidgets('tapping close button dismisses sheet when opened as modal bottom sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showAboutAttendlySheet(context),
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutAttendlySheet), findsOneWidget);

      await tester.tap(find.byType(AppCloseButton));
      await tester.pumpAndSettle();

      expect(find.byType(AboutAttendlySheet), findsNothing);
    });

    testWidgets('tapping Done dismisses sheet when scrolled into view', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showAboutAttendlySheet(context),
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutAttendlySheet), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Done'), 100);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutAttendlySheet), findsNothing);
    });
  });
}
