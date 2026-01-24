// lib/widgets/app_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Navigation item for bottom navigation bar
class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badge,
  });

  /// Icon when inactive
  final IconData icon;

  /// Icon when active (defaults to filled version)
  final IconData? activeIcon;

  /// Label text
  final String label;

  /// Optional badge count (shown as notification dot/count)
  final int? badge;
}

/// A customizable bottom navigation bar following the design system.
///
/// Example usage:
/// ```dart
/// AppBottomNavBar(
///   currentIndex: _selectedIndex,
///   onTap: (index) => setState(() => _selectedIndex = index),
///   items: [
///     AppNavItem(icon: Icons.home_outlined, label: 'Home', activeIcon: Icons.home),
///     AppNavItem(icon: Icons.fitness_center_outlined, label: 'Workouts'),
///     AppNavItem(icon: Icons.bar_chart_outlined, label: 'Progress'),
///     AppNavItem(icon: Icons.person_outline, label: 'Profile'),
///   ],
/// )
/// ```
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.showLabels = true,
    this.elevation = 0,
    this.borderRadius,
    this.margin,
    this.height = 64,
  });

  /// Currently selected index
  final int currentIndex;

  /// Callback when an item is tapped
  final ValueChanged<int> onTap;

  /// Navigation items
  final List<AppNavItem> items;

  /// Background color (defaults to card color)
  final Color? backgroundColor;

  /// Color for selected items
  final Color? selectedColor;

  /// Color for unselected items
  final Color? unselectedColor;

  /// Whether to show labels below icons
  final bool showLabels;

  /// Elevation/shadow of the nav bar
  final double elevation;

  /// Border radius for floating nav bar style
  final BorderRadius? borderRadius;

  /// Margin around the nav bar (for floating style)
  final EdgeInsets? margin;

  /// Height of the nav bar
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final bgColor =
        backgroundColor ?? (isDark ? AppColors.cardDark : AppColors.cardLight);
    final selectedClr =
        selectedColor ??
        (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final unselectedClr =
        unselectedColor ??
        (isDark
            ? AppColors.mutedForegroundDark
            : AppColors.mutedForegroundLight);

    Widget navBar = Container(
      height: height + (margin != null ? 0 : bottomPadding),
      padding: EdgeInsets.only(bottom: margin != null ? 0 : bottomPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: borderRadius != null
            ? null
            : Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
              ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: elevation * 2,
                  offset: Offset(0, -elevation / 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          return _NavBarItem(
            item: items[index],
            isSelected: currentIndex == index,
            selectedColor: selectedClr,
            unselectedColor: unselectedClr,
            showLabel: showLabels,
            onTap: () => onTap(index),
          );
        }),
      ),
    );

    if (margin != null) {
      navBar = Padding(
        padding: margin!.copyWith(bottom: margin!.bottom + bottomPadding),
        child: ClipRRect(
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
          child: navBar,
        ),
      );
    }

    return navBar;
  }
}

class _NavBarItem extends StatefulWidget {
  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.showLabel,
    required this.onTap,
  });

  final AppNavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? widget.selectedColor
        : widget.unselectedColor;
    final icon = widget.isSelected
        ? (widget.item.activeIcon ?? widget.item.icon)
        : widget.item.icon;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
          HapticFeedback.selectionClick();
        },
        onTapCancel: () => _controller.reverse(),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? widget.selectedColor.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(icon, size: 24, color: color),
                    ),
                    // Badge
                    if (widget.item.badge != null && widget.item.badge! > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            widget.item.badge! > 99
                                ? '99+'
                                : widget.item.badge.toString(),
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamilySans,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                if (widget.showLabel) ...[
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamilySans,
                      fontSize: 11,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: color,
                    ),
                    child: Text(widget.item.label),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A customizable app bar following the design system.
///
/// Example usage:
/// ```dart
/// AppTopBar(
///   title: 'Workouts',
///   leading: AppTopBarAction(
///     icon: Icons.arrow_back,
///     onPressed: () => Navigator.pop(context),
///   ),
///   actions: [
///     AppTopBarAction(
///       icon: Icons.search,
///       onPressed: () => showSearch(),
///     ),
///     AppTopBarAction(
///       icon: Icons.more_vert,
///       onPressed: () => showOptions(),
///     ),
///   ],
/// )
/// ```
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = false,
    this.titleSpacing,
    this.toolbarHeight = kToolbarHeight,
    this.automaticallyImplyLeading = true,
    this.scrolledUnderElevation,
    this.showDivider = false,
  });

  /// Title text
  final String? title;

  /// Custom title widget (overrides title)
  final Widget? titleWidget;

  /// Subtitle text below title
  final String? subtitle;

  /// Leading widget/action
  final Widget? leading;

  /// Trailing action widgets
  final List<Widget>? actions;

  /// Bottom widget (e.g., TabBar)
  final PreferredSizeWidget? bottom;

  /// Background color
  final Color? backgroundColor;

  /// Foreground/text color
  final Color? foregroundColor;

  /// Elevation/shadow
  final double elevation;

  /// Whether to center the title
  final bool centerTitle;

  /// Spacing for title from leading
  final double? titleSpacing;

  /// Height of the toolbar
  final double toolbarHeight;

  /// Whether to show back button automatically
  final bool automaticallyImplyLeading;

  /// Elevation when scrolled under
  final double? scrolledUnderElevation;

  /// Whether to show bottom divider
  final bool showDivider;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);
    final fgColor =
        foregroundColor ??
        (isDark ? AppColors.foregroundDark : AppColors.foregroundLight);

    Widget? titleContent;
    if (titleWidget != null) {
      titleContent = titleWidget;
    } else if (title != null) {
      if (subtitle != null) {
        titleContent = Column(
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title!,
              style: AppTextStyles.titleLarge.copyWith(color: fgColor),
            ),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
          ],
        );
      } else {
        titleContent = Text(
          title!,
          style: AppTextStyles.titleLarge.copyWith(color: fgColor),
        );
      }
    }

    return AppBar(
      title: titleContent,
      leading: leading,
      actions: actions,
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: bottom!.preferredSize,
              child: Column(
                children: [
                  bottom!,
                  if (showDivider)
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                ],
              ),
            )
          : (showDivider
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  )
                : null),
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation ?? elevation,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: automaticallyImplyLeading,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );
  }
}

