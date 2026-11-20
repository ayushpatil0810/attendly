import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/theme/app_theme.dart';

void main() {
  group('AppButton High Contrast Tests', () {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final isDark = brightness == Brightness.dark;
      final modeName = isDark ? 'Dark Mode' : 'Light Mode';

      testWidgets(
        'All AppButton variants have high contrast in $modeName',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.buildTheme(brightness),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      AppButton(
                        key: const Key('btn_primary'),
                        label: 'Primary Action',
                        variant: AppButtonVariant.primary,
                        onPressed: () {},
                      ),
                      AppButton(
                        key: const Key('btn_secondary'),
                        label: 'Secondary Action',
                        variant: AppButtonVariant.secondary,
                        onPressed: () {},
                      ),
                      AppButton(
                        key: const Key('btn_outline'),
                        label: 'Outline Action',
                        variant: AppButtonVariant.outline,
                        onPressed: () {},
                      ),
                      AppButton(
                        key: const Key('btn_text'),
                        label: 'Text Action',
                        variant: AppButtonVariant.text,
                        onPressed: () {},
                      ),
                      AppButton(
                        key: const Key('btn_destructive'),
                        label: 'Destructive Action',
                        variant: AppButtonVariant.destructive,
                        onPressed: () {},
                      ),
                      AppButton(
                        key: const Key('btn_disabled'),
                        label: 'Disabled Action',
                        variant: AppButtonVariant.primary,
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          // 1. Primary button check
          final primaryContainer = tester.widget<Container>(
            find.descendant(
              of: find.byKey(const Key('btn_primary')),
              matching: find.byType(Container),
            ),
          );
          final primaryDecoration =
              primaryContainer.decoration as BoxDecoration;
          final primaryBg = primaryDecoration.color!;
          final primaryText = tester.widget<Text>(
            find.descendant(
              of: find.byKey(const Key('btn_primary')),
              matching: find.byType(Text),
            ),
          );
          final primaryFg = primaryText.style!.color!;

          // Ensure primary foreground and background are not the same color
          expect(
            primaryFg,
            isNot(equals(primaryBg)),
            reason:
                'Primary button text must never match its background in $modeName',
          );

          if (isDark) {
            // In dark mode: white/light button with black/dark text
            expect(primaryBg.computeLuminance(), greaterThan(0.5));
            expect(primaryFg.computeLuminance(), lessThan(0.1));
          } else {
            // In light mode: dark button with white text
            expect(primaryBg.computeLuminance(), lessThan(0.1));
            expect(primaryFg.computeLuminance(), greaterThan(0.8));
          }

          // 2. Destructive button check
          final destText = tester.widget<Text>(
            find.descendant(
              of: find.byKey(const Key('btn_destructive')),
              matching: find.byType(Text),
            ),
          );
          final destContainer = tester.widget<Container>(
            find.descendant(
              of: find.byKey(const Key('btn_destructive')),
              matching: find.byType(Container),
            ),
          );
          final destBg = (destContainer.decoration as BoxDecoration).color!;
          final destFg = destText.style!.color!;
          expect(destFg, isNot(equals(destBg)));

          // 3. Secondary button check
          final secText = tester.widget<Text>(
            find.descendant(
              of: find.byKey(const Key('btn_secondary')),
              matching: find.byType(Text),
            ),
          );
          final secContainer = tester.widget<Container>(
            find.descendant(
              of: find.byKey(const Key('btn_secondary')),
              matching: find.byType(Container),
            ),
          );
          final secBg = (secContainer.decoration as BoxDecoration).color!;
          final secFg = secText.style!.color!;
          expect(secFg, isNot(equals(secBg)));
        },
      );
    }
  });
}
