import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';

/// Crisp, theme-adaptive vector rendering of the Attendly Brand Symbol.
///
/// Refined modern calendar tile with golden-ratio proportions, sleek binding rings,
/// subtle depth shadows, attendance progress arcs, and a signature attendance checkmark
/// matching the official attendly.svg mark.
class AttendlyBrandMark extends StatelessWidget {
  const AttendlyBrandMark({
    super.key,
    this.size = 56.0,
    this.primaryColor,
    this.surfaceColor,
    this.cutoutColor,
    this.coralColor,
    this.mintColor,
    this.checkmarkProgress = 1.0,
    this.semanticLabel = 'Attendly calendar mark',
  });

  /// Bounding size (width and height) in logical pixels.
  final double size;

  /// Main calendar body color (defaults to [context.colors.brandPrimary]).
  final Color? primaryColor;

  /// Calendar sheet page and binder ring color (defaults to [context.colors.surface]).
  final Color? surfaceColor;

  /// Ring interior cutout color (defaults to [context.colors.background]).
  final Color? cutoutColor;

  /// Outer accent arc color (defaults to [primaryColor] or [context.colors.brandPrimary]).
  final Color? coralColor;

  /// Attendance checkmark & inner progress arc color (defaults to [context.colors.accentGreen]).
  final Color? mintColor;

  /// Progress of the attendance checkmark draw animation (0.0 to 1.0).
  final double checkmarkProgress;

  /// Accessibility semantic description.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectivePrimary = primaryColor ?? colors.brandPrimary;
    final effectiveSurface = surfaceColor ?? colors.surface;
    final effectiveCutout = cutoutColor ?? colors.background;
    final effectiveCoral = coralColor ?? effectivePrimary;
    final effectiveMint = mintColor ?? colors.accentGreen;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _AttendlyBrandMarkPainter(
            primaryColor: effectivePrimary,
            surfaceColor: effectiveSurface,
            cutoutColor: effectiveCutout,
            coralColor: effectiveCoral,
            mintColor: effectiveMint,
            checkmarkProgress: checkmarkProgress.clamp(0.0, 1.0),
          ),
        ),
      ),
    );
  }
}

class _AttendlyBrandMarkPainter extends CustomPainter {
  const _AttendlyBrandMarkPainter({
    required this.primaryColor,
    required this.surfaceColor,
    required this.cutoutColor,
    required this.coralColor,
    required this.mintColor,
    required this.checkmarkProgress,
  });

  final Color primaryColor;
  final Color surfaceColor;
  final Color cutoutColor;
  final Color coralColor;
  final Color mintColor;
  final double checkmarkProgress;

