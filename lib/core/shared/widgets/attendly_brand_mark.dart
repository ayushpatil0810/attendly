import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';

/// Crisp, theme-adaptive vector rendering of the Attendly Calendar Symbol mark.
///
/// Refined modern calendar tile with golden-ratio proportions, sleek binding rings,
/// an origami corner accent, and a mathematically centered attendance checkmark.
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

  /// Folded bottom-right corner accent (defaults to [context.colors.accentCoral]).
  final Color? coralColor;

  /// Attendance checkmark stroke color (defaults to [context.colors.accentMint]).
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
    final effectiveCoral = coralColor ?? colors.accentCoral;
    final effectiveMint = mintColor ?? colors.accentMint;

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

  @override
  void paint(Canvas canvas, Size size) {
    // 512x512 reference viewBox scale
    final s = size.width / 512.0;

    final primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final surfacePaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final coralPaint = Paint()
      ..color = coralColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final mintPaint = Paint()
      ..color = mintColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32.0 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // 1. Calendar Body Tile (outer rounded squircle from SVG)
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(88.0 * s, 112.0 * s, 336.0 * s, 328.0 * s),
      Radius.circular(72.0 * s),
    );
    canvas.drawRRect(body, primaryPaint);

    // 2. Twin binder tabs anchored at the top
    final leftTab = RRect.fromRectAndRadius(
      Rect.fromLTWH(158.0 * s, 64.0 * s, 48.0 * s, 112.0 * s),
      Radius.circular(24.0 * s),
    );
    final rightTab = RRect.fromRectAndRadius(
      Rect.fromLTWH(306.0 * s, 64.0 * s, 48.0 * s, 112.0 * s),
      Radius.circular(24.0 * s),
    );
    canvas.drawRRect(leftTab, primaryPaint);
    canvas.drawRRect(rightTab, primaryPaint);

    // 3. Inner Calendar Page (clean surface face)
    final page = RRect.fromRectAndRadius(
      Rect.fromLTWH(120.0 * s, 216.0 * s, 272.0 * s, 192.0 * s),
      Radius.circular(42.0 * s),
    );
    canvas.drawRRect(page, surfacePaint);

    // 4. Clean Origami Page Fold Accent (bottom-right bezier fold)
    final foldPath = Path()
      ..moveTo(352.0 * s, 352.0 * s)
      ..cubicTo(
        352.0 * s,
        330.0 * s,
        370.0 * s,
        312.0 * s,
        392.0 * s,
        312.0 * s,
      )
      ..lineTo(424.0 * s, 312.0 * s)
      ..lineTo(424.0 * s, 368.0 * s)
      ..cubicTo(
        424.0 * s,
        408.0 * s,
        392.0 * s,
        440.0 * s,
        352.0 * s,
        440.0 * s,
      )
      ..lineTo(286.0 * s, 440.0 * s)
      ..cubicTo(
        324.0 * s,
        420.0 * s,
        352.0 * s,
        390.0 * s,
        352.0 * s,
        352.0 * s,
      )
      ..close();
    canvas.drawPath(foldPath, coralPaint);

    // 5. Attendance Checkmark
    if (checkmarkProgress > 0.0) {
      final checkPath = Path()
        ..moveTo(184.0 * s, 304.0 * s)
        ..lineTo(238.0 * s, 358.0 * s)
        ..lineTo(336.0 * s, 260.0 * s);

      if (checkmarkProgress >= 0.999) {
        canvas.drawPath(checkPath, mintPaint);
      } else {
        final metrics = checkPath.computeMetrics().toList();
        if (metrics.isNotEmpty) {
          final metric = metrics.first;
          final extracted = metric.extractPath(0.0, metric.length * checkmarkProgress);
          canvas.drawPath(extracted, mintPaint);
        }
      }
    }

    // 6. Transparent binding openings / cutouts
    final cutoutPaint = Paint()
      ..color = cutoutColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final leftOpening = RRect.fromRectAndRadius(
      Rect.fromLTWH(170.0 * s, 78.0 * s, 24.0 * s, 78.0 * s),
      Radius.circular(12.0 * s),
    );
    final rightOpening = RRect.fromRectAndRadius(
      Rect.fromLTWH(318.0 * s, 78.0 * s, 24.0 * s, 78.0 * s),
      Radius.circular(12.0 * s),
    );
    canvas.drawRRect(leftOpening, cutoutPaint);
    canvas.drawRRect(rightOpening, cutoutPaint);
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
