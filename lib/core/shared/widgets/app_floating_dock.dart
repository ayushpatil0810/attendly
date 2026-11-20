import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';

/// Floating pill-shaped navigation dock inspired by modern mobile aesthetics.
///
/// Floats above the screen bottom with a rich brand-colored capsule, soft ambient
/// shadow, and fluid expanding-pill active tab state.
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

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: bottomInset == 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          bottomInset > 0 ? bottomInset + 4 : 16,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: (colors.isDark
                        ? const Color(0xFF1E1E22)
                        : const Color(0xFF18181B))
                    .withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: colors.isDark
                      ? const Color(0xFF3F3F46).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.12),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: colors.isDark ? 0.45 : 0.18,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DockItem(
                    key: const Key('dock_tab_home'),
                    icon: AppIcons.home,
                    selectedIcon: AppIcons.homeFill,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                  _DockItem(
                    key: const Key('dock_tab_subjects'),
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
                    key: const Key('dock_tab_history'),
                    icon: AppIcons.history,
                    selectedIcon: AppIcons.historyFill,
                    label: 'History',
                    isSelected: currentIndex == 2,
                    onTap: () => onDestinationSelected(2),
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

class _DockItem extends StatelessWidget {
  const _DockItem({
    super.key,
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
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return Semantics(
      button: true,
      label: '$label tab',
      selected: isSelected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 14 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppIcon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.70),
                size: 21,
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  child: isSelected
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
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
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      button: true,
      label: 'Quick log attendance',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : 1.0,
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: AppIcon(
              AppIcons.add,
              color: const Color(0xFF18181B),
              size: 22,
            ),
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
              _RailItem(
                key: const Key('dock_tab_home'),
                icon: AppIcons.home,
                selectedIcon: AppIcons.homeFill,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              const SizedBox(height: 8),
              _RailItem(
                key: const Key('dock_tab_subjects'),
                icon: AppIcons.subjects,
                selectedIcon: AppIcons.subjectsFill,
                label: 'Subjects',
                isSelected: currentIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              const SizedBox(height: 8),
              _RailItem(
                key: const Key('dock_tab_history'),
                icon: AppIcons.history,
                selectedIcon: AppIcons.historyFill,
                label: 'History',
                isSelected: currentIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    super.key,
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
    return Semantics(
      button: true,
      label: '$label tab',
      selected: isSelected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.brandPrimarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                isSelected ? selectedIcon : icon,
                color:
                    isSelected ? colors.brandPrimaryInk : colors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? colors.brandPrimaryInk
                      : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
