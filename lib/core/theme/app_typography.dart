import 'package:flutter/material.dart';

/// Centralized typographic scale faithful to Apple's Human Interface Guidelines,
/// rendered in Plus Jakarta Sans with optical negative tracking and tabular figures.
abstract final class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';

  // ─────────────────────────────────────────────────────────────────────────
  // Canonical Apple HIG Typographic Scale
  // ─────────────────────────────────────────────────────────────────────────

  /// Large Title (34pt, Bold) — Hero screen titles in collapsible navigation bars.
  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.20,
  );

  /// Title 1 (28pt, Bold) — Primary section milestones & large metric display.
  static const TextStyle title1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.35,
    height: 1.22,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Title 2 (22pt, Bold) — Secondary hero numbers, modal headers.
  static const TextStyle title2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.25,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Title 3 (20pt, SemiBold) — Section titles within content views.
  static const TextStyle title3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    height: 1.28,
  );

  /// Headline (17pt, SemiBold) — List item titles, prominent labels.
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.35,
    height: 1.32,
  );

  /// Body (17pt, Regular) — Default body copy.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.35,
    height: 1.45,
  );

  /// Callout (16pt, Regular) — Highlighting short summaries and tips.
  static const TextStyle callout = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.40,
  );

  /// Subhead (15pt, Regular / Medium) — Secondary metadata, subtitles.
  static const TextStyle subhead = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.20,
    height: 1.35,
  );

  /// Footnote (13pt, Regular) — Timestamps, secondary captions, help text.
  static const TextStyle footnote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.10,
    height: 1.30,
  );

  /// Caption 1 (12pt, Medium) — Inset grouped section headers (ALL CAPS).
  static const TextStyle caption1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.10,
    height: 1.25,
  );

  /// Caption 2 (11pt, Regular) — Micro-badges and tertiary counts.
  static const TextStyle caption2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.20,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Backward-Compatible Aliases for Existing App Callers
  // ─────────────────────────────────────────────────────────────────────────

  static const TextStyle heroNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.15,
  );

  static const TextStyle metricLarge = title1;
  static const TextStyle metricMedium = title3;
  static const TextStyle screenTitle = title1;
  static const TextStyle sectionTitle = title3;
  static const TextStyle itemTitle = headline;
  static const TextStyle bodyLarge = body;
  static const TextStyle bodyMedium = subhead;
  static const TextStyle bodyMuted = subhead;
  static const TextStyle bodySmall = footnote;
  static const TextStyle labelLarge = headline;
  static const TextStyle labelMedium = subhead;
  static const TextStyle labelSmall = caption1;

  /// Tabular text variant helper for live counts and percentages.
  static TextStyle withTabularFigures(TextStyle base) {
    return base.copyWith(
      fontFeatures: [...?base.fontFeatures, const FontFeature.tabularFigures()],
    );
  }
}
