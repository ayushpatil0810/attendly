import 'package:flutter/material.dart';

/// Centralized color tokens according to DESIGN.md
abstract final class AppColors {
  // Brand Palette
  static const Color brandViolet = Color(0xFF9278F2);
  static const Color brandMint = Color(0xFF8BE4D0);
  static const Color brandCoral = Color(0xFFFF929B);
  static const Color brandPeach = Color(0xFFFFB49F);
  static const Color lavender = Color(0xFFB9A0F2);

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
  static const Color mutedInk = Color(0xFF827B8D);
  static const Color subtleInk = Color(0xFFA59FAF);

  // Structural & Dividers
  static const Color divider = Color(0xFFEEE6EB);
  static const Color track = Color(0xFFEEEAF2);
  static const Color border = Color(0xFFE8E2EE);

  // Semantic mappings
  static const Color present = brandMint;
  static const Color absent = brandCoral;
  static const Color primaryAction = brandViolet;
  static const Color warning = brandCoral;
  static const Color neutral = mutedInk;

  // Dock & Overlays
  static const Color dockBackground = Color(0xF7FFFFFF);
  static const Color overlayScrim = Color(0x4030263F);
}
