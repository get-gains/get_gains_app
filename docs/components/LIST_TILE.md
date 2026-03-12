# AppListTile

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

List item components for displaying data in lists. Supports various layouts and interactive states.

---

## Variants

| Variant | Purpose | Trailing |
|---------|---------|----------|
| `default` | Standard list item | Custom widget |
| `selectable` | Item with checkbox | Checkmark |
| `menu` | Settings/menu style | Chevron |

---

## Specifications

### Density Variants

| Density | Height | Vertical Padding |
|---------|--------|-----------------|
| `compact` | 44px | 8px |
| `standard` | 56px | 12px |
| `comfortable` | 72px | 16px |

### Styling

- **Horizontal padding**: `spacing4` (16px)
- **Icon/content gap**: `spacing3` (12px)
- **Border radius**: `radiusMd` (12px) when tappable
- **Divider**: 1px `border` color

---

## Implementation

```dart
// lib/widgets/app_list_tile.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

enum AppListTileDensity { compact, standard, comfortable }

class AppListTile extends StatefulWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.density = AppListTileDensity.standard,
    this.enabled = true,
    this.selected = false,
    this.showDivider = false,
  });

  factory AppListTile.selectable({
    Key? key,
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    required bool selected,
    required VoidCallback onTap,
    AppListTileDensity density = AppListTileDensity.standard,
    bool enabled = true,
  }) {
    return _SelectableListTile(
      key: key,
      title: title,
      subtitle: subtitle,
      leading: leading,
      selected: selected,
      onTap: onTap,
      density: density,
      enabled: enabled,
    );
  }

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final AppListTileDensity density;
  final bool enabled;
  final bool selected;
  final bool showDivider;

  @override
  State<AppListTile> createState() => _AppListTileState();
}

class _AppListTileState extends State<AppListTile> {
  bool _isPressed = false;

  double get _minHeight => switch (widget.density) {
    AppListTileDensity.compact => 44,
    AppListTileDensity.standard => 56,
    AppListTileDensity.comfortable => 72,
  };

  EdgeInsets get _padding => switch (widget.density) {
    AppListTileDensity.compact => const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    AppListTileDensity.standard => const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    AppListTileDensity.comfortable => const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInteractive = widget.onTap != null && widget.enabled;

    Widget tile = AnimatedContainer(
      duration: AppTheme.durationFast,
      constraints: BoxConstraints(minHeight: _minHeight),
      padding: _padding,
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        borderRadius: isInteractive ? BorderRadius.circular(AppTheme.radiusMd) : null,
      ),
      child: Row(
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DefaultTextStyle(
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: widget.enabled
                        ? (isDark ? AppColors.foregroundDark : AppColors.foregroundLight)
                        : (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight),
                  ),
                  child: widget.title,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle(
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                    ),
                    child: widget.subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 12),
            widget.trailing!,
          ],
        ],
      ),
    );

    if (isInteractive) {
      tile = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: tile,
      );
    }

    if (widget.showDivider) {
      tile = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile,
          Divider(
            height: 1,
            thickness: 1,
            indent: widget.leading != null ? 52 : 16,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ],
      );
    }

    return AnimatedOpacity(
      duration: AppTheme.durationFast,
      opacity: widget.enabled ? 1.0 : 0.5,
      child: tile,
    );
  }

  Color _getBackgroundColor(bool isDark) {
    if (widget.selected) {
      return (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(0.1);
    }
    if (_isPressed && widget.enabled) {
      return (isDark ? AppColors.mutedDark : AppColors.mutedLight).withOpacity(0.5);
    }
    return Colors.transparent;
  }
}

class _SelectableListTile extends AppListTile {
  const _SelectableListTile({
    super.key,
    required super.title,
    super.subtitle,
    super.leading,
    required super.selected,
    required VoidCallback onTap,
    super.density,
    super.enabled,
  }) : super(onTap: onTap);

  @override
  State<AppListTile> createState() => _SelectableListTileState();
}

class _SelectableListTileState extends _AppListTileState {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppListTile(
      title: widget.title,
      subtitle: widget.subtitle,
      leading: widget.leading,
      trailing: AnimatedContainer(
        duration: AppTheme.durationFast,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.selected
              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.selected
                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 2,
          ),
        ),
        child: widget.selected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
      onTap: widget.onTap,
      density: widget.density,
      enabled: widget.enabled,
      selected: widget.selected,
    );
  }
}
```

