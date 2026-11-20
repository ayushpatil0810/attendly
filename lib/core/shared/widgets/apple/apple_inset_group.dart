import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_typography.dart';

/// Renders an Apple-style Inset Grouped card container (iOS Settings / Apple Health style).
///
/// Features:
/// - Optional uppercase section [header] with 16px horizontal inset.
/// - Optional section [footer] caption with muted typography.
/// - Rounded container (`16px` radius) with elevated surface fill and subtle hairline border.
/// - Automatically inserts 0.5px hairline dividers between [children] with optional [dividerIndent].
class AppleInsetGroup extends StatelessWidget {
  const AppleInsetGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.dividerIndent = 16.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.backgroundColor,
  });

  final List<Widget> children;
  final String? header;
  final String? footer;
  final double dividerIndent;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final surfaceColor = backgroundColor ?? colors.surface;

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional Uppercase Header (Apple Caption 1)
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
              child: Text(
                header!,
                style: AppTypography.caption1.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Inset Group Card Container
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(
                color: colors.border.withValues(alpha: colors.isDark ? 0.6 : 0.8),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: colors.isDark ? 0.25 : 0.03,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: dividerIndent,
                      color: colors.divider.withValues(
                        alpha: colors.isDark ? 0.5 : 0.8,
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Optional Footer Note (Apple Footnote)
          if (footer != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 6),
              child: Text(
                footer!,
                style: AppTypography.footnote.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