/// Action button for app bar
///
/// Example usage:
/// ```dart
/// AppTopBarAction(
///   icon: Icons.search,
///   onPressed: () => showSearch(),
///   tooltip: 'Search',
/// )
/// ```
class AppTopBarAction extends StatelessWidget {
  const AppTopBarAction({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.badge,
    this.color,
    this.backgroundColor,
  });

  /// Icon to display
  final IconData icon;

  /// Callback when pressed
  final VoidCallback? onPressed;

  /// Tooltip text
  final String? tooltip;

  /// Badge count
  final int? badge;

  /// Icon color
  final Color? color;

  /// Background color for the button
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final iconColor =
        color ??
        (isDark ? AppColors.foregroundDark : AppColors.foregroundLight);
    final bgColor = backgroundColor;

    Widget button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: bgColor,
        shape: const CircleBorder(),
      ),
    );

    if (badge != null && badge! > 0) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  width: 2,
                ),
              ),
              child: Text(
                badge! > 99 ? '99+' : badge.toString(),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamilySans,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
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

/// Back button for app bar with consistent styling
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.icon, this.color});

  /// Custom callback (defaults to Navigator.pop)
  final VoidCallback? onPressed;

  /// Custom icon (defaults to arrow_back_ios_new)
  final IconData? icon;

  /// Icon color
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      icon: Icon(
        icon ?? Icons.arrow_back_ios_new,
        color:
            color ??
            (isDark ? AppColors.foregroundDark : AppColors.foregroundLight),
        size: 20,
      ),
      tooltip: 'Back',
    );
  }
}

/// Close button for app bar with consistent styling
class AppCloseButton extends StatelessWidget {
  const AppCloseButton({
    super.key,
    this.onPressed,
    this.color,
    this.backgroundColor,
  });

  /// Custom callback (defaults to Navigator.pop)
  final VoidCallback? onPressed;

  /// Icon color
  final Color? color;

  /// Background color
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      icon: Icon(
        Icons.close,
        color:
            color ??
            (isDark ? AppColors.foregroundDark : AppColors.foregroundLight),
      ),
      style: IconButton.styleFrom(
        backgroundColor:
            backgroundColor ??
            (isDark ? AppColors.secondaryDark : AppColors.secondaryLight),
        shape: const CircleBorder(),
      ),
      tooltip: 'Close',
    );
  }
}

/// Large title header for scrollable pages
///
/// Example usage:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     AppSliverHeader(
///       title: 'Workouts',
///       subtitle: '12 total',
///       actions: [
///         AppTopBarAction(icon: Icons.add, onPressed: () {}),
///       ],
///     ),
///     // ... rest of content
///   ],
/// )
/// ```
class AppSliverHeader extends StatelessWidget {
  const AppSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.expandedHeight = 120,
    this.collapsedHeight,
    this.pinned = true,
    this.floating = false,
    this.backgroundColor,
  });

  /// Title text
  final String title;

  /// Subtitle text
  final String? subtitle;

  /// Trailing actions
  final List<Widget>? actions;

  /// Height when expanded
  final double expandedHeight;

  /// Height when collapsed
  final double? collapsedHeight;

  /// Whether to pin the header when scrolling
  final bool pinned;

  /// Whether to float when scrolling back
  final bool floating;

  /// Background color
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      pinned: pinned,
      floating: floating,
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: AppTheme.spacing5,
          bottom: AppTheme.spacing4,
        ),
        expandedTitleScale: 1.0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
