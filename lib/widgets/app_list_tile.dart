// lib/widgets/app_list_tile.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Density options for list tiles
enum AppListTileDensity {
  /// Compact density (less padding)
  compact,

  /// Standard density (default)
  standard,

  /// Comfortable density (more padding)
  comfortable,
}

/// A customizable list tile following the design system.
///
/// Example usage:
/// ```dart
/// // Basic list tile
/// AppListTile(
///   title: 'Bench Press',
///   subtitle: '3 sets × 10 reps',
///   leading: CircleAvatar(child: Icon(Icons.fitness_center)),
///   trailing: Icon(Icons.chevron_right),
///   onTap: () => navigateToExercise(),
/// )
///
/// // With switch
/// AppListTile(
///   title: 'Dark Mode',
///   leading: Icon(Icons.dark_mode),
///   trailing: Switch(value: isDark, onChanged: toggleTheme),
/// )
///
/// // Selectable tile
/// AppListTile.selectable(
///   title: 'Option A',
///   selected: isSelected,
///   onTap: () => selectOption(),
/// )
/// ```
class AppListTile extends StatefulWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
    this.density = AppListTileDensity.standard,
    this.contentPadding,
    this.backgroundColor,
    this.selectedColor,
    this.shape,
    this.titleStyle,
    this.subtitleStyle,
    this.leadingAndTrailingColor,
    this.showDivider = false,
    this.dividerIndent = 0,
  }) : _isSelectable = false;

  /// Creates a selectable list tile with checkmark indicator
  const AppListTile.selectable({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
    this.density = AppListTileDensity.standard,
    this.contentPadding,
    this.backgroundColor,
    this.selectedColor,
    this.shape,
    this.titleStyle,
    this.subtitleStyle,
    this.leadingAndTrailingColor,
    this.showDivider = false,
    this.dividerIndent = 0,
  }) : trailing = null,
       _isSelectable = true;

  /// Title text or widget
  final dynamic title;

  /// Subtitle text or widget
  final dynamic subtitle;

  /// Leading widget (icon, avatar, etc.)
  final Widget? leading;

  /// Trailing widget (icon, switch, etc.)
  final Widget? trailing;

  /// Callback when tile is tapped
  final VoidCallback? onTap;

  /// Callback when tile is long pressed
  final VoidCallback? onLongPress;

  /// Whether the tile is enabled
  final bool enabled;

  /// Whether the tile is selected
  final bool selected;

  /// Density of the tile
  final AppListTileDensity density;

  /// Custom content padding
  final EdgeInsets? contentPadding;

  /// Background color
  final Color? backgroundColor;

  /// Color when selected
  final Color? selectedColor;

  /// Custom shape
  final ShapeBorder? shape;

  /// Custom title text style
  final TextStyle? titleStyle;

  /// Custom subtitle text style
  final TextStyle? subtitleStyle;

  /// Color for leading and trailing widgets
  final Color? leadingAndTrailingColor;

  /// Whether to show a divider below
  final bool showDivider;

  /// Indent for divider
  final double dividerIndent;

  final bool _isSelectable;

  @override
  State<AppListTile> createState() => _AppListTileState();
}

class _AppListTileState extends State<AppListTile> {
  bool _isPressed = false;

