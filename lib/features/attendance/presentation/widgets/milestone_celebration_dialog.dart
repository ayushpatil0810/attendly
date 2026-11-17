import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_milestone.dart';

class MilestoneCelebrationDialog extends StatefulWidget {
  const MilestoneCelebrationDialog({
    super.key,
    required this.milestone,
    this.currentPercentage,
  });

  final AttendanceMilestone milestone;
  final double? currentPercentage;

  static Future<void> show(
    BuildContext context, {
    required AttendanceMilestone milestone,
    double? currentPercentage,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => MilestoneCelebrationDialog(
        milestone: milestone,
        currentPercentage: currentPercentage,
      ),
    );
  }

  @override
  State<MilestoneCelebrationDialog> createState() =>
      _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState extends State<MilestoneCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            backgroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
            insetPadding: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Trophy Badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.softMint,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.brandMint.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandMint.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(
                      AppIcons.trophy,
                      size: 36,
                      color: AppColors.inkMint,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Celebration Heading
                  Text(
                    'Milestone Unlocked! 🎉',
                    style: AppTypography.itemTitle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Milestone Title & Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softLavender,
                      borderRadius: AppRadius.pillBorder,
                    ),
                    child: Text(
                      '${widget.milestone.title} • ${widget.milestone.badgeName}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.inkViolet,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Message
                  Text(
                    widget.milestone.celebrationMessage,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Dismiss Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inkViolet,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.pillBorder,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Keep Going',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
