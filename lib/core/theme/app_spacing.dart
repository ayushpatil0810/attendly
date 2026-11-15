import 'package:flutter/material.dart';

/// 8-point spacing rhythm tokens according to DESIGN.md
abstract final class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;

  // Screen horizontal padding
  static const double screenHorizontal = 20.0;
  // Screen top padding
  static const double screenTop = 16.0;
  // Dock bottom clearance
  static const double dockClearance = 100.0;

  // Common insets
  static const double cardPadding = 16.0;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  static const EdgeInsets screenPaddingWithTop = EdgeInsets.only(
    left: screenHorizontal,
    right: screenHorizontal,
    top: screenTop,
  );
}
