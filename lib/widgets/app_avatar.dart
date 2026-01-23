// lib/widgets/app_avatar.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Avatar size options
enum AppAvatarSize {
  /// 24x24px - Extra small, for dense lists
  xs,

  /// 32x32px - Small, for compact UI
  sm,

  /// 40x40px - Medium, default size
  md,

  /// 48x48px - Large, for profile sections
  lg,

  /// 64x64px - Extra large, for profile headers
  xl,

  /// 96x96px - 2X large, for profile pages
  xxl,
}

/// Avatar shape options
enum AppAvatarShape {
  /// Circular avatar (default)
  circle,

  /// Rounded square avatar
  rounded,
}

/// Avatar status indicator options
enum AppAvatarStatus {
  /// No status indicator
  none,

  /// Online/active status (green)
  online,

  /// Offline/inactive status (gray)
  offline,

  /// Away/idle status (yellow)
  away,

  /// Do not disturb status (red)
  busy,
}

/// A customizable avatar component following the design system.
///
/// Displays user images, initials, or icons in a consistent circular
/// or rounded container. Supports status indicators and grouping.
///
/// Example usage:
/// ```dart
/// // Image avatar
/// AppAvatar(
///   imageUrl: 'https://example.com/avatar.jpg',
///   name: 'John Doe',
/// )
///
/// // Initials avatar
/// AppAvatar(
///   name: 'John Doe',
///   size: AppAvatarSize.lg,
/// )
///
/// // Icon avatar
/// AppAvatar.icon(
///   icon: Icons.person,
///   backgroundColor: AppColors.primaryDark,
/// )
///
/// // Avatar with status
/// AppAvatar(
///   imageUrl: user.avatarUrl,
///   name: user.name,
///   status: AppAvatarStatus.online,
/// )
/// ```
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.md,
    this.shape = AppAvatarShape.circle,
    this.status = AppAvatarStatus.none,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.child,
  }) : _icon = null;

  /// Creates an avatar with an icon
  const AppAvatar.icon({
    super.key,
    required IconData icon,
    this.size = AppAvatarSize.md,
    this.shape = AppAvatarShape.circle,
    this.status = AppAvatarStatus.none,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.onTap,
  }) : imageUrl = null,
       name = null,
       child = null,
       _icon = icon;

  /// Creates an avatar with custom content
  const AppAvatar.custom({
    super.key,
    required this.child,
    this.size = AppAvatarSize.md,
    this.shape = AppAvatarShape.circle,
    this.status = AppAvatarStatus.none,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.onTap,
  }) : imageUrl = null,
       name = null,
       _icon = null;

  /// URL of the avatar image
  final String? imageUrl;

  /// Name used to generate initials when no image is available
  final String? name;

  /// Size of the avatar
  final AppAvatarSize size;

  /// Shape of the avatar
  final AppAvatarShape shape;

  /// Status indicator to display
  final AppAvatarStatus status;

  /// Background color (defaults to primary with opacity)
  final Color? backgroundColor;

  /// Foreground color for initials/icon (defaults to primary)
  final Color? foregroundColor;

  /// Optional border color
  final Color? borderColor;

  /// Border width (defaults to 0)
  final double? borderWidth;

  /// Callback when avatar is tapped
  final VoidCallback? onTap;

  /// Custom child widget
  final Widget? child;

  /// Icon to display (from icon factory)
  final IconData? _icon;

  /// Get avatar diameter based on size
  double get _diameter {
    switch (size) {
      case AppAvatarSize.xs:
        return 24;
      case AppAvatarSize.sm:
        return 32;
      case AppAvatarSize.md:
        return 40;
      case AppAvatarSize.lg:
        return 48;
      case AppAvatarSize.xl:
        return 64;
      case AppAvatarSize.xxl:
        return 96;
    }
  }

  /// Get icon size based on avatar size
  double get _iconSize {
    switch (size) {
      case AppAvatarSize.xs:
        return 14;
      case AppAvatarSize.sm:
        return 16;
      case AppAvatarSize.md:
        return 20;
      case AppAvatarSize.lg:
        return 24;
      case AppAvatarSize.xl:
        return 32;
      case AppAvatarSize.xxl:
        return 48;
    }
  }

  /// Get font size for initials based on avatar size
  double get _fontSize {
    switch (size) {
      case AppAvatarSize.xs:
        return 10;
      case AppAvatarSize.sm:
        return 12;
      case AppAvatarSize.md:
        return 14;
      case AppAvatarSize.lg:
        return 16;
      case AppAvatarSize.xl:
        return 24;
      case AppAvatarSize.xxl:
        return 36;
    }
  }

  /// Get status indicator size
  double get _statusSize {
    switch (size) {
      case AppAvatarSize.xs:
        return 8;
      case AppAvatarSize.sm:
        return 10;
      case AppAvatarSize.md:
        return 12;
      case AppAvatarSize.lg:
        return 14;
      case AppAvatarSize.xl:
        return 16;
      case AppAvatarSize.xxl:
        return 20;
    }
  }

  /// Get border radius based on shape
  BorderRadius get _borderRadius {
    if (shape == AppAvatarShape.circle) {
      return BorderRadius.circular(AppTheme.radiusFull);
    }
    // Rounded square with proportional radius
    return BorderRadius.circular(_diameter * 0.25);
  }

  /// Generate initials from name
  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';

    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  /// Get status indicator color
  Color _getStatusColor() {
    switch (status) {
      case AppAvatarStatus.none:
        return Colors.transparent;
      case AppAvatarStatus.online:
        return AppColors.success;
      case AppAvatarStatus.offline:
        return AppColors.gray500;
      case AppAvatarStatus.away:
        return AppColors.warning;
      case AppAvatarStatus.busy:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
        backgroundColor ??
        (isDark
            ? AppColors.primaryDark.withOpacity(0.15)
            : AppColors.primaryLight.withOpacity(0.15));

    final fgColor =
        foregroundColor ??
        (isDark ? AppColors.primaryDark : AppColors.primaryLight);

    Widget avatar = Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: _borderRadius,
        border: borderWidth != null && borderWidth! > 0
            ? Border.all(
                color:
                    borderColor ??
                    (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: borderWidth!,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(fgColor, isDark),
    );

    // Add status indicator if needed
    if (status != AppAvatarStatus.none) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: _statusSize,
              height: _statusSize,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Wrap with gesture detector if tappable
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: avatar),
      );
    }

    return avatar;
  }

  Widget _buildContent(Color fgColor, bool isDark) {
    // Custom child takes priority
    if (child != null) {
      return Center(child: child);
    }

    // Icon avatar
    if (_icon != null) {
      return Center(
        child: Icon(_icon, size: _iconSize, color: fgColor),
      );
    }

    // Image avatar
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: _diameter,
        height: _diameter,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to initials on error
          return _buildInitials(fgColor);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: _iconSize,
              height: _iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: fgColor,
              ),
            ),
          );
        },
      );
    }

    // Initials fallback
    return _buildInitials(fgColor);
  }

  Widget _buildInitials(Color fgColor) {
    return Center(
      child: Text(
        _getInitials(),
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamilySans,
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
          color: fgColor,
        ),
      ),
    );
  }
}