  Color _computeShadowColor(Color primary) {
    // Elegant Apple-style 20% luminance depth shadow for binder tabs
    final hsl = HSLColor.fromColor(primary);
    final darker = hsl.withLightness((hsl.lightness * 0.78).clamp(0.0, 1.0));
    return darker.toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // attendly.svg canonical viewBox: 0 0 868 930
    final scale = math.min(size.width / 868.0, size.height / 930.0);
    final dx = (size.width - 868.0 * scale) / 2.0;
    final dy = (size.height - 930.0 * scale) / 2.0;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    final primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final shadowPaint = Paint()
      ..color = _computeShadowColor(primaryColor)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final checkmarkPaint = Paint()
      ..color = mintColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final outerArcPaint = Paint()
      ..color = coralColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final innerArcPaint = Paint()
      ..color = mintColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Calendar Body Path
    final bodyPath = Path()
      ..moveTo(145, 106)
      ..lineTo(720, 106)
      ..arcToPoint(
        const Offset(764, 117),
        radius: const Radius.circular(145),
        largeArc: false,
        clockwise: true,
      )
      ..lineTo(560, 329)
      ..lineTo(92, 329)
      ..lineTo(92, 773)
      ..arcToPoint(
        const Offset(154, 835),
        radius: const Radius.circular(62),
        largeArc: false,
        clockwise: false,
      )
      ..lineTo(409, 835)
      ..arcToPoint(
        const Offset(418.5, 929),
        radius: const Radius.circular(76),
        largeArc: false,
        clockwise: false,
      )
      ..lineTo(145, 929)
      ..arcToPoint(
        const Offset(0, 784),
        radius: const Radius.circular(145),
        largeArc: false,
        clockwise: true,
      )
      ..lineTo(0, 251)
      ..arcToPoint(
        const Offset(145, 106),
        radius: const Radius.circular(145),
        largeArc: false,
        clockwise: true,
      )
      ..close();
    canvas.drawPath(bodyPath, primaryPaint);

    // 2. Top Calendar Binding Tabs
    final leftTab = RRect.fromRectAndRadius(
      const Rect.fromLTWH(187, 0, 93, 192),
      const Radius.circular(46.5),
    );
    final rightTab = RRect.fromRectAndRadius(
      const Rect.fromLTWH(576, 0, 94, 193),
      const Radius.circular(47.0),
    );
    canvas.drawRRect(leftTab, primaryPaint);
    canvas.drawRRect(rightTab, primaryPaint);

    // 3. Subtle Overlap Shadows Inside Header
    final shadow1 = Path()
      ..moveTo(187, 106)
      ..lineTo(280, 106)
      ..lineTo(280, 145.5)
      ..arcToPoint(
        const Offset(187, 145.5),
        radius: const Radius.circular(46.5),
        largeArc: false,
        clockwise: true,
      )
      ..close();
    final shadow2 = Path()
      ..moveTo(576, 106)
      ..lineTo(670, 106)
      ..lineTo(670, 146)
      ..arcToPoint(
        const Offset(576, 146),
        radius: const Radius.circular(47.0),
        largeArc: false,
        clockwise: true,
      )
      ..close();
    canvas.drawPath(shadow1, shadowPaint);
    canvas.drawPath(shadow2, shadowPaint);

    // 4. Attendance Checkmark (with smooth animation clip support)
    if (checkmarkProgress > 0.0) {
      final checkPath = Path()
        ..moveTo(801, 137)
        ..lineTo(373, 584)
        ..lineTo(284, 497)
        ..arcToPoint(
          const Offset(196, 580),
          radius: const Radius.circular(60),
          largeArc: false,
          clockwise: false,
        )
        ..lineTo(336, 725)
        ..arcToPoint(
          const Offset(405, 727),
          radius: const Radius.circular(48),
          largeArc: false,
          clockwise: false,
        )
        ..lineTo(829, 287)
        ..cubicTo(858, 257, 858, 196, 825, 162)
        ..cubicTo(817, 153, 809, 145, 801, 137)
        ..close();

      if (checkmarkProgress >= 0.999) {
        canvas.drawPath(checkPath, checkmarkPaint);
      } else {
        canvas.save();
        // Animate from left pivot point across to right
        final clipWidth = 196.0 + (868.0 - 196.0) * checkmarkProgress;
        canvas.clipRect(Rect.fromLTWH(0, 0, clipWidth, 930));
        canvas.drawPath(checkPath, checkmarkPaint);
        canvas.restore();
      }
    }

    // 5. Outer Progress Arc
    final outerArcPath = Path()
      ..moveTo(779.3, 392.5)
      ..arcToPoint(
        const Offset(466.5, 916.2),
        radius: const Radius.circular(316),
        largeArc: false,
        clockwise: true,
      )
      ..arcToPoint(
        const Offset(488.1, 839.2),
        radius: const Radius.circular(40),
        largeArc: false,
        clockwise: true,
      )
      ..arcToPoint(
        const Offset(721.8, 448.1),
        radius: const Radius.circular(236),
        largeArc: false,
        clockwise: false,
      )
      ..close();
    canvas.drawPath(outerArcPath, outerArcPaint);

    // 6. Inner Progress Arc
    final innerArcPath = Path()
      ..moveTo(698.4, 480.2)
      ..arcToPoint(
        const Offset(552, 809),
        radius: const Radius.circular(197),
        largeArc: false,
        clockwise: true,
      )
      ..arcToPoint(
        const Offset(552, 748),
        radius: const Radius.circular(30.5),
        largeArc: false,
        clockwise: true,
      )
      ..arcToPoint(
        const Offset(653.1, 521),
        radius: const Radius.circular(136),
        largeArc: false,
        clockwise: false,
      )
      ..close();
    canvas.drawPath(innerArcPath, innerArcPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AttendlyBrandMarkPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.cutoutColor != cutoutColor ||
        oldDelegate.coralColor != coralColor ||
        oldDelegate.mintColor != mintColor ||
        oldDelegate.checkmarkProgress != checkmarkProgress;
  }
}
