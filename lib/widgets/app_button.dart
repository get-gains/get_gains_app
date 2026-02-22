// lib/widgets/app_button.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Button variant types
enum AppButtonVariant { primary, secondary, ghost, outline, destructive, link }

/// Button size options
enum AppButtonSize { sm, md, lg }

/// Icon position in button
enum IconPosition { leading, trailing }

/// A customizable button component following the design system.
///
/// Example usage:
/// ```dart
/// AppButton(
///   label: 'Get Started',
///   onPressed: () => print('Pressed'),
///   variant: AppButtonVariant.primary,
/// )
///
/// AppButton.ghost(
///   label: 'Cancel',
///   onPressed: () => Navigator.pop(context),
/// )
///
/// AppButton.icon(
///   icon: Icons.add,
///   onPressed: () {},
/// )
/// ```
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  });

  /// Primary button factory
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  }) : variant = AppButtonVariant.primary;

  /// Secondary button factory
  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  }) : variant = AppButtonVariant.secondary;

  /// Ghost button factory
  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  }) : variant = AppButtonVariant.ghost;

  /// Outline button factory
  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  }) : variant = AppButtonVariant.outline;

  /// Destructive button factory
  const AppButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  }) : variant = AppButtonVariant.destructive;

  /// Link button factory
  const AppButton.link({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  }) : variant = AppButtonVariant.link;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconPosition iconPosition;
  final bool isLoading;
  final bool isFullWidth;
  final bool disabled;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;

  bool get _isDisabled => widget.disabled || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _isDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: _isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: _isDisabled
            ? null
            : () => setState(() => _isPressed = false),
        onTap: _isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: AppTheme.durationFast,
          curve: AppTheme.curveDefault,
          child: AnimatedOpacity(
            opacity: _isDisabled ? 0.5 : 1.0,
            duration: AppTheme.durationFast,
            child: Container(
              height: _getHeight(),
              padding: _getPadding(),
              decoration: _getDecoration(isDark),
              child: Center(child: _buildContent(isDark)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (widget.isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(_getForegroundColor(isDark)),
        ),
      );
    }

    final textWidget = Text(widget.label, style: _getTextStyle(isDark));

    if (widget.icon == null) return textWidget;

    final iconWidget = Icon(
      widget.icon,
      size: _getIconSize(),
      color: _getForegroundColor(isDark),
    );

    const gap = SizedBox(width: AppTheme.spacing2);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.iconPosition == IconPosition.leading
            ? [iconWidget, gap, textWidget]
            : [textWidget, gap, iconWidget],
      ),
    );
  }

  double _getHeight() {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 36;
      case AppButtonSize.md:
        return 44;
      case AppButtonSize.lg:
        return 52;
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case AppButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 16);
      case AppButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 24);
      case AppButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 16;
      case AppButtonSize.md:
        return 20;
      case AppButtonSize.lg:
        return 24;
    }
  }

  TextStyle _getTextStyle(bool isDark) {
    TextStyle base;
    switch (widget.size) {
      case AppButtonSize.sm:
        base = AppTextStyles.buttonSmall;
        break;
      case AppButtonSize.md:
        base = AppTextStyles.button;
        break;
      case AppButtonSize.lg:
        base = AppTextStyles.buttonLarge;
        break;
    }
    return base.copyWith(color: _getForegroundColor(isDark));
  }

  Color _getForegroundColor(bool isDark) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return isDark
            ? AppColors.primaryForegroundDark
            : AppColors.primaryForegroundLight;
      case AppButtonVariant.secondary:
        return isDark
            ? AppColors.secondaryForegroundDark
            : AppColors.secondaryForegroundLight;
      case AppButtonVariant.ghost:
      case AppButtonVariant.link:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;
      case AppButtonVariant.outline:
        return isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
      case AppButtonVariant.destructive:
        return AppColors.white;
    }
  }

  BoxDecoration _getDecoration(bool isDark) {
    final borderRadius = BorderRadius.circular(AppTheme.radiusMd);

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          color: _getPrimaryBackground(isDark),
          borderRadius: borderRadius,
        );
      case AppButtonVariant.secondary:
        return BoxDecoration(
          color: _getSecondaryBackground(isDark),
          borderRadius: borderRadius,
        );
      case AppButtonVariant.ghost:
        return BoxDecoration(
          color: _getGhostBackground(isDark),
          borderRadius: borderRadius,
        );
      case AppButtonVariant.outline:
        return BoxDecoration(
          color: _getOutlineBackground(isDark),
          borderRadius: borderRadius,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        );
      case AppButtonVariant.destructive:
        return BoxDecoration(
          color: _getDestructiveBackground(isDark),
          borderRadius: borderRadius,
        );
      case AppButtonVariant.link:
        return const BoxDecoration(color: Colors.transparent);
    }
  }

  Color _getPrimaryBackground(bool isDark) {
    final base = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    if (_isPressed) return base.withOpacity(0.8);
    if (_isHovered) return base.withOpacity(0.9);
    return base;
  }

  Color _getSecondaryBackground(bool isDark) {
    final base = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    if (_isPressed) return base.withOpacity(0.8);
    if (_isHovered) return base.withOpacity(0.9);
    return base;
  }

  Color _getGhostBackground(bool isDark) {
    final base = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    if (_isPressed) return base.withOpacity(0.2);
    if (_isHovered) return base.withOpacity(0.1);
    return Colors.transparent;
  }

  Color _getOutlineBackground(bool isDark) {
    final base = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    if (_isPressed) return base.withOpacity(0.8);
    if (_isHovered) return base.withOpacity(0.5);
    return Colors.transparent;
  }

  Color _getDestructiveBackground(bool isDark) {
    final base = AppColors.error;
    if (_isPressed) return base.withOpacity(0.8);
    if (_isHovered) return base.withOpacity(0.9);
    return base;
  }
}