  EdgeInsets get _padding {
    if (widget.contentPadding != null) return widget.contentPadding!;

    switch (widget.density) {
      case AppListTileDensity.compact:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppListTileDensity.standard:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case AppListTileDensity.comfortable:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }

  double get _minHeight {
    switch (widget.density) {
      case AppListTileDensity.compact:
        return 44;
      case AppListTileDensity.standard:
        return 56;
      case AppListTileDensity.comfortable:
        return 72;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final bgColor = widget.backgroundColor ?? Colors.transparent;
    final selectedBgColor =
        widget.selectedColor ?? primaryColor.withOpacity(0.1);

    Color textColor;
    Color subtitleColor;
    Color iconColor;

    if (!widget.enabled) {
      textColor =
          (isDark ? AppColors.foregroundDark : AppColors.foregroundLight)
              .withOpacity(0.5);
      subtitleColor =
          (isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight)
              .withOpacity(0.5);
      iconColor =
          (isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight)
              .withOpacity(0.5);
    } else if (widget.selected) {
      textColor = primaryColor;
      subtitleColor = primaryColor.withOpacity(0.7);
      iconColor = widget.leadingAndTrailingColor ?? primaryColor;
    } else {
      textColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
      subtitleColor = isDark
          ? AppColors.mutedForegroundDark
          : AppColors.mutedForegroundLight;
      iconColor = widget.leadingAndTrailingColor ?? subtitleColor;
    }

    // Build title widget
    Widget titleWidget;
    if (widget.title is Widget) {
      titleWidget = widget.title as Widget;
    } else {
      titleWidget = Text(
        widget.title.toString(),
        style:
            widget.titleStyle ??
            AppTextStyles.bodyLarge.copyWith(
              color: textColor,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Build subtitle widget
    Widget? subtitleWidget;
    if (widget.subtitle != null) {
      if (widget.subtitle is Widget) {
        subtitleWidget = widget.subtitle as Widget;
      } else {
        subtitleWidget = Text(
          widget.subtitle.toString(),
          style:
              widget.subtitleStyle ??
              AppTextStyles.bodySmall.copyWith(color: subtitleColor),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    // Build trailing widget
    Widget? trailingWidget;
    if (widget._isSelectable) {
      trailingWidget = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.selected ? primaryColor : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.selected
                ? primaryColor
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 2,
          ),
        ),
        child: widget.selected
            ? const Icon(Icons.check, size: 16, color: AppColors.white)
            : null,
      );
    } else if (widget.trailing != null) {
      trailingWidget = IconTheme(
        data: IconThemeData(color: iconColor, size: 24),
        child: widget.trailing!,
      );
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      constraints: BoxConstraints(minHeight: _minHeight),
      padding: _padding,
      decoration: BoxDecoration(
        color: widget.selected
            ? selectedBgColor
            : (_isPressed
                  ? (isDark
                        ? AppColors.secondaryDark
                        : AppColors.secondaryLight)
                  : bgColor),
        borderRadius: widget.shape != null
            ? null
            : BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          // Leading
          if (widget.leading != null) ...[
            IconTheme(
              data: IconThemeData(color: iconColor, size: 24),
              child: widget.leading!,
            ),
            const SizedBox(width: 16),
          ],

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                titleWidget,
                if (subtitleWidget != null) ...[
                  const SizedBox(height: 2),
                  subtitleWidget,
                ],
              ],
            ),
          ),

          // Trailing
          if (trailingWidget != null) ...[
            const SizedBox(width: 16),
            trailingWidget,
          ],
        ],
      ),
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      content = GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: content,
        ),
      );
    }

    if (widget.showDivider) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          Padding(
            padding: EdgeInsets.only(left: widget.dividerIndent),
            child: Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ],
      );
    }

    return content;
  }
}

/// A section header for grouped lists
///
/// Example usage:
/// ```dart
/// Column(
///   children: [
///     AppListSection(
///       title: 'Account',
///       children: [
///         AppListTile(title: 'Profile'),
///         AppListTile(title: 'Preferences'),
///       ],
///     ),
///     AppListSection(
///       title: 'About',
///       children: [
///         AppListTile(title: 'Version'),
///         AppListTile(title: 'Privacy Policy'),
///       ],
///     ),
///   ],
/// )
/// ```
class AppListSection extends StatelessWidget {
  const AppListSection({
    super.key,
    this.title,
    this.titleWidget,
    this.trailing,
    required this.children,
    this.padding,
    this.headerPadding,
    this.backgroundColor,
    this.showDividers = false,
    this.dividerIndent = 56,
  });

  /// Section title text
  final String? title;

  /// Custom title widget
  final Widget? titleWidget;

  /// Trailing widget in header (e.g., "See all" button)
  final Widget? trailing;

  /// List tiles in this section
  final List<Widget> children;

  /// Padding around the section
  final EdgeInsets? padding;

