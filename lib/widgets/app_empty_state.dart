// lib/widgets/app_empty_state.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import 'app_button.dart';

/// Size variants for empty state
enum AppEmptyStateSize {
  /// Compact size for inline/card usage (48px icon)
  sm,

  /// Default size for page sections (64px icon)
  md,

  /// Large size for full page empty states (96px icon)
  lg,
}

/// A customizable empty state component following the design system.
///
/// Used to display helpful messages when there's no content to show,
/// such as empty lists, search results, or initial states.
///
/// Example usage:
/// ```dart
/// // Basic empty state
/// AppEmptyState(
///   icon: Icons.inbox_outlined,
///   title: 'No messages yet',
///   description: 'Your inbox is empty. Start a conversation!',
/// )
///
/// // With action button
/// AppEmptyState(
///   icon: Icons.fitness_center,
///   title: 'No workouts found',
///   description: 'Create your first workout to get started.',
///   actionLabel: 'Create Workout',
///   onAction: () => Navigator.push(...),
/// )
///
/// // Compact size for cards
/// AppEmptyState.compact(
///   icon: Icons.search_off,
///   title: 'No results',
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.size = AppEmptyStateSize.md,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
    this.customIcon,
  });

  /// Compact empty state factory
  const AppEmptyState.compact({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
    this.customIcon,
  }) : size = AppEmptyStateSize.sm;

  /// Large empty state factory for full page states
  const AppEmptyState.fullPage({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
    this.customIcon,
  }) : size = AppEmptyStateSize.lg;

  /// Icon to display (from Icons or custom IconData)
  final IconData icon;

  /// Main title text
  final String title;

  /// Optional description text below the title
  final String? description;

  /// Size variant
  final AppEmptyStateSize size;

  /// Label for primary action button
  final String? actionLabel;

  /// Callback for primary action button
  final VoidCallback? onAction;

  /// Label for secondary action button
  final String? secondaryActionLabel;

  /// Callback for secondary action button
  final VoidCallback? onSecondaryAction;

  /// Custom icon color (defaults to mutedForeground)
  final Color? iconColor;

  /// Custom widget to display instead of icon
  final Widget? customIcon;

  double get _iconSize {
    switch (size) {
      case AppEmptyStateSize.sm:
        return 48;
      case AppEmptyStateSize.md:
        return 64;
      case AppEmptyStateSize.lg:
        return 96;
    }
  }

  double get _iconContainerSize {
    switch (size) {
      case AppEmptyStateSize.sm:
        return 80;
      case AppEmptyStateSize.md:
        return 120;
      case AppEmptyStateSize.lg:
        return 160;
    }
  }

  TextStyle _getTitleStyle(bool isDark) {
    switch (size) {
      case AppEmptyStateSize.sm:
        return AppTextStyles.titleMedium.copyWith(
          color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
        );
      case AppEmptyStateSize.md:
        return AppTextStyles.titleLarge.copyWith(
          color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
        );
      case AppEmptyStateSize.lg:
        return AppTextStyles.headlineSmall.copyWith(
          color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
        );
    }
  }

  TextStyle _getDescriptionStyle(bool isDark) {
    switch (size) {
      case AppEmptyStateSize.sm:
        return AppTextStyles.bodySmall.copyWith(
          color: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        );
      case AppEmptyStateSize.md:
        return AppTextStyles.bodyMedium.copyWith(
          color: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        );
      case AppEmptyStateSize.lg:
        return AppTextStyles.bodyLarge.copyWith(
          color: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        );
    }
  }

  double get _spacing {
    switch (size) {
      case AppEmptyStateSize.sm:
        return AppTheme.spacing3;
      case AppEmptyStateSize.md:
        return AppTheme.spacing4;
      case AppEmptyStateSize.lg:
        return AppTheme.spacing6;
    }
  }

  AppButtonSize get _buttonSize {
    switch (size) {
      case AppEmptyStateSize.sm:
        return AppButtonSize.sm;
      case AppEmptyStateSize.md:
        return AppButtonSize.md;
      case AppEmptyStateSize.lg:
        return AppButtonSize.lg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveIconColor =
        iconColor ??
        (isDark
            ? AppColors.mutedForegroundDark
            : AppColors.mutedForegroundLight);

    final bgColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    return Padding(
      padding: EdgeInsets.all(_spacing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: _iconContainerSize,
            height: _iconContainerSize,
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child:
                  customIcon ??
                  Icon(icon, size: _iconSize, color: effectiveIconColor),
            ),
          ),
          SizedBox(height: _spacing),

          // Title
          Text(
            title,
            style: _getTitleStyle(isDark),
            textAlign: TextAlign.center,
          ),

          // Description
          if (description != null) ...[
            SizedBox(height: size == AppEmptyStateSize.sm ? 4 : 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: size == AppEmptyStateSize.lg ? 320 : 280,
              ),
              child: Text(
                description!,
                style: _getDescriptionStyle(isDark),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Action buttons
          if (actionLabel != null || secondaryActionLabel != null) ...[
            SizedBox(height: _spacing * 1.5),
            _buildActions(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    final hasSecondary = secondaryActionLabel != null;

    if (size == AppEmptyStateSize.sm) {
      // Compact: single row of buttons
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSecondary) ...[
            AppButton.ghost(
              label: secondaryActionLabel!,
              onPressed: onSecondaryAction,
              size: _buttonSize,
            ),
            const SizedBox(width: 8),
          ],
          if (actionLabel != null)
            AppButton.primary(
              label: actionLabel!,
              onPressed: onAction,
              size: _buttonSize,
            ),
        ],
      );
    }

    // Medium/Large: stacked or row based on content
    if (hasSecondary) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (actionLabel != null)
            AppButton.primary(
              label: actionLabel!,
              onPressed: onAction,
              size: _buttonSize,
            ),
          const SizedBox(height: 12),
          AppButton.ghost(
            label: secondaryActionLabel!,
            onPressed: onSecondaryAction,
            size: _buttonSize,
          ),
        ],
      );
    }

    return AppButton.primary(
      label: actionLabel!,
      onPressed: onAction,
      size: _buttonSize,
    );
  }
}

