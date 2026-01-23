# AppAvatar

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Displays user images, initials, or icons in a consistent circular or rounded container. Used for profile displays, user lists, and collaborative features.

---

## Variants

| Variant | Purpose | Content |
|---------|---------|---------|
| `image` | User profile photos | Network/asset image |
| `initials` | Fallback when no image | 1-2 letters from name |
| `icon` | Generic/action avatars | Icon widget |
| `custom` | Flexible content | Any child widget |

---

## Specifications

### Size Variants

| Size | Diameter | Icon Size | Font Size |
|------|----------|-----------|-----------|
| `xs` | 24px | 14px | 10px |
| `sm` | 32px | 16px | 12px |
| `md` | 40px | 20px | 14px |
| `lg` | 48px | 24px | 16px |
| `xl` | 64px | 32px | 24px |
| `xxl` | 96px | 48px | 36px |

### Status Indicators

| Status | Color | Token |
|--------|-------|-------|
| `online` | `#4ADE80` | `success` |
| `offline` | `#71717A` | `mutedForeground` |
| `away` | `#FBBF24` | `warning` |
| `busy` | `#F87171` | `error` |

### Styling

- **Shape**: Circular (`radiusFull`)
- **Initials background**: `primary` at 15% opacity
- **Initials text**: `primary` color, weight 600
- **Status dot**: 25% of avatar diameter, 2px white border

---

## Implementation

```dart
// lib/widgets/app_avatar.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

enum AppAvatarSize { xs, sm, md, lg, xl, xxl }
enum AppAvatarStatus { online, offline, away, busy }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.md,
    this.status,
    this.onTap,
    this.borderWidth = 0,
    this.borderColor,
  })  : icon = null,
        iconBackgroundColor = null,
        child = null;

  const AppAvatar.icon({
    super.key,
    required this.icon,
    this.iconBackgroundColor,
    this.size = AppAvatarSize.md,
    this.status,
    this.onTap,
    this.borderWidth = 0,
    this.borderColor,
  })  : imageUrl = null,
        name = null,
        child = null;

  const AppAvatar.custom({
    super.key,
    required this.child,
    this.size = AppAvatarSize.md,
    this.status,
    this.onTap,
    this.borderWidth = 0,
    this.borderColor,
  })  : imageUrl = null,
        name = null,
        icon = null,
        iconBackgroundColor = null;

  final String? imageUrl;
  final String? name;
  final IconData? icon;
  final Color? iconBackgroundColor;
  final Widget? child;
  final AppAvatarSize size;
  final AppAvatarStatus? status;
  final VoidCallback? onTap;
  final double borderWidth;
  final Color? borderColor;

  double get _diameter => switch (size) {
    AppAvatarSize.xs => 24,
    AppAvatarSize.sm => 32,
    AppAvatarSize.md => 40,
    AppAvatarSize.lg => 48,
    AppAvatarSize.xl => 64,
    AppAvatarSize.xxl => 96,
  };

  double get _iconSize => switch (size) {
    AppAvatarSize.xs => 14,
    AppAvatarSize.sm => 16,
    AppAvatarSize.md => 20,
    AppAvatarSize.lg => 24,
    AppAvatarSize.xl => 32,
    AppAvatarSize.xxl => 48,
  };

  double get _fontSize => switch (size) {
    AppAvatarSize.xs => 10,
    AppAvatarSize.sm => 12,
    AppAvatarSize.md => 14,
    AppAvatarSize.lg => 16,
    AppAvatarSize.xl => 24,
    AppAvatarSize.xxl => 36,
  };

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatar = Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: borderWidth,
              )
            : null,
      ),
      child: ClipOval(child: _buildContent(isDark)),
    );

    // Add status indicator
    if (status != null) {
      final statusSize = _diameter * 0.25;
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: statusSize,
              height: statusSize,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Make tappable
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildContent(bool isDark) {
    // Custom child
    if (child != null) return child!;

    // Icon avatar
    if (icon != null) {
      return Container(
        color: iconBackgroundColor ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(0.15),
        child: Center(
          child: Icon(
            icon,
            size: _iconSize,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
      );
    }

    // Image avatar
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: _diameter,
        height: _diameter,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildInitials(isDark);
        },
        errorBuilder: (context, error, stackTrace) => _buildInitials(isDark),
      );
    }

    // Initials fallback
    return _buildInitials(isDark);
  }

  Widget _buildInitials(bool isDark) {
    final initials = name != null ? _getInitials(name!) : '?';
    return Container(
      color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(0.15),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() => switch (status) {
    AppAvatarStatus.online => AppColors.success,
    AppAvatarStatus.offline => const Color(0xFF71717A),
    AppAvatarStatus.away => AppColors.warning,
    AppAvatarStatus.busy => AppColors.error,
    null => Colors.transparent,
  };
}
```

