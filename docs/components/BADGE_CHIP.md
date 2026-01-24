# AppBadge & AppChip

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

**Badges** display status, labels, or counts in a compact form.
**Chips** represent selection, filtering, or actions.

---

## AppBadge

### Variants

| Variant | Background | Text | Usage |
|---------|------------|------|-------|
| `secondary` | `secondary` | `mutedForeground` | Neutral information |
| `primary` | `primary` 15% | `primary` | Highlighted info |
| `success` | `success` 15% | `success` | Positive states |
| `warning` | `warning` 15% | `warning` | Caution states |
| `error` | `error` 15% | `error` | Error/critical states |
| `info` | `info` 15% | `info` | Informational |
| `outline` | transparent | `foreground` | Minimal weight |
| `dot` | variant color | - | Notification indicator |

### Size Variants

| Size | Height | Font Size | Horizontal Padding |
|------|--------|-----------|-------------------|
| `sm` | 18px | 10px | 6px |
| `md` | 22px | 11px | 8px |
| `lg` | 26px | 12px | 10px |

### Implementation

```dart
// lib/widgets/app_badge.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

enum AppBadgeVariant { secondary, primary, success, warning, error, info, outline }
enum AppBadgeSize { sm, md, lg }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.secondary,
    this.size = AppBadgeSize.md,
    this.icon,
  }) : isDot = false;

  const AppBadge.dot({
    super.key,
    this.variant = AppBadgeVariant.error,
  })  : label = '',
        size = AppBadgeSize.sm,
        icon = null,
        isDot = true;

  final String label;
  final AppBadgeVariant variant;
  final AppBadgeSize size;
  final IconData? icon;
  final bool isDot;

  double get _height => switch (size) {
    AppBadgeSize.sm => 18,
    AppBadgeSize.md => 22,
    AppBadgeSize.lg => 26,
  };

  double get _fontSize => switch (size) {
    AppBadgeSize.sm => 10,
    AppBadgeSize.md => 11,
    AppBadgeSize.lg => 12,
  };

  EdgeInsets get _padding => switch (size) {
    AppBadgeSize.sm => const EdgeInsets.symmetric(horizontal: 6),
    AppBadgeSize.md => const EdgeInsets.symmetric(horizontal: 8),
    AppBadgeSize.lg => const EdgeInsets.symmetric(horizontal: 10),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dot variant
    if (isDot) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _getBackgroundColor(isDark, solid: true),
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      height: _height,
      padding: _padding,
      decoration: BoxDecoration(
        color: variant == AppBadgeVariant.outline ? Colors.transparent : _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: variant == AppBadgeVariant.outline
            ? Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _fontSize, color: _getTextColor(isDark)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilySans,
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
              color: _getTextColor(isDark),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(bool isDark, {bool solid = false}) {
    final opacity = solid ? 1.0 : 0.15;
    return switch (variant) {
      AppBadgeVariant.secondary => isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
      AppBadgeVariant.primary => (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(opacity),
      AppBadgeVariant.success => AppColors.success.withOpacity(opacity),
      AppBadgeVariant.warning => AppColors.warning.withOpacity(opacity),
      AppBadgeVariant.error => AppColors.error.withOpacity(opacity),
      AppBadgeVariant.info => const Color(0xFF3B82F6).withOpacity(opacity),
      AppBadgeVariant.outline => Colors.transparent,
    };
  }

  Color _getTextColor(bool isDark) => switch (variant) {
    AppBadgeVariant.secondary => isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
    AppBadgeVariant.primary => isDark ? AppColors.primaryDark : AppColors.primaryLight,
    AppBadgeVariant.success => AppColors.success,
    AppBadgeVariant.warning => AppColors.warning,
    AppBadgeVariant.error => AppColors.error,
    AppBadgeVariant.info => const Color(0xFF3B82F6),
    AppBadgeVariant.outline => isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
  };
}
```

---

## AppChip

### Variants

| Variant | Background | Border | Selected State |
|---------|------------|--------|----------------|
| `filled` | `secondary` | none | `primary` bg, white text |
| `outlined` | transparent | 1px `border` | `primary` border |
| `tonal` | `primary` 15% | none | Darker primary bg |

### Size Variants

| Size | Height | Font Size | Icon Size |
|------|--------|-----------|-----------|
| `sm` | 28px | 12px | 14px |
| `md` | 32px | 13px | 16px |
| `lg` | 40px | 14px | 18px |

### Implementation

