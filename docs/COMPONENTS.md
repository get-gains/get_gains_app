# Flutter Components Library

> **Purpose**: This document catalogs reusable Flutter widgets for the Get Gains application. Each component includes all variants, complete specifications, and implementation code.
>
> **Reference**: See [DESIGN_STYLE.md](./DESIGN_STYLE.md) for design tokens and guidelines.

---

## Table of Contents

1. [Component 1: AppButton](#component-1-appbutton)
2. [Component 2: AppCard](#component-2-appcard)
3. [Component 3: AppTextField](#component-3-apptextfield)

---

## Component 1: AppButton

### Purpose
Primary interactive element for user actions. Supports multiple visual styles and states to convey different levels of importance and interaction patterns.

### Variants

#### 1. Primary (Default)
- **Purpose**: Main call-to-action, highest visual priority
- **Specifications**:
  - Background: `primary` color (`#E07D3B` dark / `#E8844A` light)
  - Text: `primaryForeground` (`#FFFFFF`)
  - Border radius: 12px (`radiusMd`)
  - Padding: 24px horizontal, 16px vertical
  - Font: `button` style (14px, weight 600)
- **States**:
  - Default: Full opacity background
  - Hover: 90% opacity
  - Pressed: 80% opacity, slight scale (0.98)
  - Focused: 2px ring with `ring` color
  - Disabled: 50% opacity, non-interactive

#### 2. Secondary
- **Purpose**: Supporting actions, less visual weight than primary
- **Specifications**:
  - Background: `secondary` color (`#363636` dark / `#E4E4E7` light)
  - Text: `secondaryForeground` (`#FFFFFF` dark / `#1A1A1A` light)
  - Border radius: 12px
  - Padding: 24px horizontal, 16px vertical
- **States**: Same pattern as primary

#### 3. Ghost
- **Purpose**: Tertiary actions, minimal visual weight
- **Specifications**:
  - Background: `transparent`
  - Text: `primary` color
  - Border: none
  - Hover background: `primary` at 10% opacity
- **States**:
  - Default: Transparent background
  - Hover: 10% primary background
  - Pressed: 20% primary background
  - Disabled: 50% opacity text

#### 4. Outline
- **Purpose**: Secondary actions with defined boundaries
- **Specifications**:
  - Background: `transparent`
  - Text: `foreground` color
  - Border: 1px solid `border` color
  - Hover background: `muted` at 50% opacity
- **States**:
  - Default: Transparent with border
  - Hover: Subtle fill
  - Pressed: Darker fill
  - Focused: Ring replaces border

#### 5. Destructive
- **Purpose**: Dangerous or irreversible actions (delete, remove)
- **Specifications**:
  - Background: `error` color (`#F87171`)
  - Text: `white`
  - Border radius: 12px
- **States**:
  - Default: Full error color
  - Hover: Darker error shade
  - Disabled: Muted error background

#### 6. Link
- **Purpose**: Navigation or inline actions, appears as text link
- **Specifications**:
  - Background: `transparent`
  - Text: `primary` color with underline on hover
  - Padding: minimal (8px horizontal)
- **States**:
  - Default: Primary colored text
  - Hover: Underline appears
  - Pressed: Darker text

#### 7. Icon Only
- **Purpose**: Compact actions with icon, no text
- **Specifications**:
  - Shape: Circle or rounded square
  - Size: 40x40px (default), 32x32px (small), 48x48px (large)
  - Icon size: 20px (default)
- **Variants**: Can combine with primary, ghost, outline styles

#### 8. Loading
- **Purpose**: Indicates async operation in progress
- **Specifications**:
  - Maintains button dimensions
  - Shows circular progress indicator
  - Disabled interaction
  - Optional: keeps text with spinner

### Size Variants

| Size | Height | Horizontal Padding | Font Size | Icon Size |
|------|--------|-------------------|-----------|-----------|
| `sm` | 36px | 16px | 12px | 16px |
| `md` | 44px | 24px | 14px | 20px |
| `lg` | 52px | 32px | 16px | 24px |

### Implementation

```dart
// lib/widgets/app_button.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Button variant types
enum AppButtonVariant {
  primary,
  secondary,
  ghost,
  outline,
  destructive,
  link,
}

/// Button size options
enum AppButtonSize {
  sm,
  md,
  lg,
}

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

enum IconPosition { leading, trailing }

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
        onTapDown: _isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: _isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: _isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: _isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: AppTheme.durationFast,
          curve: AppTheme.curveDefault,
          child: AnimatedOpacity(
            opacity: _isDisabled ? 0.5 : 1.0,
            duration: AppTheme.durationFast,
            child: AnimatedContainer(
              duration: AppTheme.durationFast,
              curve: AppTheme.curveDefault,
              height: _getHeight(),
              padding: _getPadding(),
              decoration: _getDecoration(isDark),
              child: widget.isFullWidth
                  ? Center(child: _buildContent(isDark))
                  : _buildContent(isDark),
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

    final textWidget = Text(
      widget.label,
      style: _getTextStyle(isDark),
    );

    if (widget.icon == null) return textWidget;

    final iconWidget = Icon(
      widget.icon,
      size: _getIconSize(),
      color: _getForegroundColor(isDark),
    );

    final gap = SizedBox(width: AppTheme.spacing2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.iconPosition == IconPosition.leading
          ? [iconWidget, gap, textWidget]
          : [textWidget, gap, iconWidget],
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
        onTapDown: widget.disabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.disabled ? null : () => setState(() => _isPressed = false),
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
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
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
```

### Usage Examples

```dart
// Primary action
AppButton(
  label: 'Start Workout',
  icon: Icons.play_arrow,
  onPressed: () => startWorkout(),
)

// Secondary action
AppButton.secondary(
  label: 'Save Draft',
  onPressed: () => saveDraft(),
)

// Ghost button in toolbar
AppButton.ghost(
  label: 'Cancel',
  onPressed: () => Navigator.pop(context),
)

// Destructive action
AppButton.destructive(
  label: 'Delete Exercise',
  icon: Icons.delete,
  onPressed: () => showDeleteConfirmation(),
)

// Loading state
AppButton(
  label: 'Saving...',
  isLoading: true,
  onPressed: null,
)

// Full width button
AppButton(
  label: 'Continue',
  isFullWidth: true,
  onPressed: () => nextStep(),
)

// Icon button
AppIconButton(
  icon: Icons.add,
  onPressed: () => addItem(),
  tooltip: 'Add new exercise',
)
```

### Accessibility Notes
- All buttons have minimum touch target of 44x44px
- Disabled state visually indicated (50% opacity)
- Loading state prevents double-submission
- Tooltips available for icon-only buttons
- Focus states visible for keyboard navigation

---

## Component 2: AppCard

### Purpose
Container for grouping related content with visual hierarchy. Used for transaction items, stats displays, feature cards, and content sections.

### Variants

#### 1. Default (Elevated)
- **Purpose**: Standard content container with subtle elevation
- **Specifications**:
  - Background: `card` color (`#252525` dark / `#FFFFFF` light)
  - Border: 1px solid `border` color
  - Border radius: 16px (`radiusLg`)
  - Padding: 20px all sides
  - Shadow: None (dark mode) / subtle shadow (light mode)

#### 2. Outlined
- **Purpose**: Content container with border emphasis, no fill
- **Specifications**:
  - Background: `transparent`
  - Border: 1px solid `border` color
  - Border radius: 16px
  - Padding: 20px

#### 3. Flat
- **Purpose**: Minimal container, blends with background
- **Specifications**:
  - Background: `transparent` or subtle `surface` fill
  - Border: none
  - Border radius: 16px
  - Padding: 20px

#### 4. Interactive
- **Purpose**: Clickable cards (navigation, selection)
- **Specifications**:
  - Base: Default card styling
  - Hover: Subtle background shift
  - Pressed: Scale to 0.98
  - Focus: Ring outline

#### 5. Gradient
- **Purpose**: Feature cards, promotional content
- **Specifications**:
  - Background: Linear gradient (customizable)
  - Border: none
  - Border radius: 16px (or 20px for emphasis)

#### 6. List Item
- **Purpose**: Horizontal card for list displays (transactions, exercises)
- **Specifications**:
  - Layout: Row with leading, content, trailing
  - Height: Auto (min 64px)
  - Padding: 16px horizontal, 12px vertical
  - Border radius: 12px

### Size Variants

| Size | Padding | Border Radius |
|------|---------|---------------|
| `sm` | 12px | 12px |
| `md` | 20px | 16px |
| `lg` | 24px | 20px |

### Implementation

```dart
// lib/widgets/app_card.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Card variant types
enum AppCardVariant {
  elevated,
  outlined,
  flat,
  gradient,
}

/// Card size options
enum AppCardSize {
  sm,
  md,
  lg,
}

/// A customizable card component following the design system.
///
/// Example usage:
/// ```dart
/// AppCard(
///   child: Text('Card content'),
/// )
///
/// AppCard.interactive(
///   onTap: () => navigateToDetail(),
///   child: ListTile(...),
/// )
///
/// AppCard.gradient(
///   gradient: AppColors.primaryGradient,
///   child: BalanceDisplay(),
/// )
/// ```
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.size = AppCardSize.md,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 0,
  });

  /// Elevated card factory (default)
  const AppCard.elevated({
    super.key,
    required this.child,
    this.size = AppCardSize.md,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 0,
  })  : variant = AppCardVariant.elevated,
        gradient = null;

  /// Outlined card factory
  const AppCard.outlined({
    super.key,
    required this.child,
    this.size = AppCardSize.md,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.borderColor,
  })  : variant = AppCardVariant.outlined,
        gradient = null,
        backgroundColor = null,
        elevation = 0;

  /// Flat card factory
  const AppCard.flat({
    super.key,
    required this.child,
    this.size = AppCardSize.md,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  })  : variant = AppCardVariant.flat,
        gradient = null,
        borderColor = null,
        elevation = 0;

  /// Gradient card factory
  const AppCard.gradient({
    super.key,
    required this.child,
    required this.gradient,
    this.size = AppCardSize.md,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.elevation = 0,
  })  : variant = AppCardVariant.gradient,
        backgroundColor = null,
        borderColor = null;

  /// Interactive card factory
  factory AppCard.interactive({
    Key? key,
    required Widget child,
    required VoidCallback onTap,
    AppCardVariant variant = AppCardVariant.elevated,
    AppCardSize size = AppCardSize.md,
    EdgeInsetsGeometry? padding,
    BorderRadiusGeometry? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return AppCard(
      key: key,
      variant: variant,
      size: size,
      onTap: onTap,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: child,
    );
  }

  final Widget child;
  final AppCardVariant variant;
  final AppCardSize size;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  bool get _isInteractive => widget.onTap != null;

  EdgeInsetsGeometry get _padding {
    if (widget.padding != null) return widget.padding!;
    switch (widget.size) {
      case AppCardSize.sm:
        return const EdgeInsets.all(12);
      case AppCardSize.md:
        return const EdgeInsets.all(20);
      case AppCardSize.lg:
        return const EdgeInsets.all(24);
    }
  }

  BorderRadiusGeometry get _borderRadius {
    if (widget.borderRadius != null) return widget.borderRadius!;
    switch (widget.size) {
      case AppCardSize.sm:
        return BorderRadius.circular(AppTheme.radiusMd);
      case AppCardSize.md:
        return BorderRadius.circular(AppTheme.radiusLg);
      case AppCardSize.lg:
        return BorderRadius.circular(AppTheme.radiusXl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: AppTheme.durationFast,
      curve: AppTheme.curveDefault,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        curve: AppTheme.curveDefault,
        padding: _padding,
        decoration: _getDecoration(isDark),
        child: widget.child,
      ),
    );

    if (_isInteractive) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: card,
        ),
      );
    }

    return card;
  }

  BoxDecoration _getDecoration(bool isDark) {
    switch (widget.variant) {
      case AppCardVariant.elevated:
        return BoxDecoration(
          color: _getBackgroundColor(isDark),
          borderRadius: _borderRadius,
          border: Border.all(
            color: widget.borderColor ??
                (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          boxShadow: widget.elevation > 0 && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: widget.elevation * 2,
                    offset: Offset(0, widget.elevation),
                  ),
                ]
              : null,
        );

      case AppCardVariant.outlined:
        return BoxDecoration(
          color: _isHovered && _isInteractive
              ? (isDark ? AppColors.surface1Dark : AppColors.surface1Light)
                  .withOpacity(0.5)
              : Colors.transparent,
          borderRadius: _borderRadius,
          border: Border.all(
            color: widget.borderColor ??
                (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        );

      case AppCardVariant.flat:
        return BoxDecoration(
          color: _getBackgroundColor(isDark).withOpacity(
            _isHovered && _isInteractive ? 0.8 : 0.5,
          ),
          borderRadius: _borderRadius,
        );

      case AppCardVariant.gradient:
        return BoxDecoration(
          gradient: widget.gradient,
          borderRadius: _borderRadius,
          boxShadow: widget.elevation > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: widget.elevation * 2,
                    offset: Offset(0, widget.elevation),
                  ),
                ]
              : null,
        );
    }
  }

  Color _getBackgroundColor(bool isDark) {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    final baseColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    if (_isInteractive && _isHovered) {
      return isDark ? AppColors.surface2Dark : AppColors.surface2Light;
    }

    return baseColor;
  }
}