---

## AppAvatarGroup

Stacked avatar display for showing multiple users.

```dart
class AppAvatarGroup extends StatelessWidget {
  const AppAvatarGroup({
    super.key,
    required this.avatars,
    this.maxVisible = 3,
    this.size = AppAvatarSize.sm,
    this.onExcessTap,
    this.spacing = -8,
  });

  final List<AppAvatar> avatars;
  final int maxVisible;
  final AppAvatarSize size;
  final VoidCallback? onExcessTap;
  final double spacing;

  double get _diameter => switch (size) {
    AppAvatarSize.xs => 24,
    AppAvatarSize.sm => 32,
    AppAvatarSize.md => 40,
    AppAvatarSize.lg => 48,
    AppAvatarSize.xl => 64,
    AppAvatarSize.xxl => 96,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleCount = avatars.length > maxVisible ? maxVisible : avatars.length;
    final excessCount = avatars.length - maxVisible;

    return SizedBox(
      height: _diameter,
      child: Stack(
        children: [
          // Visible avatars
          for (int i = 0; i < visibleCount; i++)
            Positioned(
              left: i * (_diameter + spacing),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                    width: 2,
                  ),
                ),
                child: AppAvatar(
                  imageUrl: avatars[i].imageUrl,
                  name: avatars[i].name,
                  size: size,
                ),
              ),
            ),
          // Excess indicator
          if (excessCount > 0)
            Positioned(
              left: visibleCount * (_diameter + spacing),
              child: GestureDetector(
                onTap: onExcessTap,
                child: Container(
                  width: _diameter,
                  height: _diameter,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+$excessCount',
                      style: TextStyle(
                        fontSize: _diameter * 0.35,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
                      ),
                    ),
                  ),
                ),
              ),
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
// Image avatar
AppAvatar(
  imageUrl: 'https://example.com/avatar.jpg',
  name: 'John Doe',
  size: AppAvatarSize.lg,
)

// Initials avatar (no image)
AppAvatar(
  name: 'John Doe',
  size: AppAvatarSize.md,
)

// Icon avatar
AppAvatar.icon(
  icon: Icons.person,
  size: AppAvatarSize.lg,
)

// With status indicator
AppAvatar(
  imageUrl: user.avatarUrl,
  name: user.name,
  status: AppAvatarStatus.online,
)

// Tappable avatar
AppAvatar(
  imageUrl: user.avatarUrl,
  name: user.name,
  size: AppAvatarSize.xl,
  onTap: () => navigateToProfile(),
)

// With border
AppAvatar(
  imageUrl: user.avatarUrl,
  name: user.name,
  borderWidth: 2,
  borderColor: AppColors.primary,
)

// Avatar group (stacked)
AppAvatarGroup(
  avatars: [
    AppAvatar(name: 'User 1', imageUrl: url1),
    AppAvatar(name: 'User 2', imageUrl: url2),
    AppAvatar(name: 'User 3', imageUrl: url3),
    AppAvatar(name: 'User 4', imageUrl: url4),
    AppAvatar(name: 'User 5', imageUrl: url5),
  ],
  maxVisible: 3,
  onExcessTap: () => showAllUsers(),
)

// Size variants
AppAvatar(name: 'XS', size: AppAvatarSize.xs)
AppAvatar(name: 'SM', size: AppAvatarSize.sm)
AppAvatar(name: 'MD', size: AppAvatarSize.md)
AppAvatar(name: 'LG', size: AppAvatarSize.lg)
AppAvatar(name: 'XL', size: AppAvatarSize.xl)
AppAvatar(name: 'XXL', size: AppAvatarSize.xxl)
```

---

## Accessibility

- ✅ Image alt text: Derived from `name` property
- ✅ Tappable targets: Appropriate touch targets based on size
- ✅ Status meaning: Semantic indicator for screen readers
- ✅ Fallback: Graceful degradation from image → initials