/// A group of overlapping avatars.
///
/// Useful for displaying multiple users in a compact space.
///
/// Example usage:
/// ```dart
/// AppAvatarGroup(
///   avatars: [
///     AppAvatar(imageUrl: user1.avatarUrl, name: user1.name),
///     AppAvatar(imageUrl: user2.avatarUrl, name: user2.name),
///     AppAvatar(imageUrl: user3.avatarUrl, name: user3.name),
///   ],
///   maxVisible: 3,
///   onExcessTap: () => showAllUsers(),
/// )
/// ```
class AppAvatarGroup extends StatelessWidget {
  const AppAvatarGroup({
    super.key,
    required this.avatars,
    this.size = AppAvatarSize.md,
    this.maxVisible = 4,
    this.overlapFactor = 0.3,
    this.borderWidth = 2,
    this.onExcessTap,
  });

  /// List of avatars to display
  final List<AppAvatar> avatars;

  /// Size of all avatars in the group
  final AppAvatarSize size;

  /// Maximum number of avatars to show before "+N" indicator
  final int maxVisible;

  /// How much avatars overlap (0.0 to 1.0)
  final double overlapFactor;

  /// Border width around each avatar
  final double borderWidth;

  /// Callback when "+N" excess indicator is tapped
  final VoidCallback? onExcessTap;

  double get _diameter {
    switch (size) {
      case AppAvatarSize.xs:
        return 24;
      case AppAvatarSize.sm:
        return 32;
      case AppAvatarSize.md:
        return 40;
      case AppAvatarSize.lg:
        return 48;
      case AppAvatarSize.xl:
        return 64;
      case AppAvatarSize.xxl:
        return 96;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppAvatarSize.xs:
        return 8;
      case AppAvatarSize.sm:
        return 10;
      case AppAvatarSize.md:
        return 12;
      case AppAvatarSize.lg:
        return 14;
      case AppAvatarSize.xl:
        return 18;
      case AppAvatarSize.xxl:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    final visibleAvatars = avatars.take(maxVisible).toList();
    final excessCount = avatars.length - maxVisible;
    final overlap = _diameter * overlapFactor;

    return SizedBox(
      height: _diameter,
      child: Stack(
        children: [
          // Render visible avatars
          for (int i = 0; i < visibleAvatars.length; i++)
            Positioned(
              left: i * (_diameter - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: AppAvatar(
                  imageUrl: visibleAvatars[i].imageUrl,
                  name: visibleAvatars[i].name,
                  size: size,
                  backgroundColor: visibleAvatars[i].backgroundColor,
                  foregroundColor: visibleAvatars[i].foregroundColor,
                ),
              ),
            ),

          // Excess indicator
          if (excessCount > 0)
            Positioned(
              left: visibleAvatars.length * (_diameter - overlap),
              child: GestureDetector(
                onTap: onExcessTap,
                child: Container(
                  width: _diameter,
                  height: _diameter,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.secondaryDark
                        : AppColors.secondaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                  child: Center(
                    child: Text(
                      '+$excessCount',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamilySans,
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight,
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