/// List item card optimized for horizontal layouts
class AppListItemCard extends StatelessWidget {
  const AppListItemCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.backgroundColor,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.elevated,
      size: AppCardSize.sm,
      onTap: onTap,
      padding: padding ?? AppTheme.listItemPadding,
      backgroundColor: backgroundColor,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppTheme.spacing3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spacing1),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTheme.spacing3),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Stats card for displaying metrics
class AppStatsCard extends StatelessWidget {
  const AppStatsCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.trendPositive = true,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? trend;
  final bool trendPositive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                const SizedBox(width: AppTheme.spacing2),
              ],
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: AppTheme.spacing2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (trendPositive ? AppColors.success : AppColors.error)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                trend!,
                style: textTheme.labelSmall?.copyWith(
                  color: trendPositive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### Usage Examples

```dart
// Basic card
AppCard(
  child: Column(
    children: [
      Text('Workout Summary'),
      Text('3 exercises completed'),
    ],
  ),
)

// Interactive card
AppCard.interactive(
  onTap: () => navigateToWorkout(workout),
  child: WorkoutPreview(workout: workout),
)

// Gradient feature card
AppCard.gradient(
  gradient: AppColors.primaryGradient,
  child: BalanceDisplay(balance: user.balance),
)

// List item card
AppListItemCard(
  leading: CircleAvatar(
    backgroundImage: NetworkImage(exercise.imageUrl),
  ),
  title: Text(exercise.name),
  subtitle: Text('${exercise.sets} sets × ${exercise.reps} reps'),
  trailing: Icon(Icons.chevron_right),
  onTap: () => editExercise(exercise),
)

// Stats card
AppStatsCard(
  label: 'Total Workouts',
  value: '127',
  icon: Icons.fitness_center,
  trend: '+12%',
  trendPositive: true,
)
```

### Accessibility Notes
- Interactive cards announce as buttons to screen readers
- Minimum touch target of 44x44px for tappable cards
- Focus states visible for keyboard navigation
- Sufficient color contrast for text on all card backgrounds

---

## Component 3: AppTextField

### Purpose
Text input component for forms and data entry. Supports various input types, validation states, and enhanced features like icons and character counts.

### Variants

#### 1. Default (Outlined)
- **Purpose**: Standard text input with border
- **Specifications**:
  - Background: `input` color (`#363636` dark / `#E4E4E7` light)
  - Border: 1px solid `border` color
  - Border radius: 12px (`radiusMd`)
  - Padding: 16px horizontal, 14px vertical
  - Font: `bodyLarge` (16px)

#### 2. Filled
- **Purpose**: Text input with filled background, no visible border
- **Specifications**:
  - Background: `surface2` color
  - Border: none (border on focus only)
  - Border radius: 12px
  - Padding: 16px horizontal, 14px vertical

#### 3. Underlined
- **Purpose**: Minimal input with bottom border only
- **Specifications**:
  - Background: transparent
  - Border: bottom only, 1px
  - Padding: 16px horizontal, 12px vertical

### State Variants

| State | Border Color | Background | Label/Hint Color |
|-------|--------------|------------|------------------|
| Default | `border` | `input` | `mutedForeground` |
| Focused | `ring` (2px) | `input` | `primary` |
| Error | `error` | `input` with error tint | `error` |
| Disabled | `border` (50% opacity) | `muted` | `mutedForeground` (50%) |
| Success | `success` | `input` | `success` |

### Size Variants

| Size | Height | Font Size | Padding |
|------|--------|-----------|---------|
| `sm` | 40px | 14px | 12px h, 10px v |
| `md` | 48px | 16px | 16px h, 14px v |
| `lg` | 56px | 18px | 20px h, 16px v |

### Implementation

```dart
// lib/widgets/app_text_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Text field variant types
enum AppTextFieldVariant {
  outlined,
  filled,
  underlined,
}

/// Text field size options
enum AppTextFieldSize {
  sm,
  md,
  lg,
}

/// Text field state for custom validation display
enum AppTextFieldState {
  normal,
  error,
  success,
}

/// A customizable text field component following the design system.
///
/// Example usage:
/// ```dart
/// AppTextField(
///   label: 'Email',
///   hint: 'Enter your email',
///   keyboardType: TextInputType.emailAddress,
/// )
///
/// AppTextField.password(
///   label: 'Password',
///   controller: passwordController,
/// )
///
/// AppTextField.search(
///   hint: 'Search exercises...',
///   onChanged: (value) => searchExercises(value),
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.variant = AppTextFieldVariant.outlined,
    this.size = AppTextFieldSize.md,
    this.fieldState = AppTextFieldState.normal,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
  });

  /// Password field factory
  factory AppTextField.password({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? helperText,
    String? errorText,
    AppTextFieldVariant variant = AppTextFieldVariant.outlined,
    AppTextFieldSize size = AppTextFieldSize.md,
    AppTextFieldState fieldState = AppTextFieldState.normal,
    bool enabled = true,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
    FocusNode? focusNode,
  }) {
    return _PasswordTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      variant: variant,
      size: size,
      fieldState: fieldState,
      enabled: enabled,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      focusNode: focusNode,
    );
  }

  /// Search field factory
  factory AppTextField.search({
    Key? key,
    TextEditingController? controller,
    String? hint,
    AppTextFieldSize size = AppTextFieldSize.md,
    bool enabled = true,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
    FocusNode? focusNode,
  }) {
    return _SearchTextField(
      key: key,
      controller: controller,
      hint: hint,
      size: size,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onClear: onClear,
      focusNode: focusNode,
    );
  }

  /// Multiline text area factory
  const AppTextField.textArea({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.variant = AppTextFieldVariant.outlined,
    this.size = AppTextFieldSize.md,
    this.fieldState = AppTextFieldState.normal,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 4,
    this.minLines = 3,
    this.maxLength,
    this.showCounter = true,
    this.onChanged,
    this.onTap,
    this.validator,
    this.focusNode,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = true,
  })  : obscureText = false,
        keyboardType = TextInputType.multiline,
        textInputAction = TextInputAction.newline,
        inputFormatters = null,
        prefixIcon = null,
        suffixIcon = null,
        prefix = null,
        suffix = null,
        onSubmitted = null;

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final AppTextFieldVariant variant;
  final AppTextFieldSize size;
  final AppTextFieldState fieldState;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool showCounter;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool autocorrect;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError =
        widget.fieldState == AppTextFieldState.error || widget.errorText != null;
    final hasSuccess = widget.fieldState == AppTextFieldState.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: _getLabelColor(isDark, hasError, hasSuccess),
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
        ],
        AnimatedContainer(
          duration: AppTheme.durationFast,
          curve: AppTheme.curveDefault,
          decoration: _getDecoration(isDark, hasError, hasSuccess),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            autocorrect: widget.autocorrect,
            style: _getTextStyle(isDark),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: _getHintStyle(isDark),
              contentPadding: _getContentPadding(),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              counterText: widget.showCounter ? null : '',
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: _getIconSize(),
                      color: _getIconColor(isDark, hasError, hasSuccess),
                    )
                  : widget.prefix,
              suffixIcon: widget.suffixIcon != null
                  ? Icon(
                      widget.suffixIcon,
                      size: _getIconSize(),
                      color: _getIconColor(isDark, hasError, hasSuccess),
                    )
                  : widget.suffix,
            ),
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            validator: widget.validator,
          ),
        ),
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: AppTheme.spacing1),
          Text(
            widget.errorText ?? widget.helperText!,
            style: AppTextStyles.bodySmall.copyWith(
              color: hasError
                  ? AppColors.error
                  : (isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight),
            ),
          ),
        ],
      ],
    );
  }

  BoxDecoration _getDecoration(bool isDark, bool hasError, bool hasSuccess) {
    switch (widget.variant) {
      case AppTextFieldVariant.outlined:
        return BoxDecoration(
          color: widget.enabled
              ? (isDark ? AppColors.inputDark : AppColors.surface1Light)
              : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: _getBorderColor(isDark, hasError, hasSuccess),
            width: _isFocused ? 2 : 1,
          ),
        );

      case AppTextFieldVariant.filled:
        return BoxDecoration(
          color: widget.enabled
              ? (isDark ? AppColors.surface2Dark : AppColors.surface2Light)
              : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: _isFocused
              ? Border.all(
                  color: _getBorderColor(isDark, hasError, hasSuccess),
                  width: 2,
                )
              : null,
        );

      case AppTextFieldVariant.underlined:
        return BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _getBorderColor(isDark, hasError, hasSuccess),
              width: _isFocused ? 2 : 1,
            ),
          ),
        );
    }
  }

  Color _getBorderColor(bool isDark, bool hasError, bool hasSuccess) {
    if (hasError) return AppColors.error;
    if (hasSuccess) return AppColors.success;
    if (_isFocused) return isDark ? AppColors.ringDark : AppColors.ringLight;
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  Color _getLabelColor(bool isDark, bool hasError, bool hasSuccess) {
    if (hasError) return AppColors.error;
    if (hasSuccess) return AppColors.success;
    if (_isFocused) return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
  }

  Color _getIconColor(bool isDark, bool hasError, bool hasSuccess) {
    if (hasError) return AppColors.error;
    if (hasSuccess) return AppColors.success;
    if (_isFocused) return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
  }

  TextStyle _getTextStyle(bool isDark) {
    final baseStyle = switch (widget.size) {
      AppTextFieldSize.sm => AppTextStyles.bodyMedium,
      AppTextFieldSize.md => AppTextStyles.bodyLarge,
      AppTextFieldSize.lg => AppTextStyles.titleMedium,
    };
    return baseStyle.copyWith(
      color: widget.enabled
          ? (isDark ? AppColors.foregroundDark : AppColors.foregroundLight)
          : (isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight),
    );
  }

  TextStyle _getHintStyle(bool isDark) {
    final baseStyle = switch (widget.size) {
      AppTextFieldSize.sm => AppTextStyles.bodyMedium,
      AppTextFieldSize.md => AppTextStyles.bodyLarge,
      AppTextFieldSize.lg => AppTextStyles.titleMedium,
    };
    return baseStyle.copyWith(
      color: isDark
          ? AppColors.mutedForegroundDark
          : AppColors.mutedForegroundLight,
    );
  }

  EdgeInsets _getContentPadding() {
    return switch (widget.size) {
      AppTextFieldSize.sm =>
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      AppTextFieldSize.md =>
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      AppTextFieldSize.lg =>
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    };
  }

  double _getIconSize() {
    return switch (widget.size) {
      AppTextFieldSize.sm => 18,
      AppTextFieldSize.md => 20,
      AppTextFieldSize.lg => 24,
    };
  }
}

