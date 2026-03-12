// lib/widgets/app_snackbar.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Snackbar variant types
enum AppSnackbarVariant {
  /// Neutral information
  info,

  /// Success message
  success,

  /// Warning message
  warning,

  /// Error message
  error,
}

/// Configuration for snackbar appearance and behavior
class AppSnackbarConfig {
  const AppSnackbarConfig({
    this.duration = const Duration(seconds: 4),
    this.behavior = SnackBarBehavior.floating,
    this.showIcon = true,
    this.dismissible = true,
    this.margin = const EdgeInsets.all(16),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.showFromTop = true,
  });

  /// How long the snackbar is visible
  final Duration duration;

  /// Snackbar behavior (floating or fixed)
  final SnackBarBehavior behavior;

  /// Whether to show the variant icon
  final bool showIcon;

  /// Whether user can dismiss
  final bool dismissible;

  /// Margin around the snackbar (for floating behavior)
  final EdgeInsets margin;

  /// Internal padding
  final EdgeInsets padding;

  /// Whether to show from top (true) or bottom (false)
  final bool showFromTop;

  /// Default configuration
  static const AppSnackbarConfig defaults = AppSnackbarConfig();
}

/// Styled snackbar wrapper with consistent theming.
///
/// Uses the app's design system colors and typography.
///
/// ## Usage
///
/// Show a snackbar from anywhere with a ScaffoldMessenger:
/// ```dart
/// AppSnackbar.show(context, message: 'Item deleted');
/// AppSnackbar.success(context, 'Saved successfully!');
/// AppSnackbar.error(context, 'Failed to save');
/// ```
///
/// With action:
/// ```dart
/// AppSnackbar.show(
///   context,
///   message: 'Item deleted',
///   actionLabel: 'Undo',
///   onAction: () => undoDelete(),
/// );
/// ```
class AppSnackbar {
  AppSnackbar._();

  /// Show a snackbar with full customization
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarVariant variant = AppSnackbarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    AppSnackbarConfig config = AppSnackbarConfig.defaults,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get colors based on variant
    final (bgColor, iconColor, icon) = _getVariantStyle(variant, isDark);

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (config.showIcon) ...[
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: config.behavior,
      duration: config.duration,
      margin: config.behavior == SnackBarBehavior.floating
          ? config.margin
          : null,
      padding: config.padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      elevation: 4,
      dismissDirection: config.dismissible
          ? DismissDirection.horizontal
          : DismissDirection.none,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: iconColor,
              onPressed: () {
                onAction?.call();
              },
            )
          : null,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Show a success snackbar
  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    AppSnackbarConfig config = AppSnackbarConfig.defaults,
  }) {
    show(
      context,
      message: message,
      variant: AppSnackbarVariant.success,
      actionLabel: actionLabel,
      onAction: onAction,
      config: config,
    );
  }

  /// Show an error snackbar
  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    AppSnackbarConfig config = AppSnackbarConfig.defaults,
  }) {
    show(
      context,
      message: message,
      variant: AppSnackbarVariant.error,
      actionLabel: actionLabel,
      onAction: onAction,
      config: config,
    );
  }

  /// Show a warning snackbar
  static void warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    AppSnackbarConfig config = AppSnackbarConfig.defaults,
  }) {
    show(
      context,
      message: message,
      variant: AppSnackbarVariant.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      config: config,
    );
  }

  /// Show an info snackbar
  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    AppSnackbarConfig config = AppSnackbarConfig.defaults,
  }) {
    show(
      context,
      message: message,
      variant: AppSnackbarVariant.info,
      actionLabel: actionLabel,
      onAction: onAction,
      config: config,
    );
  }

  /// Hide the current snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Hide all snackbars
  static void hideAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  /// Get styling based on variant
  static (Color, Color, IconData) _getVariantStyle(
    AppSnackbarVariant variant,
    bool isDark,
  ) {
    switch (variant) {
      case AppSnackbarVariant.info:
        return (
          isDark ? AppColors.surface3Dark : AppColors.gray800,
          AppColors.info,
          Icons.info_outline_rounded,
        );
      case AppSnackbarVariant.success:
        return (
          isDark ? const Color(0xFF1B4332) : const Color(0xFF166534),
          AppColors.success,
          Icons.check_circle_outline_rounded,
        );
      case AppSnackbarVariant.warning:
        return (
          isDark ? const Color(0xFF78350F) : AppColors.warningMuted,
          AppColors.warning,
          Icons.warning_amber_rounded,
        );
      case AppSnackbarVariant.error:
        return (
          isDark ? const Color(0xFF7F1D1D) : const Color(0xFFB91C1C),
          AppColors.error,
          Icons.error_outline_rounded,
        );
    }
  }
}

/// A custom snackbar widget for more control over appearance.
///
/// Use this when you need a snackbar as a regular widget
/// (e.g., in custom overlay implementations).
class AppSnackbarWidget extends StatelessWidget {
  const AppSnackbarWidget({
    super.key,
    required this.message,
    this.variant = AppSnackbarVariant.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.showIcon = true,
  });

  final String message;
  final AppSnackbarVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bgColor, iconColor, icon) = AppSnackbar._getVariantStyle(
      variant,
      isDark,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: iconColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.white.withOpacity(0.7),
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
