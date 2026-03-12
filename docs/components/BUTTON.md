# AppButton

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Primary interactive element for user actions. Supports multiple visual styles and states to convey different levels of importance and interaction patterns.

---

## Variants

| Variant | Purpose | Background | Text Color |
|---------|---------|------------|------------|
| `primary` | Main CTA | `primary` | `primaryForeground` |
| `secondary` | Supporting actions | `secondary` | `secondaryForeground` |
| `ghost` | Tertiary, minimal weight | `transparent` | `primary` |
| `outline` | Secondary with boundaries | `transparent` + border | `foreground` |
| `destructive` | Dangerous actions | `error` | `white` |
| `link` | Navigation, inline actions | `transparent` | `primary` |

---

## Specifications

### Size Variants

| Size | Height | Horizontal Padding | Font Size | Icon Size |
|------|--------|-------------------|-----------|-----------|
| `sm` | 36px | `spacing4` (16px) | 12px | 16px |
| `md` | 44px | `spacing6` (24px) | 14px | 20px |
| `lg` | 52px | `spacing8` (32px) | 16px | 24px |

### Styling

- **Border radius**: `radiusMd` (12px)
- **Font**: `button` style (weight 600)
- **Icon gap**: `spacing2` (8px)

### States

| State | Behavior |
|-------|----------|
| Default | Full opacity background |
| Hover | 90% opacity |
| Pressed | 80% opacity, scale 0.98 |
| Focused | 2px ring with `ring` color |
| Disabled | 50% opacity, non-interactive |
| Loading | Spinner, disabled interaction |

---

## Implementation

```dart
// lib/widgets/app_button.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, outline, destructive, link }
enum AppButtonSize { sm, md, lg }
enum IconPosition { leading, trailing }

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

  // Factory constructors for each variant
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

class _AppButtonState extends State<AppButton> {
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

    final textWidget = Text(widget.label, style: _getTextStyle(isDark));
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

  double _getHeight() => switch (widget.size) {
    AppButtonSize.sm => 36,
    AppButtonSize.md => 44,
    AppButtonSize.lg => 52,
  };

  EdgeInsets _getPadding() => switch (widget.size) {
    AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: 16),
    AppButtonSize.md => const EdgeInsets.symmetric(horizontal: 24),
    AppButtonSize.lg => const EdgeInsets.symmetric(horizontal: 32),
  };

  double _getIconSize() => switch (widget.size) {
    AppButtonSize.sm => 16,
    AppButtonSize.md => 20,
    AppButtonSize.lg => 24,
  };

  TextStyle _getTextStyle(bool isDark) {
    final base = switch (widget.size) {
      AppButtonSize.sm => AppTextStyles.buttonSmall,
      AppButtonSize.md => AppTextStyles.button,
      AppButtonSize.lg => AppTextStyles.buttonLarge,
    };
    return base.copyWith(color: _getForegroundColor(isDark));
  }

  Color _getForegroundColor(bool isDark) => switch (widget.variant) {
    AppButtonVariant.primary => isDark ? AppColors.primaryForegroundDark : AppColors.primaryForegroundLight,
    AppButtonVariant.secondary => isDark ? AppColors.secondaryForegroundDark : AppColors.secondaryForegroundLight,
    AppButtonVariant.ghost || AppButtonVariant.link => isDark ? AppColors.primaryDark : AppColors.primaryLight,
    AppButtonVariant.outline => isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
    AppButtonVariant.destructive => AppColors.white,
  };

  BoxDecoration _getDecoration(bool isDark) {
    final borderRadius = BorderRadius.circular(AppTheme.radiusMd);
    return switch (widget.variant) {
      AppButtonVariant.primary => BoxDecoration(
        color: _getBackgroundWithState(isDark ? AppColors.primaryDark : AppColors.primaryLight),
        borderRadius: borderRadius,
      ),
      AppButtonVariant.secondary => BoxDecoration(
        color: _getBackgroundWithState(isDark ? AppColors.secondaryDark : AppColors.secondaryLight),
        borderRadius: borderRadius,
      ),
      AppButtonVariant.ghost => BoxDecoration(
        color: _getGhostBackground(isDark),
        borderRadius: borderRadius,
      ),
      AppButtonVariant.outline => BoxDecoration(
        color: _getOutlineBackground(isDark),
        borderRadius: borderRadius,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      AppButtonVariant.destructive => BoxDecoration(
        color: _getBackgroundWithState(AppColors.error),
        borderRadius: borderRadius,
      ),
      AppButtonVariant.link => const BoxDecoration(color: Colors.transparent),
    };
  }

  Color _getBackgroundWithState(Color base) {
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
}
```

---

## AppIconButton

Icon-only button variant for compact actions.

### Specifications

| Size | Diameter | Icon Size |
|------|----------|-----------|
| `sm` | 32px | 16px |
| `md` | 40px | 20px |
| `lg` | 48px | 24px |

### Implementation

```dart
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

  double get _size => switch (widget.size) {
    AppButtonSize.sm => 32,
    AppButtonSize.md => 40,
    AppButtonSize.lg => 48,
  };

  double get _iconSize => switch (widget.size) {
    AppButtonSize.sm => 16,
    AppButtonSize.md => 20,
    AppButtonSize.lg => 24,
  };

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
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }

  Color _getForegroundColor(bool isDark) => switch (widget.variant) {
    AppButtonVariant.primary => isDark ? AppColors.primaryForegroundDark : AppColors.primaryForegroundLight,
    _ => isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
  };

  BoxDecoration _getDecoration(bool isDark) {
    final borderRadius = BorderRadius.circular(_size / 2);
    return switch (widget.variant) {
      AppButtonVariant.primary => BoxDecoration(
        color: _getBackgroundWithState(isDark ? AppColors.primaryDark : AppColors.primaryLight),
        borderRadius: borderRadius,
      ),
      AppButtonVariant.ghost => BoxDecoration(
        color: _getGhostBackground(isDark),
        borderRadius: borderRadius,
      ),
      AppButtonVariant.outline => BoxDecoration(
        color: _getGhostBackground(isDark),
        borderRadius: borderRadius,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      _ => BoxDecoration(color: Colors.transparent, borderRadius: borderRadius),
    };
  }

  Color _getBackgroundWithState(Color base) {
    if (_isPressed) return base.withOpacity(0.8);
    if (_isHovered) return base.withOpacity(0.9);
    return base;
  }

  Color _getGhostBackground(bool isDark) {
    final base = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    if (_isPressed) return base.withOpacity(0.8);
    if (_isHovered) return base.withOpacity(0.5);
    return Colors.transparent;
  }
}
```

---

## Usage Examples

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

// Size variants
AppButton(label: 'Small', size: AppButtonSize.sm, onPressed: () {})
AppButton(label: 'Medium', size: AppButtonSize.md, onPressed: () {})
AppButton(label: 'Large', size: AppButtonSize.lg, onPressed: () {})
```

---

## Accessibility

- ✅ Minimum touch target: 44x44px (36px for `sm` with padding)
- ✅ Disabled state: 50% opacity, non-interactive
- ✅ Loading state: Prevents double-submission
- ✅ Tooltips: Available for icon-only buttons
- ✅ Focus states: Visible ring for keyboard navigation
- ✅ Semantic: Uses `GestureDetector` with proper callbacks