/// Password text field with toggle visibility
class _PasswordTextField extends AppTextField {
  const _PasswordTextField({
    super.key,
    super.controller,
    super.label,
    super.hint,
    super.helperText,
    super.errorText,
    super.variant,
    super.size,
    super.fieldState,
    super.enabled,
    super.textInputAction,
    super.onChanged,
    super.onSubmitted,
    super.validator,
    super.focusNode,
  }) : super(
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          autocorrect: false,
        );

  @override
  State<AppTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends _AppTextFieldState {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError =
        widget.fieldState == AppTextFieldState.error || widget.errorText != null;
    final hasSuccess = widget.fieldState == AppTextFieldState.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: _getLabelColor(isDark, hasError, hasSuccess),
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
        ],
        AnimatedContainer(
          duration: AppTheme.durationFast,
          curve: AppTheme.curveDefault,
          decoration: _getDecoration(isDark, hasError, hasSuccess),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            enabled: widget.enabled,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: widget.textInputAction,
            autocorrect: false,
            style: _getTextStyle(isDark),
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Enter password',
              hintStyle: _getHintStyle(isDark),
              contentPadding: _getContentPadding(),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Icon(
                Icons.lock_outline,
                size: _getIconSize(),
                color: _getIconColor(isDark, hasError, hasSuccess),
              ),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscureText = !_obscureText),
                child: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: _getIconSize(),
                  color: _getIconColor(isDark, hasError, hasSuccess),
                ),
              ),
            ),
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
          ),
        ),
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: AppTheme.spacing1),
          Text(
            widget.errorText ?? widget.helperText!,
            style: AppTextStyles.bodySmall.copyWith(
              color: hasError
                  ? AppColors.error
                  : (isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight),
            ),
          ),
        ],
      ],
    );
  }
}

