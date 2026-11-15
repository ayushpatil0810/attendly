import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

class AppFloatingDock extends StatelessWidget {
  const AppFloatingDock({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onQuickLogPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onQuickLogPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomInset > 0 ? bottomInset + 8 : 16,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.xxlBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.dockBackground,
              borderRadius: AppRadius.xxlBorder,
              border: Border.all(
                color: AppColors.border.withOpacity(0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DockItem(
                  icon: AppIcons.home,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
                _DockItem(
                  icon: AppIcons.subjects,
                  label: 'Subjects',
                  isSelected: currentIndex == 1,
                  onTap: () => onDestinationSelected(1),
                ),
                _QuickLogButton(
                  key: const Key('quick_log_dock_button'),
                  onPressed: onQuickLogPressed,
                ),
                _DockItem(
                  icon: AppIcons.history,
                  label: 'History',
                  isSelected: currentIndex == 2,
                  onTap: () => onDestinationSelected(2),
                ),
                _DockItem(
                  icon: AppIcons.insights,
                  label: 'Insights',
                  isSelected: currentIndex == 3,
                  onTap: () => onDestinationSelected(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final dynamic icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.brandViolet : AppColors.mutedInk;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.softLavender : Colors.transparent,
                borderRadius: AppRadius.pillBorder,
              ),
              child: AppIcon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLogButton extends StatefulWidget {
  const _QuickLogButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_QuickLogButton> createState() => _QuickLogButtonState();
}

class _QuickLogButtonState extends State<_QuickLogButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.brandViolet,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brandViolet.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const AppIcon(
            AppIcons.add,
            color: AppColors.pureWhite,
            size: 24,
          ),
        ),
      ),
    );
  }
}
