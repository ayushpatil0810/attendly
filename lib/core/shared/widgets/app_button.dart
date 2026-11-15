import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
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

  Color get _backgroundColor {
    if (!_isEnabled) {
      return AppColors.track;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _isPressed
            ? AppColors.brandViolet.withOpacity(0.85)
            : AppColors.brandViolet;
      case AppButtonVariant.secondary:
        return _isPressed
            ? AppColors.softLavender.withOpacity(0.8)
            : AppColors.softLavender;
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return Colors.transparent;
      case AppButtonVariant.destructive:
        return _isPressed
            ? AppColors.brandCoral.withOpacity(0.85)
            : AppColors.brandCoral;
    }
  }

  Color get _textColor {
    if (!_isEnabled) {
      return AppColors.subtleInk;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        return AppColors.pureWhite;
      case AppButtonVariant.secondary:
        return AppColors.brandViolet;
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return AppColors.ink;
    }
  }

  BorderSide? get _border {
    if (widget.variant == AppButtonVariant.outline) {
      return BorderSide(
        color: _isEnabled ? AppColors.border : AppColors.divider,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_textColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: AppTypography.labelLarge.copyWith(
            color: _textColor,
            fontSize: _fontSize,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: _isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: _isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: _isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          padding: _padding,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: AppRadius.mdBorder,
            border: _border != null ? Border.fromBorderSide(_border!) : null,
          ),
          child: content,
        ),
      ),
    );
  }
}
