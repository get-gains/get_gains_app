# AppNavigation

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

App-wide navigation components including bottom navigation bar for tab switching and top app bar for page headers.

---

## Components

| Component | Purpose |
|-----------|---------|
| `AppBottomNavBar` | Primary tab navigation at bottom |
| `AppTopBar` | Page header with title and actions |
| `AppSliverHeader` | Large scrollable header for lists |

---

## AppBottomNavBar

### Specifications

- **Height**: 64px + safe area
- **Background**: `card` color
- **Active color**: `primary`
- **Inactive color**: `mutedForeground`
- **Icon size**: 24px
- **Label font**: `labelSmall` (10px)

### Styles

| Style | Description |
|-------|-------------|
| `default` | Full-width, border top |
| `floating` | Rounded corners, margin, elevation |

### Implementation

```dart
// lib/widgets/app_navigation.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badge,
  });

  final IconData icon;
  final String label;
  final IconData? activeIcon;
  final int? badge;
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isFloating = false,
    this.margin,
    this.borderRadius,
    this.elevation = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavItem> items;
  final bool isFloating;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inactiveColor = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;
    final backgroundColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    Widget navBar = Container(
      height: 64,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: isFloating ? (borderRadius ?? BorderRadius.circular(24)) : null,
        border: !isFloating ? Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)) : null,
        boxShadow: elevation > 0
            ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: elevation * 2, offset: Offset(0, -elevation))]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = index == currentIndex;
          return _NavItemWidget(
            item: item,
            isActive: isActive,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            onTap: () => onTap(index),
          );
        }).toList(),
      ),
    );

    if (isFloating) {
      navBar = Padding(
        padding: margin ?? const EdgeInsets.all(16),
        child: navBar,
      );
    }

    return SafeArea(
      top: false,
      child: navBar,
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  const _NavItemWidget({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final AppNavItem item;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: AppTheme.durationFast,
                  child: Icon(
                    isActive ? (item.activeIcon ?? item.icon) : item.icon,
                    key: ValueKey(isActive),
                    size: 24,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
                if (item.badge != null && item.badge! > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        item.badge! > 99 ? '99+' : '${item.badge}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## AppTopBar

### Specifications

- **Height**: 56px (standard) / 64px (with subtitle)
- **Background**: `background` color (or transparent)
- **Title**: `titleLarge` style
- **Actions**: Icon buttons with optional badges

### Implementation

```dart
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.elevation = 0,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    (subtitle != null ? 64 : 56) + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Column(
        crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
              ),
            ),
        ],
      ),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
      elevation: elevation,
      scrolledUnderElevation: elevation,
      bottom: bottom,
      iconTheme: IconThemeData(color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight),
    );
  }
}

/// Action button for top bar
class AppTopBarAction extends StatelessWidget {
  const AppTopBarAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.badge,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final int? badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
    );

    if (badge != null && badge! > 0) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badge! > 99 ? '99+' : '$badge',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return button;
  }
}

/// Back button for navigation
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: 'Back',
    );
  }
}

/// Close button for modals
class AppCloseButton extends StatelessWidget {
  const AppCloseButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: 'Close',
    );
  }
}
```

---

## AppSliverHeader

### Specifications

- **Expanded height**: 120px (default)
- **Collapsed height**: 56px (AppBar height)
- **Title**: Large typography when expanded

### Implementation

```dart
class AppSliverHeader extends StatelessWidget {
  const AppSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.expandedHeight = 120,
    this.pinned = true,
    this.floating = false,
    this.backgroundColor,
    this.flexibleSpace,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final Color? backgroundColor;
  final Widget? flexibleSpace;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      backgroundColor: backgroundColor ?? (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
      actions: actions,
      flexibleSpace: flexibleSpace ?? FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                ),
              ),
          ],
        ),
        expandedTitleScale: 1.0,
      ),
    );
  }
}
```

---

## Usage Examples

```dart
// Bottom navigation
AppBottomNavBar(
  currentIndex: _selectedIndex,
  onTap: (index) => setState(() => _selectedIndex = index),
  items: [
    AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    AppNavItem(icon: Icons.fitness_center_outlined, label: 'Workouts'),
    AppNavItem(icon: Icons.bar_chart_outlined, label: 'Progress'),
    AppNavItem(icon: Icons.person_outline, label: 'Profile', badge: 3),
  ],
)

// Floating bottom nav
AppBottomNavBar(
  currentIndex: _selectedIndex,
  onTap: onTap,
  items: items,
  isFloating: true,
  margin: EdgeInsets.all(16),
  borderRadius: BorderRadius.circular(24),
  elevation: 8,
)

// Top app bar
AppTopBar(
  title: 'Workouts',
  leading: AppBackButton(),
  actions: [
    AppTopBarAction(icon: Icons.search, onPressed: () => showSearch()),
    AppTopBarAction(icon: Icons.more_vert, onPressed: () => showMenu()),
  ],
)

// Top bar with subtitle
AppTopBar(
  title: 'John Doe',
  subtitle: 'Premium Member',
  centerTitle: true,
)

// Sliver header in CustomScrollView
CustomScrollView(
  slivers: [
    AppSliverHeader(
      title: 'My Workouts',
      subtitle: '12 total',
      actions: [
        AppTopBarAction(icon: Icons.add, onPressed: () => addWorkout()),
      ],
    ),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => WorkoutTile(workout: workouts[index]),
        childCount: workouts.length,
      ),
    ),
  ],
)
```

---

## Accessibility

- ✅ Navigation items: Have semantic labels
- ✅ Badge counts: Announced to screen readers
- ✅ Back/close buttons: Have proper tooltips
- ✅ Touch targets: Minimum 48px
- ✅ Active state: Visually distinct and announced
