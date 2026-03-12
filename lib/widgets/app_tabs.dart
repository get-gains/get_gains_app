// lib/widgets/app_tabs.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_text_styles.dart';

/// Tab bar style variants
enum AppTabVariant {
  /// Text with underline indicator
  underline,

  /// Filled background on selected
  filled,

  /// Pill/capsule style buttons
  segmented,

  /// Border around tabs
  outlined,
}

/// Tab bar size options
enum AppTabSize {
  /// Compact size (36px height)
  sm,

  /// Default size (44px height)
  md,

  /// Large size (52px height)
  lg,
}

/// Indicator style for tabs
enum AppTabIndicator {
  /// Line below text
  underline,

  /// Rounded rectangle behind text
  pill,

  /// Small dot below text
  dot,
}

/// A customizable tab bar component
///
/// Example:
/// ```dart
/// AppTabs(
///   tabs: ['All', 'Strength', 'Cardio', 'Flexibility'],
///   selectedIndex: _selectedIndex,
///   onChanged: (index) => setState(() => _selectedIndex = index),
/// )
/// ```
class AppTabs extends StatelessWidget {
  const AppTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.variant = AppTabVariant.underline,
    this.size = AppTabSize.md,
    this.indicator = AppTabIndicator.underline,
    this.isScrollable = false,
    this.showDivider = true,
    this.enabled = true,
    this.padding,
  });

  /// List of tab labels
  final List<String> tabs;

  /// Currently selected tab index
  final int selectedIndex;

  /// Called when a tab is selected
  final ValueChanged<int>? onChanged;

  /// Visual variant of the tabs
  final AppTabVariant variant;

  /// Size of the tabs
  final AppTabSize size;

  /// Style of the selection indicator
  final AppTabIndicator indicator;

  /// Whether tabs should scroll horizontally
  final bool isScrollable;

  /// Whether to show a divider below the tabs
  final bool showDivider;

  /// Whether the tabs are interactive
  final bool enabled;

  /// Padding around the tab bar
  final EdgeInsetsGeometry? padding;

  double _getHeight() {
    switch (size) {
      case AppTabSize.sm:
        return 36;
      case AppTabSize.md:
        return 44;
      case AppTabSize.lg:
        return 52;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppTabSize.sm:
        return AppTextStyles.labelSmall;
      case AppTabSize.md:
        return AppTextStyles.labelMedium;
      case AppTabSize.lg:
        return AppTextStyles.labelLarge;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (variant == AppTabVariant.segmented) {
      return _buildSegmentedTabs(context);
    }

    return _buildStandardTabs(context);
  }

  Widget _buildStandardTabs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = _getHeight();
    final textStyle = _getTextStyle();

    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inactiveColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    Widget tabBar = SizedBox(
      height: height,
      child: isScrollable
          ? ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              padding: padding,
              itemBuilder: (context, index) {
                return _buildTab(
                  context,
                  index: index,
                  label: tabs[index],
                  isSelected: index == selectedIndex,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  textStyle: textStyle,
                  height: height,
                );
              },
            )
          : Row(
              children: tabs.asMap().entries.map((entry) {
                return Expanded(
                  child: _buildTab(
                    context,
                    index: entry.key,
                    label: entry.value,
                    isSelected: entry.key == selectedIndex,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    textStyle: textStyle,
                    height: height,
                  ),
                );
              }).toList(),
            ),
    );

    if (showDivider && variant == AppTabVariant.underline) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tabBar,
          Container(height: 1, color: dividerColor),
        ],
      );
    }

    return tabBar;
  }

  Widget _buildTab(
    BuildContext context, {
    required int index,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required TextStyle textStyle,
    required double height,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.surface2Dark : AppColors.surface2Light;

    return GestureDetector(
      onTap: enabled && onChanged != null ? () => onChanged!(index) : null,
      child: AnimatedContainer(
        duration: AppTheme.durationNormal,
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: isScrollable ? AppTheme.spacing4 : AppTheme.spacing2,
        ),
        decoration: BoxDecoration(
          color: variant == AppTabVariant.filled && isSelected
              ? fillColor
              : Colors.transparent,
          border: variant == AppTabVariant.outlined
              ? Border.all(color: isSelected ? activeColor : inactiveColor)
              : null,
          borderRadius:
              variant == AppTabVariant.filled ||
                  variant == AppTabVariant.outlined
              ? AppTheme.borderRadiusSm
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: AppTheme.durationFast,
              style: textStyle.copyWith(
                color: enabled
                    ? (isSelected ? activeColor : inactiveColor)
                    : inactiveColor.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
            if (variant == AppTabVariant.underline) ...[
              const SizedBox(height: 4),
              _buildIndicator(isSelected, activeColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isSelected, Color color) {
    switch (indicator) {
      case AppTabIndicator.underline:
        return AnimatedContainer(
          duration: AppTheme.durationNormal,
          curve: AppTheme.curveDefault,
          height: 2,
          width: isSelected ? 24 : 0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppTheme.borderRadiusFull,
          ),
        );
      case AppTabIndicator.pill:
        return const SizedBox.shrink(); // Handled by background
      case AppTabIndicator.dot:
        return AnimatedContainer(
          duration: AppTheme.durationNormal,
          curve: AppTheme.curveDefault,
          height: 4,
          width: isSelected ? 4 : 0,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    }
  }

  Widget _buildSegmentedTabs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = _getHeight();
    final textStyle = _getTextStyle();

    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final activeForeground = isDark
        ? AppColors.primaryForegroundDark
        : AppColors.primaryForegroundLight;
    final inactiveColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final backgroundColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;

    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTheme.borderRadiusFull,
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final isSelected = entry.key == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: enabled && onChanged != null
                  ? () => onChanged!(entry.key)
                  : null,
              child: AnimatedContainer(
                duration: AppTheme.durationNormal,
                curve: AppTheme.curveDefault,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: AppTheme.borderRadiusFull,
                ),
                alignment: Alignment.center,
                child: AnimatedDefaultTextStyle(
                  duration: AppTheme.durationFast,
                  style: textStyle.copyWith(
                    color: enabled
                        ? (isSelected ? activeForeground : inactiveColor)
                        : inactiveColor.withOpacity(0.5),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Text(entry.value),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Data class for icon tabs
class AppIconTab {
  const AppIconTab({
    required this.icon,
    this.selectedIcon,
    this.label,
    this.badge,
  });

  /// Icon for unselected state
  final IconData icon;

  /// Icon for selected state (optional)
  final IconData? selectedIcon;

  /// Optional text label
  final String? label;

  /// Optional badge text (e.g., notification count)
  final String? badge;
}

/// Tab bar with icon tabs
///
/// Example:
/// ```dart
/// AppIconTabs(
///   tabs: [
///     AppIconTab(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
///     AppIconTab(icon: Icons.search, label: 'Search'),
///     AppIconTab(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
///   ],
///   selectedIndex: _selected,
///   onChanged: (index) => setState(() => _selected = index),
/// )
/// ```
class AppIconTabs extends StatelessWidget {
  const AppIconTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.variant = AppTabVariant.underline,
    this.size = AppTabSize.md,
    this.showLabels = false,
    this.enabled = true,
    this.showDivider = true,
  });

  /// List of icon tab data
  final List<AppIconTab> tabs;

  /// Currently selected tab index
  final int selectedIndex;

  /// Called when a tab is selected
  final ValueChanged<int>? onChanged;

  /// Visual variant
  final AppTabVariant variant;

  /// Size of the tabs
  final AppTabSize size;

  /// Whether to show text labels
  final bool showLabels;

  /// Whether the tabs are interactive
  final bool enabled;

  /// Whether to show divider below
  final bool showDivider;

  double _getHeight() {
    switch (size) {
      case AppTabSize.sm:
        return showLabels ? 48 : 36;
      case AppTabSize.md:
        return showLabels ? 56 : 44;
      case AppTabSize.lg:
        return showLabels ? 64 : 52;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppTabSize.sm:
        return 20;
      case AppTabSize.md:
        return 24;
      case AppTabSize.lg:
        return 28;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = _getHeight();
    final iconSize = _getIconSize();

    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inactiveColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final badgeColor = AppColors.error;

    Widget tabBar = SizedBox(
      height: height,
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == selectedIndex;
          final effectiveIcon = isSelected
              ? (tab.selectedIcon ?? tab.icon)
              : tab.icon;

          return Expanded(
            child: GestureDetector(
              onTap: enabled && onChanged != null
                  ? () => onChanged!(index)
                  : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: AppTheme.durationFast,
                        child: Icon(
                          effectiveIcon,
                          size: iconSize,
                          color: enabled
                              ? (isSelected ? activeColor : inactiveColor)
                              : inactiveColor.withOpacity(0.5),
                        ),
                      ),
                      if (tab.badge != null)
                        _buildBadge(tab.badge!, badgeColor),
                    ],
                  ),
                  if (showLabels && tab.label != null) ...[
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: AppTheme.durationFast,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: enabled
                            ? (isSelected ? activeColor : inactiveColor)
                            : inactiveColor.withOpacity(0.5),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      child: Text(tab.label!),
                    ),
                  ],
                  if (variant == AppTabVariant.underline) ...[
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: AppTheme.durationNormal,
                      curve: AppTheme.curveDefault,
                      height: 2,
                      width: isSelected ? 24 : 0,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: AppTheme.borderRadiusFull,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (showDivider && variant == AppTabVariant.underline) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tabBar,
          Container(height: 1, color: dividerColor),
        ],
      );
    }

    return tabBar;
  }

  Widget _buildBadge(String text, Color color) {
    return Positioned(
      right: -8,
      top: -4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full tab view with content switching
///
/// Combines tab bar with page view for content.
///
/// Example:
/// ```dart
/// AppTabView(
///   tabs: ['Overview', 'Exercises', 'History'],
///   children: [
///     OverviewTab(),
///     ExercisesTab(),
///     HistoryTab(),
///   ],
/// )
/// ```
class AppTabView extends StatefulWidget {
  const AppTabView({
    super.key,
    required this.tabs,
    required this.children,
    this.initialIndex = 0,
    this.variant = AppTabVariant.underline,
    this.size = AppTabSize.md,
    this.isScrollable = false,
    this.keepAlive = false,
    this.physics,
    this.onTabChanged,
    this.tabPadding,
  });

  /// List of tab labels
  final List<String> tabs;

  /// Content widgets for each tab
  final List<Widget> children;

  /// Initial selected tab
  final int initialIndex;

  /// Visual variant of the tabs
  final AppTabVariant variant;

  /// Size of the tabs
  final AppTabSize size;

  /// Whether tabs should scroll horizontally
  final bool isScrollable;

  /// Whether to keep tabs alive when switching
  final bool keepAlive;

  /// Physics for the page view
  final ScrollPhysics? physics;

  /// Called when tab changes
  final ValueChanged<int>? onTabChanged;

  /// Padding around tab bar
  final EdgeInsetsGeometry? tabPadding;

  @override
  State<AppTabView> createState() => _AppTabViewState();
}

class _AppTabViewState extends State<AppTabView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppTheme.durationNormal,
      curve: AppTheme.curveDefault,
    );
    widget.onTabChanged?.call(index);
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    widget.onTabChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              widget.tabPadding ??
              const EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
          child: AppTabs(
            tabs: widget.tabs,
            selectedIndex: _currentIndex,
            onChanged: _onTabChanged,
            variant: widget.variant,
            size: widget.size,
            isScrollable: widget.isScrollable,
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: widget.physics,
            onPageChanged: _onPageChanged,
            itemCount: widget.children.length,
            itemBuilder: (context, index) {
              if (widget.keepAlive) {
                return _KeepAliveWrapper(child: widget.children[index]);
              }
              return widget.children[index];
            },
          ),
        ),
      ],
    );
  }
}

/// Wrapper to keep tab content alive
class _KeepAliveWrapper extends StatefulWidget {
  const _KeepAliveWrapper({required this.child});

  final Widget child;

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
