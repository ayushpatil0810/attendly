import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.color = AppColors.brandMint,
    this.trackColor = AppColors.track,
  });

  /// Progress clamped between 0.0 and 1.0
  final double progress;
  final double height;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: AppRadius.pillBorder,
      child: Container(
        height: height,
        color: trackColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: AppMotion.duration(
                  context,
                  const Duration(milliseconds: 300),
                ),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * clamped,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.progress,
    this.size = 80.0,
    this.strokeWidth = 8.0,
    this.color = AppColors.brandMint,
    this.trackColor = AppColors.track,
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: clamped,
            strokeWidth: strokeWidth,
            strokeCap: StrokeCap.round,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          ?child,
        ],
      ),
    );
  }
}
