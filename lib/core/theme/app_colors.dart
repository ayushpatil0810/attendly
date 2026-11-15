import 'package:flutter/material.dart';

/// Centralized color tokens according to DESIGN.md
abstract final class AppColors {
  // Brand Palette
  static const Color brandViolet = Color(0xFF9278F2);
  static const Color brandMint = Color(0xFF8BE4D0);
  static const Color brandCoral = Color(0xFFFF929B);
  static const Color brandPeach = Color(0xFFFFB49F);
  static const Color lavender = Color(0xFFB9A0F2);

  /// Readable text and small icons. Same hues as the pastels, darkened so
  /// body copy clears 4.5:1 on white and on the soft tinted surfaces.
  static const Color inkViolet = Color(0xFF704EEE);
  static const Color inkMint = Color(0xFF166151);
  static const Color inkCoral = Color(0xFF7D1A22);
  static const Color inkPeach = Color(0xFF7F4026);

  // Surfaces & Backgrounds
  static const Color warmWhite = Color(0xFFFFFAF9);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softLavender = Color(0xFFF5F1FF);
  static const Color softMint = Color(0xFFF0FAF7);
  static const Color softCoral = Color(0xFFFFF1F1);
  static const Color softPeach = Color(0xFFFFF4F0);
  static const Color surfaceTint = Color(0xFFF7F4FD);

  // Text & Ink
  static const Color ink = Color(0xFF30263F);
  static const Color mutedInk = Color(0xFF6E6778);
  static const Color subtleInk = Color(0xFF756C84);

  // Structural & Dividers
  static const Color divider = Color(0xFFEEE6EB);
  static const Color track = Color(0xFFEEEAF2);
  static const Color border = Color(0xFFE8E2EE);

  // Semantic mappings
  static const Color present = brandMint;
  static const Color absent = brandCoral;
  static const Color onPresent = inkMint;
  static const Color onAbsent = inkCoral;
  static const Color onProvisional = inkPeach;
  static const Color primaryAction = inkViolet;
  static const Color warning = inkCoral;
  static const Color neutral = mutedInk;

  // Dock & Overlays
  static const Color dockBackground = Color(0xF7FFFFFF);
  static const Color overlayScrim = Color(0x4030263F);
}
