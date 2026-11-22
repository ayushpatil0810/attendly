import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_theme_colors.dart';
import '../../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, text, destructive }

enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  EdgeInsets get _padding {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 18, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 13;
      case AppButtonSize.medium:
        return 14;
      case AppButtonSize.large:
        return 16;
    }
  }

  double get _minHeight {
    switch (widget.size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
    }
  }

  Color _backgroundColor(AppThemeColors colors) {
    if (!_isEnabled) {
      return colors.isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        final base = colors.isDark
            ? const Color(0xFFFAFAFA)
            : const Color(0xFF18181B);
        return _isPressed ? base.withValues(alpha: 0.85) : base;
      case AppButtonVariant.secondary:
        final base = colors.isDark
            ? const Color(0xFF27272A)
            : const Color(0xFFF4F4F5);
        return _isPressed ? base.withValues(alpha: 0.8) : base;
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return Colors.transparent;
      case AppButtonVariant.destructive:
        final base = colors.absent;
        return _isPressed ? base.withValues(alpha: 0.85) : base;
    }
  }

  Color _textColor(AppThemeColors colors) {
    if (!_isEnabled) {
      return colors.isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        // High-contrast inverted text: Black text on White button in Dark Mode, White text on Black button in Light Mode
        return colors.isDark ? const Color(0xFF09090B) : Colors.white;
      case AppButtonVariant.secondary:
        return colors.isDark ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return colors.textPrimary;
      case AppButtonVariant.destructive:
        return Colors.white;
    }
  }

  BorderSide? _border(AppThemeColors colors) {
    if (widget.variant == AppButtonVariant.outline) {
      return BorderSide(
        color: _isEnabled
            ? (colors.isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8))
            : colors.divider,
        width: 1.2,
      );
    }
    if (widget.variant == AppButtonVariant.secondary && _isEnabled) {
      return BorderSide(
        color: colors.isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
        width: 1.0,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = _backgroundColor(colors);
    final fg = _textColor(colors);
    final border = _border(colors);

    Widget content = IconTheme(
      data: IconThemeData(
        color: fg,
        size: _fontSize + 2,
      ),
      child: Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isLoading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              style: AppTypography.labelLarge.copyWith(
                color: fg,
                fontSize: _fontSize,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      button: true,
      label: widget.label,
      enabled: _isEnabled,
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: _isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: _isEnabled
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: _isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 100),
          child: Container(
            width: widget.isFullWidth ? double.infinity : null,
            constraints: BoxConstraints(minHeight: _minHeight),
            padding: _padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.mdBorder,
              border: border != null ? Border.fromBorderSide(border) : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
