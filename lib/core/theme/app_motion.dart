import 'package:flutter/material.dart';

/// Motion and haptic constants adhering to Apple's Human Interface Guidelines.
abstract final class AppMotion {
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  // Canonical Apple HIG Durations
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration sheet = Duration(milliseconds: 320);

  // Canonical Apple HIG Curves
  static const Curve spring = Curves.easeOutCubic;
  static const Curve entrance = Curves.fastOutSlowIn;
  static const Curve exit = Curves.easeInCubic;

  // Interactive scale on touch
  static const double pressScale = 0.97;
}
