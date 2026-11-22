import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.duration(
          context,
          const Duration(milliseconds: 180),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value
              ? (colors.isDark ? colors.surfaceElevated : colors.surface)
              : (colors.isDark
                  ? colors.surface
                  : colors.surfaceSubtle.withValues(alpha: 0.5)),
          borderRadius: AppRadius.lgBorder,
          border: Border.all(
            color: colors.border.withValues(
              alpha: colors.isDark
                  ? (value ? 0.6 : 0.4)
                  : (value ? 0.8 : 0.5),
            ),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.itemTitle.copyWith(
                      color: enabled ? colors.textPrimary : colors.textTertiary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.labelSmall.copyWith(
                        color: enabled
                            ? colors.textSecondary
                            : colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: AppMotion.duration(
                context,
                const Duration(milliseconds: 200),
              ),
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: AppRadius.pillBorder,
                color: value ? colors.brandPrimary : colors.track,
              ),
              child: AnimatedAlign(
                duration: AppMotion.duration(
                  context,
                  const Duration(milliseconds: 200),
                ),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
