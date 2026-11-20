import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/shared/widgets/animated_indexed_stack.dart';

void main() {
  Widget buildTestWidget({
    required int index,
    bool disableAnimations = false,
  }) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp(
        home: Scaffold(
          body: AnimatedIndexedStack(
            index: index,
            duration: const Duration(milliseconds: 200),
            children: const [
              _TestTab(name: 'Tab 0'),
              _TestTab(name: 'Tab 1'),
              _TestTab(name: 'Tab 2'),
            ],
          ),
        ),
      ),
    );
  }

  group('AnimatedIndexedStack Tests', () {
    testWidgets('renders active tab initially', (tester) async {
      await tester.pumpWidget(buildTestWidget(index: 0));
      await tester.pumpAndSettle();

      expect(find.text('Tab 0'), findsOneWidget);
    });

    testWidgets('animates transition smoothly when index changes', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(index: 0));
      await tester.pumpAndSettle();

      // Switch to Tab 1
      await tester.pumpWidget(buildTestWidget(index: 1));

      // Mid-animation frame (after 100ms)
      await tester.pump(const Duration(milliseconds: 100));

      // Tab 1 is now visible and transitioning
      expect(find.text('Tab 1'), findsOneWidget);

      // Finish animation
      await tester.pumpAndSettle();
      expect(find.text('Tab 1'), findsOneWidget);
    });

    testWidgets('preserves state of tabs across switches', (tester) async {
      await tester.pumpWidget(buildTestWidget(index: 0));
      await tester.pumpAndSettle();

      // Increment counter on Tab 0
      await tester.tap(find.byKey(const Key('increment_btn_Tab 0')));
      await tester.pumpAndSettle();
      expect(find.text('Count for Tab 0: 1'), findsOneWidget);

      // Switch to Tab 1
      await tester.pumpWidget(buildTestWidget(index: 1));
      await tester.pumpAndSettle();
      expect(find.text('Tab 1'), findsOneWidget);

      // Switch back to Tab 0
      await tester.pumpWidget(buildTestWidget(index: 0));
      await tester.pumpAndSettle();

      // State is preserved!
      expect(find.text('Count for Tab 0: 1'), findsOneWidget);
    });

    testWidgets('transitions immediately when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(index: 0, disableAnimations: true),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestWidget(index: 2, disableAnimations: true),
      );
      // No extra frames needed; already at destination
      expect(find.text('Tab 2'), findsOneWidget);
    });

    testWidgets('animates reverse transition cleanly (Tab 2 to Tab 0)', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(index: 2));
      await tester.pumpAndSettle();
      expect(find.text('Tab 2'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget(index: 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Tab 0'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Tab 0'), findsOneWidget);
    });
  });
}

class _TestTab extends StatefulWidget {
  const _TestTab({required this.name});
  final String name;

  @override
  State<_TestTab> createState() => _TestTabState();
}

class _TestTabState extends State<_TestTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.name),
        Text('Count for ${widget.name}: $_count'),
        ElevatedButton(
          key: Key('increment_btn_${widget.name}'),
          onPressed: () => setState(() => _count++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
