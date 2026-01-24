// lib/widgets/app_badge.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Badge variant types for semantic meaning
enum AppBadgeVariant {
  /// Default/neutral badge
  secondary,

  /// Primary accent badge
  primary,

  /// Success/positive state
  success,

  /// Warning/caution state
  warning,

  /// Error/destructive state
  error,

  /// Informational state
  info,

  /// Outlined style (no fill)
  outline,
}

/// Badge size options
enum AppBadgeSize {
  /// Small badge (18px height)
  sm,

  /// Medium badge (22px height) - default
  md,

  /// Large badge (26px height)
  lg,
}

/// A badge component for displaying status, labels, or counts.
///
/// Badges are small status descriptors for UI elements. They can
/// contain text, numbers, or be used as notification indicators.
///
/// Example usage:
/// ```dart
/// // Status badge
/// AppBadge(
///   label: 'Active',
///   variant: AppBadgeVariant.success,
/// )
///
/// // Count badge
/// AppBadge(
///   label: '5',
///   variant: AppBadgeVariant.primary,
/// )
///
/// // Badge on icon
/// AppBadge.dot(
///   variant: AppBadgeVariant.error,
/// )
/// ```
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.secondary,
    this.size = AppBadgeSize.md,
    this.icon,
    this.onTap,
  }) : _isDot = false;

  /// Creates a dot badge (no text, just indicator)
  const AppBadge.dot({
    super.key,
    this.variant = AppBadgeVariant.error,
    this.size = AppBadgeSize.sm,
    this.onTap,
  }) : label = '',
       icon = null,
       _isDot = true;

  /// Text to display in the badge
  final String label;

  /// Visual variant of the badge
  final AppBadgeVariant variant;

  /// Size of the badge
  final AppBadgeSize size;

  /// Optional leading icon
  final IconData? icon;

  /// Callback when badge is tapped
  final VoidCallback? onTap;

  /// Whether this is a dot badge
  final bool _isDot;

  double get _height {
    switch (size) {
      case AppBadgeSize.sm:
        return 18;
      case AppBadgeSize.md:
        return 22;
      case AppBadgeSize.lg:
        return 26;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppBadgeSize.sm:
        return 10;
      case AppBadgeSize.md:
        return 11;
      case AppBadgeSize.lg:
        return 12;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppBadgeSize.sm:
        return 10;
      case AppBadgeSize.md:
        return 12;
      case AppBadgeSize.lg:
        return 14;
    }
  }

  double get _dotSize {
    switch (size) {
      case AppBadgeSize.sm:
        return 8;
      case AppBadgeSize.md:
        return 10;
      case AppBadgeSize.lg:
        return 12;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case AppBadgeSize.sm:
        return const EdgeInsets.symmetric(horizontal: 6);
      case AppBadgeSize.md:
        return const EdgeInsets.symmetric(horizontal: 8);
      case AppBadgeSize.lg:
        return const EdgeInsets.symmetric(horizontal: 10);
    }
  }

  Color _getBackgroundColor(bool isDark) {
    switch (variant) {
      case AppBadgeVariant.secondary:
        return isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
      case AppBadgeVariant.primary:
        return isDark
            ? AppColors.primaryDark.withOpacity(0.15)
            : AppColors.primaryLight.withOpacity(0.15);
      case AppBadgeVariant.success:
        return isDark
            ? AppColors.success.withOpacity(0.15)
            : AppColors.successLight;
      case AppBadgeVariant.warning:
        return isDark
            ? AppColors.warning.withOpacity(0.15)
            : AppColors.warningLight;
      case AppBadgeVariant.error:
        return isDark
            ? AppColors.error.withOpacity(0.15)
            : AppColors.errorLight;
      case AppBadgeVariant.info:
        return isDark ? AppColors.info.withOpacity(0.15) : AppColors.infoLight;
      case AppBadgeVariant.outline:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor(bool isDark) {
    switch (variant) {
      case AppBadgeVariant.secondary:
        return isDark
            ? AppColors.mutedForegroundDark
            : AppColors.mutedForegroundLight;
      case AppBadgeVariant.primary:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;
      case AppBadgeVariant.success:
        return isDark ? AppColors.success : AppColors.successMuted;
      case AppBadgeVariant.warning:
        return isDark ? AppColors.warning : AppColors.warningMuted;
      case AppBadgeVariant.error:
        return isDark ? AppColors.error : AppColors.errorMuted;
      case AppBadgeVariant.info:
        return isDark ? AppColors.info : AppColors.infoMuted;
      case AppBadgeVariant.outline:
        return isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    }
  }

  Color? _getBorderColor(bool isDark) {
    if (variant == AppBadgeVariant.outline) {
      return isDark ? AppColors.borderDark : AppColors.borderLight;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _getBackgroundColor(isDark);
    final fgColor = _getForegroundColor(isDark);
    final borderColor = _getBorderColor(isDark);

    // Dot badge
    if (_isDot) {
      return Container(
        width: _dotSize,
        height: _dotSize,
        decoration: BoxDecoration(color: fgColor, shape: BoxShape.circle),
      );
    }

    Widget badge = Container(
      height: _height,
      padding: _padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _iconSize, color: fgColor),
            SizedBox(width: size == AppBadgeSize.sm ? 2 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilySans,
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
              color: fgColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(
        onTap: onTap,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: badge),
      );
    }

    return badge;
  }
}

/// Chip variant types
enum AppChipVariant {
  /// Filled background (default)
  filled,

  /// Outlined style
  outlined,

  /// Tonal/subtle style
  tonal,
}

/// Chip size options
enum AppChipSize {
  /// Small chip (28px height)
  sm,

  /// Medium chip (32px height) - default
  md,

  /// Large chip (40px height)
  lg,
}

/// A chip component for selection, filtering, or actions.
///
/// Chips are compact elements that represent an input, attribute,
/// or action. They can be selectable, deletable, or actionable.
///
/// Example usage:
/// ```dart
/// // Filter chip
/// AppChip(
///   label: 'Strength',
///   selected: isSelected,
///   onSelected: (selected) => setState(() => isSelected = selected),
/// )
///
/// // Deletable chip
/// AppChip(
///   label: 'Tag Name',
///   onDeleted: () => removeTag(),
/// )
///
/// // Action chip
/// AppChip(
///   label: 'Add Filter',
///   avatar: Icon(Icons.add),
///   onTap: () => addFilter(),
/// )
/// ```
class AppChip extends StatefulWidget {
  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.filled,
    this.size = AppChipSize.md,
    this.selected = false,
    this.disabled = false,
    this.avatar,
    this.leadingIcon,
    this.deleteIcon,
    this.onSelected,
    this.onDeleted,
    this.onTap,
    this.selectedColor,
    this.backgroundColor,
  });

  /// Text to display in the chip
  final String label;

  /// Visual variant of the chip
  final AppChipVariant variant;

  /// Size of the chip
  final AppChipSize size;

  /// Whether the chip is selected
  final bool selected;

  /// Whether the chip is disabled
  final bool disabled;

  /// Optional avatar widget (left side)
  final Widget? avatar;

  /// Optional leading icon
  final IconData? leadingIcon;

  /// Custom delete icon (defaults to close)
  final IconData? deleteIcon;

  /// Callback when selection changes
  final ValueChanged<bool>? onSelected;

  /// Callback when delete is pressed
  final VoidCallback? onDeleted;

  /// Callback when chip is tapped (for action chips)
  final VoidCallback? onTap;

  /// Custom color when selected
  final Color? selectedColor;

  /// Custom background color
  final Color? backgroundColor;

  @override
  State<AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<AppChip> {
  bool _isPressed = false;

  double get _height {
    switch (widget.size) {
      case AppChipSize.sm:
        return 28;
      case AppChipSize.md:
        return 32;
      case AppChipSize.lg:
        return 40;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppChipSize.sm:
        return 12;
      case AppChipSize.md:
        return 13;
      case AppChipSize.lg:
        return 14;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppChipSize.sm:
        return 14;
      case AppChipSize.md:
        return 16;
      case AppChipSize.lg:
        return 18;
    }
  }

  double get _avatarSize {
    switch (widget.size) {
      case AppChipSize.sm:
        return 20;
      case AppChipSize.md:
        return 24;
      case AppChipSize.lg:
        return 28;
    }
  }

  EdgeInsets get _padding {
    final hasLeading = widget.avatar != null || widget.leadingIcon != null;
    final hasTrailing = widget.onDeleted != null;

    switch (widget.size) {
      case AppChipSize.sm:
        return EdgeInsets.only(
          left: hasLeading ? 4 : 10,
          right: hasTrailing ? 4 : 10,
        );
      case AppChipSize.md:
        return EdgeInsets.only(
          left: hasLeading ? 4 : 12,
          right: hasTrailing ? 4 : 12,
        );
      case AppChipSize.lg:
        return EdgeInsets.only(
          left: hasLeading ? 6 : 16,
          right: hasTrailing ? 6 : 16,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInteractive =
        !widget.disabled &&
        (widget.onSelected != null ||
            widget.onDeleted != null ||
            widget.onTap != null);

    // Colors based on variant and state
    Color bgColor;
    Color fgColor;
    Color? borderColor;

    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    if (widget.selected) {
      bgColor = widget.selectedColor ?? primaryColor;
      fgColor = AppColors.white;
      borderColor = null;
    } else {
      switch (widget.variant) {
        case AppChipVariant.filled:
          bgColor =
              widget.backgroundColor ??
              (isDark ? AppColors.secondaryDark : AppColors.secondaryLight);
          fgColor = isDark
              ? AppColors.foregroundDark
              : AppColors.foregroundLight;
          borderColor = null;
          break;
        case AppChipVariant.outlined:
          bgColor = Colors.transparent;
          fgColor = isDark
              ? AppColors.foregroundDark
              : AppColors.foregroundLight;
          borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
          break;
        case AppChipVariant.tonal:
          bgColor =
              widget.backgroundColor ??
              primaryColor.withOpacity(isDark ? 0.15 : 0.1);
          fgColor = primaryColor;
          borderColor = null;
          break;
      }
    }

    // Apply pressed state
    if (_isPressed && isInteractive) {
      bgColor = bgColor.withOpacity(bgColor.opacity * 0.8);
    }

    // Apply disabled state
    if (widget.disabled) {
      bgColor = bgColor.withOpacity(0.5);
      fgColor = fgColor.withOpacity(0.5);
    }

    Widget chip = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: _height,
      padding: _padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: borderColor != null
            ? Border.all(
                color: widget.selected ? primaryColor : borderColor,
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          if (widget.avatar != null) ...[
            SizedBox(
              width: _avatarSize,
              height: _avatarSize,
              child: widget.avatar,
            ),
            SizedBox(width: widget.size == AppChipSize.sm ? 4 : 6),
          ],

          // Leading icon
          if (widget.leadingIcon != null && widget.avatar == null) ...[
            Icon(widget.leadingIcon, size: _iconSize, color: fgColor),
            SizedBox(width: widget.size == AppChipSize.sm ? 4 : 6),
          ],

          // Label
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilySans,
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
              color: fgColor,
            ),
          ),

          // Delete button
          if (widget.onDeleted != null) ...[
            SizedBox(width: widget.size == AppChipSize.sm ? 2 : 4),
            GestureDetector(
              onTap: widget.disabled ? null : widget.onDeleted,
              child: Icon(
                widget.deleteIcon ?? Icons.close,
                size: _iconSize,
                color: fgColor.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );

    if (isInteractive) {
      chip = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.disabled
            ? null
            : () {
                if (widget.onSelected != null) {
                  widget.onSelected!(!widget.selected);
                } else if (widget.onTap != null) {
                  widget.onTap!();
                }
              },
        child: MouseRegion(
          cursor: widget.disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: chip,
        ),
      );
    }

    return chip;
  }
}

/// A horizontal list of filter chips with optional wrap behavior.
///
/// Example usage:
/// ```dart
/// AppChipGroup(
///   chips: [
///     AppChip(label: 'All', selected: true),
///     AppChip(label: 'Strength'),
///     AppChip(label: 'Cardio'),
///   ],
///   spacing: 8,
/// )
/// ```
class AppChipGroup extends StatelessWidget {
  const AppChipGroup({
    super.key,
    required this.chips,
    this.spacing = 8,
    this.runSpacing = 8,
    this.wrap = true,
  });

  /// List of chips to display
  final List<Widget> chips;

  /// Horizontal spacing between chips
  final double spacing;

  /// Vertical spacing between rows (when wrapped)
  final double runSpacing;

  /// Whether chips should wrap to new lines
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(spacing: spacing, runSpacing: runSpacing, children: chips);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            chips[i],
            if (i < chips.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}