/// A specialized empty state for search results.
///
/// Example usage:
/// ```dart
/// AppSearchEmptyState(
///   query: searchController.text,
///   onClear: () => searchController.clear(),
/// )
/// ```
class AppSearchEmptyState extends StatelessWidget {
  const AppSearchEmptyState({
    super.key,
    required this.query,
    this.onClear,
    this.suggestions,
  });

  /// The search query that returned no results
  final String query;

  /// Callback to clear the search
  final VoidCallback? onClear;

  /// Optional list of search suggestions
  final List<String>? suggestions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppEmptyState(
      icon: Icons.search_off_rounded,
      title: 'No results found',
      description: 'We couldn\'t find anything matching "$query"',
      actionLabel: onClear != null ? 'Clear Search' : null,
      onAction: onClear,
    );
  }
}

/// A specialized empty state for error scenarios.
///
/// Example usage:
/// ```dart
/// AppErrorState(
///   title: 'Something went wrong',
///   description: 'We couldn\'t load your data. Please try again.',
///   onRetry: () => ref.refresh(dataProvider),
/// )
/// ```
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.description,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = Icons.error_outline_rounded,
    this.size = AppEmptyStateSize.md,
  });

  /// Error title
  final String title;

  /// Error description
  final String? description;

  /// Callback for retry action
  final VoidCallback? onRetry;

  /// Label for retry button
  final String retryLabel;

  /// Error icon
  final IconData icon;

  /// Size variant
  final AppEmptyStateSize size;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      description: description,
      size: size,
      iconColor: AppColors.error,
      actionLabel: onRetry != null ? retryLabel : null,
      onAction: onRetry,
    );
  }
}

/// A specialized empty state for offline/connection issues.
///
/// Example usage:
/// ```dart
/// AppOfflineState(
///   onRetry: () => checkConnectivity(),
/// )
/// ```
class AppOfflineState extends StatelessWidget {
  const AppOfflineState({
    super.key,
    this.onRetry,
    this.size = AppEmptyStateSize.md,
  });

  /// Callback for retry action
  final VoidCallback? onRetry;

  /// Size variant
  final AppEmptyStateSize size;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'No connection',
      description: 'Please check your internet connection and try again.',
      size: size,
      iconColor: AppColors.warning,
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }
}
