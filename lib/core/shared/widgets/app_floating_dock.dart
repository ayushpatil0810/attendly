import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
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
    final colors = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: colors.dockBackground,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.dockBackground,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        padding: EdgeInsets.fromLTRB(
          8,
          6,
          8,
          bottomInset > 0 ? bottomInset : 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _DockItem(
              icon: AppIcons.home,
              selectedIcon: AppIcons.homeFill,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => onDestinationSelected(0),
            ),
            _DockItem(
              icon: AppIcons.subjects,
              selectedIcon: AppIcons.subjectsFill,
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
              selectedIcon: AppIcons.historyFill,
              label: 'History',
              isSelected: currentIndex == 2,
              onTap: () => onDestinationSelected(2),
            ),
            _DockItem(
              icon: AppIcons.insights,
              selectedIcon: AppIcons.insightsFill,
              label: 'Insights',
              isSelected: currentIndex == 3,
              onTap: () => onDestinationSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 180);

    // Active tab animates into the brand highlight.
    final targetColor = isSelected
        ? colors.brandPrimaryInk
        : colors.textSecondary;
    final activeDuration = isSelected ? duration : Duration.zero;

    return Semantics(
      button: true,
      label: '$label tab',
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 58, minHeight: 48),
          child: TweenAnimationBuilder<Color?>(
            key: ValueKey(isSelected),
            tween: ColorTween(begin: colors.textSecondary, end: targetColor),
            duration: activeDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, animatedColor, _) {
              final currentColor = isSelected
                  ? (animatedColor ?? targetColor)
                  : colors.textSecondary;
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: AppIcon(
                      isSelected ? selectedIcon : icon,
                      color: currentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: currentColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
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
    final colors = context.colors;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      button: true,
      label: 'Quick log attendance',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 100),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryAction,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppIcon(AppIcons.add, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Side navigation for medium and expanded windows. Same destinations as
/// the phone dock, with Quick Log at the top of the rail.
class AppSideRail extends StatelessWidget {
  const AppSideRail({
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
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.dockBackground,
        border: Border(right: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: 96,
          child: Column(
            children: [
              const SizedBox(height: 16),
              _QuickLogButton(
                key: const Key('quick_log_dock_button'),
                onPressed: onQuickLogPressed,
              ),
              const SizedBox(height: 16),
              _DockItem(
                icon: AppIcons.home,
                selectedIcon: AppIcons.homeFill,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _DockItem(
                icon: AppIcons.subjects,
                selectedIcon: AppIcons.subjectsFill,
                label: 'Subjects',
                isSelected: currentIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              _DockItem(
                icon: AppIcons.history,
                selectedIcon: AppIcons.historyFill,
                label: 'History',
                isSelected: currentIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _DockItem(
                icon: AppIcons.insights,
                selectedIcon: AppIcons.insightsFill,
                label: 'Insights',
                isSelected: currentIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
