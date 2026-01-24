// lib/widgets/app_card.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Card variant types
enum AppCardVariant { elevated, outlined, flat, gradient }

/// Card size options
enum AppCardSize { sm, md, lg }

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
  }) : variant = AppCardVariant.elevated,
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
  }) : variant = AppCardVariant.outlined,
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
  }) : variant = AppCardVariant.flat,
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
  }) : variant = AppCardVariant.gradient,
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
            color:
                widget.borderColor ??
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
            color:
                widget.borderColor ??
                (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        );

      case AppCardVariant.flat:
        return BoxDecoration(
          color: _getBackgroundColor(
            isDark,
          ).withOpacity(_isHovered && _isInteractive ? 0.8 : 0.5),
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
