import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Centers a phone-width column once the window is wider than a phone.
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  /// Material medium window: a rail replaces the bottom dock.
  static bool useSideRail(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, maxWidth);
        final height = constraints.maxHeight;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: height.isFinite ? height : null,
            child: child,
          ),
        );
      },
    );
  }
}