/// Icon-only button variant
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.ghost,
    this.size = AppButtonSize.md,
    this.disabled = false,
    this.tooltip,
  });

  const AppIconButton.primary({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.disabled = false,
    this.tooltip,
  }) : variant = AppButtonVariant.primary;

  const AppIconButton.ghost({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.disabled = false,
    this.tooltip,
  }) : variant = AppButtonVariant.ghost;

  const AppIconButton.outline({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.disabled = false,
    this.tooltip,
  }) : variant = AppButtonVariant.outline;

  final IconData icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool disabled;
  final String? tooltip;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  double get _size {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 32;
      case AppButtonSize.md:
        return 40;
      case AppButtonSize.lg:
        return 48;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 16;
      case AppButtonSize.md:
        return 20;
      case AppButtonSize.lg:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.disabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.disabled
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.disabled
            ? null
            : () => setState(() => _isPressed = false),
        onTap: widget.disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: AppTheme.durationFast,
          child: AnimatedOpacity(
            opacity: widget.disabled ? 0.5 : 1.0,
            duration: AppTheme.durationFast,
            child: AnimatedContainer(
              duration: AppTheme.durationFast,
              width: _size,
              height: _size,
              decoration: _getDecoration(isDark),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: _iconSize,
                  color: _getForegroundColor(isDark),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }

  Color _getForegroundColor(bool isDark) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return isDark
            ? AppColors.primaryForegroundDark
            : AppColors.primaryForegroundLight;
      case AppButtonVariant.ghost:
      case AppButtonVariant.outline:
        return isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
      default:
        return isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    }
  }

  BoxDecoration _getDecoration(bool isDark) {
    final borderRadius = BorderRadius.circular(_size / 2);

    switch (widget.variant) {
      case AppButtonVariant.primary:
        final base = isDark ? AppColors.primaryDark : AppColors.primaryLight;
        return BoxDecoration(
          color: _isPressed
              ? base.withOpacity(0.8)
              : _isHovered
              ? base.withOpacity(0.9)
              : base,
          borderRadius: borderRadius,
        );
      case AppButtonVariant.ghost:
        final base = isDark ? AppColors.mutedDark : AppColors.mutedLight;
        return BoxDecoration(
          color: _isPressed
              ? base.withOpacity(0.8)
              : _isHovered
              ? base.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: borderRadius,
        );
      case AppButtonVariant.outline:
        final base = isDark ? AppColors.mutedDark : AppColors.mutedLight;
        return BoxDecoration(
          color: _isPressed
              ? base.withOpacity(0.8)
              : _isHovered
              ? base.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        );
      default:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
        );
    }
  }
}
