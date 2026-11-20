import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/shared/widgets/attendly_brand_mark.dart';
import 'package:attendly/core/theme/app_palettes.dart';

void main() {
  testWidgets('AttendlyBrandMark renders with custom size and semantic label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AttendlyBrandMark(size: 80, semanticLabel: 'App Icon'),
        ),
      ),
    );

    final finder = find.byType(AttendlyBrandMark);
    expect(finder, findsOneWidget);

    final size = tester.getSize(finder);
    expect(size.width, equals(80));
    expect(size.height, equals(80));

    expect(find.bySemanticsLabel('App Icon'), findsOneWidget);
  });

  testWidgets('AttendlyBrandMark adopts theme colors from context extension', (
    tester,
  ) async {
    final themeColors = AppPalettes.oceanBreezeLight;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [themeColors]),
        home: const Scaffold(
          body: AttendlyBrandMark(
            size: 64,
            checkmarkProgress: 0.5,
          ),
        ),
      ),
    );

    expect(find.byType(AttendlyBrandMark), findsOneWidget);
  });
}