/// Search text field with clear button
class _SearchTextField extends AppTextField {
  const _SearchTextField({
    super.key,
    super.controller,
    super.hint,
    super.size,
    super.enabled,
    super.autofocus,
    super.onChanged,
    super.onSubmitted,
    this.onClear,
    super.focusNode,
  }) : super(
          variant: AppTextFieldVariant.filled,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        );

  final VoidCallback? onClear;

  @override
  State<AppTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends _AppTextFieldState {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleTextChange);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleTextChange);
    }
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    (widget as _SearchTextField).onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: AppTheme.durationFast,
      curve: AppTheme.curveDefault,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: _isFocused
            ? Border.all(
                color: isDark ? AppColors.ringDark : AppColors.ringLight,
                width: 2,
              )
            : null,
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        style: _getTextStyle(isDark),
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Search...',
          hintStyle: _getHintStyle(isDark),
          contentPadding: _getContentPadding(),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            size: _getIconSize(),
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
          suffixIcon: _hasText
              ? GestureDetector(
                  onTap: _clearText,
                  child: Icon(
                    Icons.close,
                    size: _getIconSize(),
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                )
              : null,
        ),
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
      ),
    );
  }
}
```

### Usage Examples

```dart
// Basic text field
AppTextField(
  label: 'Email',
  hint: 'Enter your email address',
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.email_outlined,
)