  /// Padding for the header
  final EdgeInsets? headerPadding;

  /// Background color for the section
  final Color? backgroundColor;

  /// Whether to show dividers between items
  final bool showDividers;

  /// Indent for dividers (typically matches leading widget)
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: backgroundColor != null
          ? BoxDecoration(color: backgroundColor)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          if (title != null || titleWidget != null) ...[
            Padding(
              padding:
                  headerPadding ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child:
                        titleWidget ??
                        Text(
                          title!.toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ],

          // Children
          if (showDividers)
            ...List.generate(children.length * 2 - 1, (index) {
              if (index.isEven) {
                return children[index ~/ 2];
              } else {
                return Padding(
                  padding: EdgeInsets.only(left: dividerIndent),
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                );
              }
            })
          else
            ...children,
        ],
      ),
    );
  }
}

/// A grouped card container for list tiles
///
/// Example usage:
/// ```dart
/// AppListGroup(
///   children: [
///     AppListTile(title: 'Item 1'),
///     AppListTile(title: 'Item 2'),
///     AppListTile(title: 'Item 3'),
///   ],
/// )
/// ```
class AppListGroup extends StatelessWidget {
  const AppListGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.backgroundColor,
    this.borderRadius,
    this.showDividers = true,
    this.dividerIndent = 16,
    this.margin,
    this.padding,
  });

  /// List tiles in the group
  final List<Widget> children;

  /// Header widget above the group
  final Widget? header;

  /// Footer widget below the group
  final Widget? footer;

  /// Background color
  final Color? backgroundColor;

  /// Border radius for the card
  final BorderRadius? borderRadius;

  /// Whether to show dividers between items
  final bool showDividers;

  /// Indent for dividers
  final double dividerIndent;

  /// Margin around the group
  final EdgeInsets? margin;

  /// Padding inside the group
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
        backgroundColor ?? (isDark ? AppColors.cardDark : AppColors.cardLight);
    final radius = borderRadius ?? BorderRadius.circular(AppTheme.radiusLg);

    List<Widget> items;
    if (showDividers && children.length > 1) {
      items = List.generate(children.length * 2 - 1, (index) {
        if (index.isEven) {
          return children[index ~/ 2];
        } else {
          return Padding(
            padding: EdgeInsets.only(left: dividerIndent),
            child: Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          );
        }
      });
    } else {
      items = children;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) ...[header!, const SizedBox(height: 8)],
        Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min, children: items),
        ),
        if (footer != null) ...[const SizedBox(height: 8), footer!],
      ],
    );
  }
}

/// Menu-style list tile with icon and optional navigation chevron
///
/// Example usage:
/// ```dart
/// AppMenuTile(
///   icon: Icons.settings,
///   title: 'Settings',
///   onTap: () => navigateToSettings(),
/// )
/// ```
class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.iconColor,
    this.iconBackgroundColor,
    this.destructive = false,
  });

  /// Leading icon
  final IconData icon;

  /// Title text
  final String title;

  /// Subtitle text
  final String? subtitle;

  /// Custom trailing widget
  final Widget? trailing;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Whether to show navigation chevron
  final bool showChevron;

  /// Custom icon color
  final Color? iconColor;

  /// Background color for icon container
  final Color? iconBackgroundColor;

  /// Whether this is a destructive action (red styling)
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    Color effectiveIconColor;
    Color effectiveIconBgColor;
    Color textColor;

    if (destructive) {
      effectiveIconColor = AppColors.error;
      effectiveIconBgColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
    } else {
      effectiveIconColor = iconColor ?? primaryColor;
      effectiveIconBgColor =
          iconBackgroundColor ?? primaryColor.withOpacity(0.1);
      textColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    }

    return AppListTile(
      title: title,
      subtitle: subtitle,
      titleStyle: AppTextStyles.bodyLarge.copyWith(color: textColor),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: effectiveIconBgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(icon, size: 20, color: effectiveIconColor),
      ),
      trailing:
          trailing ??
          (showChevron
              ? Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                )
              : null),
      onTap: onTap,
    );
  }
}