```dart
enum AppChipVariant { filled, outlined, tonal }
enum AppChipSize { sm, md, lg }

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.filled,
    this.size = AppChipSize.md,
    this.selected = false,
    this.icon,
    this.onSelected,
    this.onDeleted,
    this.enabled = true,
  });

  final String label;
  final AppChipVariant variant;
  final AppChipSize size;
  final bool selected;
  final IconData? icon;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final bool enabled;

  double get _height => switch (size) {
    AppChipSize.sm => 28,
    AppChipSize.md => 32,
    AppChipSize.lg => 40,
  };

  double get _fontSize => switch (size) {
    AppChipSize.sm => 12,
    AppChipSize.md => 13,
    AppChipSize.lg => 14,
  };

  double get _iconSize => switch (size) {
    AppChipSize.sm => 14,
    AppChipSize.md => 16,
    AppChipSize.lg => 18,
  };

  EdgeInsets get _padding => switch (size) {
    AppChipSize.sm => const EdgeInsets.symmetric(horizontal: 10),
    AppChipSize.md => const EdgeInsets.symmetric(horizontal: 12),
    AppChipSize.lg => const EdgeInsets.symmetric(horizontal: 16),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInteractive = onSelected != null || onDeleted != null;

    Widget chip = AnimatedContainer(
      duration: AppTheme.durationFast,
      height: _height,
      padding: _padding,
      decoration: _getDecoration(isDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _iconSize, color: _getTextColor(isDark)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilySans,
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
              color: _getTextColor(isDark),
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: enabled ? onDeleted : null,
              child: Icon(
                Icons.close,
                size: _iconSize - 2,
                color: _getTextColor(isDark).withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );

    if (isInteractive && enabled) {
      chip = GestureDetector(
        onTap: onSelected != null ? () => onSelected!(!selected) : null,
        child: chip,
      );
    }

    return AnimatedOpacity(
      duration: AppTheme.durationFast,
      opacity: enabled ? 1.0 : 0.5,
      child: chip,
    );
  }

  BoxDecoration _getDecoration(bool isDark) {
    return switch (variant) {
      AppChipVariant.filled => BoxDecoration(
        color: selected
            ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
            : (isDark ? AppColors.secondaryDark : AppColors.secondaryLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      AppChipVariant.outlined => BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: selected
              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: selected ? 2 : 1,
        ),
      ),
      AppChipVariant.tonal => BoxDecoration(
        color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
            .withOpacity(selected ? 0.3 : 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
    };
  }

  Color _getTextColor(bool isDark) {
    if (variant == AppChipVariant.filled && selected) {
      return Colors.white;
    }
    if (variant == AppChipVariant.tonal || (variant == AppChipVariant.outlined && selected)) {
      return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    }
    return isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
  }
}
```

---

## AppChipGroup

Horizontal scrolling group of chips.

```dart
class AppChipGroup extends StatelessWidget {
  const AppChipGroup({
    super.key,
    required this.chips,
    this.spacing = 8,
    this.scrollable = true,
    this.padding,
  });

  final List<AppChip> chips;
  final double spacing;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final content = Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: chips,
    );

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
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

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: content,
    );
  }
}
```

---

## Usage Examples

### Badges

```dart
// Status badge
AppBadge(
  label: 'Active',
  variant: AppBadgeVariant.success,
)

// Count badge
AppBadge(
  label: '5',
  variant: AppBadgeVariant.primary,
)

// With icon
AppBadge(
  label: 'New',
  variant: AppBadgeVariant.info,
  icon: Icons.star,
)

// Dot indicator
AppBadge.dot(variant: AppBadgeVariant.error)

// Different sizes
AppBadge(label: 'Small', size: AppBadgeSize.sm)
AppBadge(label: 'Medium', size: AppBadgeSize.md)
AppBadge(label: 'Large', size: AppBadgeSize.lg)

// Outline variant
AppBadge(
  label: 'Draft',
  variant: AppBadgeVariant.outline,
)
```

### Chips

```dart
// Selectable chip
AppChip(
  label: 'Strength',
  selected: isSelected,
  onSelected: (selected) => setState(() => isSelected = selected),
)

// With icon
AppChip(
  label: 'Running',
  icon: Icons.directions_run,
  selected: true,
)

// Deletable chip
AppChip(
  label: 'Tag Name',
  onDeleted: () => removeTag(),
)

// Outlined variant
AppChip(
  label: 'Option',
  variant: AppChipVariant.outlined,
  selected: isSelected,
  onSelected: (v) => toggle(),
)

// Tonal variant
AppChip(
  label: 'Featured',
  variant: AppChipVariant.tonal,
)

// Chip group
AppChipGroup(
  chips: [
    AppChip(label: 'All', selected: filter == 'all', onSelected: (_) => setFilter('all')),
    AppChip(label: 'Strength', selected: filter == 'strength', onSelected: (_) => setFilter('strength')),
    AppChip(label: 'Cardio', selected: filter == 'cardio', onSelected: (_) => setFilter('cardio')),
    AppChip(label: 'Flexibility', selected: filter == 'flex', onSelected: (_) => setFilter('flex')),
  ],
  spacing: 8,
)

// Filter chips with delete
Wrap(
  spacing: 8,
  children: selectedTags.map((tag) => AppChip(
    label: tag,
    onDeleted: () => removeTag(tag),
  )).toList(),
)
```

---

## Accessibility

### Badges
- ✅ Color alone doesn't convey meaning (label included)
- ✅ Sufficient contrast for all variants
- ✅ Dot badges should have additional context nearby

### Chips
- ✅ Selection state: Announced to screen readers
- ✅ Delete buttons: Have appropriate labels
- ✅ Touch targets: Meet minimum 44px requirement (via padding)
- ✅ Disabled state: Visually indicated (50% opacity)