// Password field
AppTextField.password(
  label: 'Password',
  hint: 'Enter your password',
  helperText: 'Must be at least 8 characters',
  controller: passwordController,
  onChanged: (value) => validatePassword(value),
)

// Search field
AppTextField.search(
  hint: 'Search exercises...',
  onChanged: (value) => filterExercises(value),
  onClear: () => clearSearch(),
)

// Text area
AppTextField.textArea(
  label: 'Notes',
  hint: 'Add workout notes...',
  maxLength: 500,
  showCounter: true,
)

// Error state
AppTextField(
  label: 'Username',
  fieldState: AppTextFieldState.error,
  errorText: 'Username already taken',
  controller: usernameController,
)

// Filled variant
AppTextField(
  label: 'Phone',
  variant: AppTextFieldVariant.filled,
  keyboardType: TextInputType.phone,
  prefixIcon: Icons.phone_outlined,
)

// With validation
AppTextField(
  label: 'Weight (kg)',
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
  ],
  validator: (value) {
    if (value == null || value.isEmpty) return 'Required';
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0) return 'Enter valid weight';
    return null;
  },
)
```

### Accessibility Notes
- Labels associated with input fields for screen readers
- Error messages announced when field has error
- Minimum touch target of 44px height
- High contrast between text and background
- Clear visual distinction between states
- Password visibility toggle accessible via tap and keyboard

---

## Status

**Documented**: 3 components
- ✅ AppButton (8 variants)
- ✅ AppCard (6 variants + 2 specialized)
- ✅ AppTextField (3 variants + 3 specialized)

**Next Session**: Continue with the following components:
- Avatar / UserAvatar
- Badge / Chip
- BottomSheet / Modal
- Navigation components (BottomNav, AppBar)
- List / ListTile
- Progress indicators

---

> **Note**: Start a new chat to continue with the next batch of components to maintain optimal context and avoid token limits.