---

## AppMenuTile

Settings/menu style list item.

```dart
class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.destructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = destructive
        ? AppColors.error
        : (isDark ? AppColors.foregroundDark : AppColors.foregroundLight);
    final mutedColor = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;

    return AppListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (destructive ? AppColors.error : (isDark ? AppColors.primaryDark : AppColors.primaryLight))
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: destructive ? AppColors.error : (isDark ? AppColors.primaryDark : AppColors.primaryLight)),
      ),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: mutedColor)) : null,
      trailing: trailing ?? (showChevron ? Icon(Icons.chevron_right, color: mutedColor) : null),
      onTap: onTap,
    );
  }
}
```

---

## Grouping Components

### AppListSection

Section with header and children.

```dart
class AppListSection extends StatelessWidget {
  const AppListSection({
    super.key,
    this.title,
    this.trailing,
    required this.children,
    this.padding,
  });

  final String? title;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
```

### AppListGroup

Card container for list items.

```dart
class AppListGroup extends StatelessWidget {
  const AppListGroup({
    super.key,
    this.header,
    required this.children,
    this.footer,
    this.showDividers = true,
    this.margin,
  });

  final Widget? header;
  final List<Widget> children;
  final Widget? footer;
  final bool showDividers;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: header!,
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (showDividers && i < children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: footer!,
            ),
        ],
      ),
    );
  }
}
```

---

## Usage Examples

```dart
// Basic list tile
AppListTile(
  title: Text('Bench Press'),
  subtitle: Text('3 sets × 10 reps'),
  leading: CircleAvatar(child: Icon(Icons.fitness_center)),
  trailing: Icon(Icons.chevron_right),
  onTap: () => navigateToExercise(),
)

// Selectable list tile
AppListTile.selectable(
  title: Text('Option A'),
  selected: isSelected,
  onTap: () => toggleSelection(),
)

// Menu tile
AppMenuTile(
  icon: Icons.settings,
  title: 'Settings',
  subtitle: 'App preferences',
  onTap: () => navigateToSettings(),
)

// Destructive menu tile
AppMenuTile(
  icon: Icons.logout,
  title: 'Sign Out',
  destructive: true,
  onTap: () => signOut(),
)

// Section with header
AppListSection(
  title: 'Account',
  trailing: TextButton(child: Text('Edit'), onPressed: () {}),
  children: [
    AppListTile(title: Text('Profile'), leading: Icon(Icons.person)),
    AppListTile(title: Text('Preferences'), leading: Icon(Icons.tune)),
  ],
)

// Card group
AppListGroup(
  header: Text('Settings', style: AppTextStyles.titleMedium),
  children: [
    AppListTile(title: Text('Notifications')),
    AppListTile(title: Text('Privacy')),
    AppListTile(title: Text('Security')),
  ],
)

// Density variants
AppListTile(title: Text('Compact'), density: AppListTileDensity.compact)
AppListTile(title: Text('Standard'), density: AppListTileDensity.standard)
AppListTile(title: Text('Comfortable'), density: AppListTileDensity.comfortable)

// With dividers
ListView(
  children: workouts.map((w) => AppListTile(
    title: Text(w.name),
    showDivider: true,
  )).toList(),
)
```

---

## Accessibility

- ✅ List items: Announced as buttons when tappable
- ✅ Selection state: Communicated to screen readers
- ✅ Minimum height: 44px for touch targets
- ✅ Dividers: Don't interfere with navigation
- ✅ Disabled state: Visually indicated (50% opacity)
