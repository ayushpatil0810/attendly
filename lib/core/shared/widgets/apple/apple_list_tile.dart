import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_typography.dart';

/// Apple-styled list tile row adhering to HIG Inset Grouped specifications.
class AppleListTile extends StatelessWidget {
  const AppleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDisclosure = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDisclosure;
  final EdgeInsetsGeometry padding;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final tileContent = Padding(
      padding: padding,
      child: Row(
        children: [
          // Optional Leading Icon / Widget
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.headline.copyWith(
                    fontSize: 16,
                    color: enabled ? colors.textPrimary : colors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.footnote.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Trailing widget or disclosure chevron
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],

          if (showDisclosure) ...[
            const SizedBox(width: 6),
            AppIcon(
              AppIcons.caretRight,
              size: 16,
              color: colors.textTertiary.withValues(alpha: 0.8),
            ),
          ],
        ],
      ),
    );

    if (onTap == null || !enabled) {
      return tileContent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: colors.surfaceSubtle.withValues(alpha: 0.5),
        highlightColor: colors.surfaceSubtle.withValues(alpha: 0.3),
        child: tileContent,
      ),
    );
  }
}

/// Helper container rendering Apple's iconic squircle colored icon tile
/// (seen in iOS Settings, Shortcuts, and Health).
class AppleIconTile extends StatelessWidget {
  const AppleIconTile({
    super.key,
    required this.icon,
    required this.backgroundColor,
    this.iconColor = Colors.white,
    this.size = 30.0,
    this.iconSize = 18.0,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.smBorder,
      ),
      alignment: Alignment.center,
      child: AppIcon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );
  }
}
