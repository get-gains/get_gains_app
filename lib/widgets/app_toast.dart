// lib/widgets/app_toast.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Toast variant types
enum AppToastVariant {
  /// Neutral information
  info,

  /// Success message
  success,

  /// Warning message
  warning,

  /// Error message
  error,
}

/// Toast position on screen
enum AppToastPosition {
  /// Top of screen
  top,

  /// Bottom of screen
  bottom,
}

/// Configuration for toast appearance and behavior
class AppToastConfig {
  const AppToastConfig({
    this.duration = const Duration(seconds: 3),
    this.position = AppToastPosition.top,
    this.showIcon = true,
    this.dismissible = true,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  /// How long the toast is visible
  final Duration duration;

  /// Where the toast appears
  final AppToastPosition position;

  /// Whether to show the variant icon
  final bool showIcon;

  /// Whether user can dismiss by swiping
  final bool dismissible;

  /// Margin around the toast
  final EdgeInsets margin;

  /// Default configuration
  static const AppToastConfig defaults = AppToastConfig();
}

/// Toast data model
class _ToastData {
  _ToastData({
    required this.message,
    required this.variant,
    this.title,
    this.action,
    this.actionLabel,
    this.config = AppToastConfig.defaults,
  });

  final String message;
  final AppToastVariant variant;
  final String? title;
  final VoidCallback? action;
  final String? actionLabel;
  final AppToastConfig config;
}

/// Global toast manager for showing toasts anywhere in the app.
///
/// Setup in your main app widget:
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     return AppToastOverlay(child: child!);
///   },
/// )
/// ```
///
/// Then show toasts from anywhere:
/// ```dart
/// AppToast.show(context, message: 'Changes saved!', variant: AppToastVariant.success);
/// AppToast.success(context, 'Workout completed!');
/// AppToast.error(context, 'Failed to save changes');
/// ```
class AppToast {
  AppToast._();

  static final List<_ToastEntry> _toasts = [];
  static _AppToastOverlayState? _overlayState;

  /// Register the overlay state (called automatically by AppToastOverlay)
  static void _registerOverlay(_AppToastOverlayState state) {
    _overlayState = state;
  }

  /// Unregister the overlay state
  static void _unregisterOverlay(_AppToastOverlayState state) {
    if (_overlayState == state) {
      _overlayState = null;
    }
  }

  /// Show a toast with full customization
  static void show(
    BuildContext context, {
    required String message,
    AppToastVariant variant = AppToastVariant.info,
    String? title,
    VoidCallback? action,
    String? actionLabel,
    AppToastConfig config = AppToastConfig.defaults,
  }) {
    final data = _ToastData(
      message: message,
      variant: variant,
      title: title,
      action: action,
      actionLabel: actionLabel,
      config: config,
    );

    _overlayState?._showToast(data);
  }

  /// Show a success toast
  static void success(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? action,
    String? actionLabel,
    AppToastConfig config = AppToastConfig.defaults,
  }) {
    show(
      context,
      message: message,
      variant: AppToastVariant.success,
      title: title,
      action: action,
      actionLabel: actionLabel,
      config: config,
    );
  }

  /// Show an error toast
  static void error(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? action,
    String? actionLabel,
    AppToastConfig config = AppToastConfig.defaults,
  }) {
    show(
      context,
      message: message,
      variant: AppToastVariant.error,
      title: title,
      action: action,
      actionLabel: actionLabel,
      config: config,
    );
  }

  /// Show a warning toast
  static void warning(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? action,
    String? actionLabel,
    AppToastConfig config = AppToastConfig.defaults,
  }) {
    show(
      context,
      message: message,
      variant: AppToastVariant.warning,
      title: title,
      action: action,
      actionLabel: actionLabel,
      config: config,
    );
  }

  /// Show an info toast
  static void info(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? action,
    String? actionLabel,
    AppToastConfig config = AppToastConfig.defaults,
  }) {
    show(
      context,
      message: message,
      variant: AppToastVariant.info,
      title: title,
      action: action,
      actionLabel: actionLabel,
      config: config,
    );
  }

  /// Dismiss all visible toasts
  static void dismissAll() {
    _overlayState?._dismissAll();
  }
}

/// Internal toast entry with animation controller
class _ToastEntry {
  _ToastEntry({required this.data, required this.controller, required this.id});

  final _ToastData data;
  final AnimationController controller;
  final int id;
  Timer? dismissTimer;
}

/// Overlay widget that manages toast display.
///
/// Wrap your app with this widget to enable toasts:
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     return AppToastOverlay(child: child!);
///   },
/// )
/// ```
class AppToastOverlay extends StatefulWidget {
  const AppToastOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<AppToastOverlay>
    with TickerProviderStateMixin {
  final List<_ToastEntry> _entries = [];
  int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    AppToast._registerOverlay(this);
  }

  @override
  void dispose() {
    AppToast._unregisterOverlay(this);
    for (final entry in _entries) {
      entry.dismissTimer?.cancel();
      entry.controller.dispose();
    }
    super.dispose();
  }

  void _showToast(_ToastData data) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    final entry = _ToastEntry(
      data: data,
      controller: controller,
      id: _idCounter++,
    );

    setState(() {
      _entries.add(entry);
    });

    controller.forward();

    // Auto-dismiss timer
    entry.dismissTimer = Timer(data.config.duration, () {
      _dismissToast(entry);
    });
  }

  void _dismissToast(_ToastEntry entry) {
    entry.dismissTimer?.cancel();
    entry.controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _entries.remove(entry);
        });
        entry.controller.dispose();
      }
    });
  }

  void _dismissAll() {
    for (final entry in List.from(_entries)) {
      _dismissToast(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          widget.child,
          // Bottom toasts
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _entries
                  .where(
                    (e) => e.data.config.position == AppToastPosition.bottom,
                  )
                  .map((entry) => _buildToastWidget(entry))
                  .toList(),
            ),
          ),
          // Top toasts
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).padding.top + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _entries
                  .where((e) => e.data.config.position == AppToastPosition.top)
                  .map((entry) => _buildToastWidget(entry))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToastWidget(_ToastEntry entry) {
    final animation = CurvedAnimation(
      parent: entry.controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final isTop = entry.data.config.position == AppToastPosition.top;
    final slideOffset = isTop ? const Offset(0, -1) : const Offset(0, 1);

    Widget toast = SlideTransition(
      position: Tween<Offset>(
        begin: slideOffset,
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: entry.data.config.margin,
          child: _AppToastWidget(
            data: entry.data,
            onDismiss: () => _dismissToast(entry),
          ),
        ),
      ),
    );

    if (entry.data.config.dismissible) {
      toast = Dismissible(
        key: ValueKey(entry.id),
        direction: isTop ? DismissDirection.up : DismissDirection.down,
        onDismissed: (_) => _dismissToast(entry),
        child: toast,
      );
    }

    return toast;
  }
}

/// Internal toast widget
class _AppToastWidget extends StatelessWidget {
  const _AppToastWidget({required this.data, this.onDismiss});

  final _ToastData data;
  final VoidCallback? onDismiss;

  Color _getBackgroundColor(bool isDark) {
    switch (data.variant) {
      case AppToastVariant.success:
        return isDark ? AppColors.successMuted : AppColors.successLight;
      case AppToastVariant.error:
        return isDark ? AppColors.errorMuted : AppColors.errorLight;
      case AppToastVariant.warning:
        return isDark ? AppColors.warningMuted : AppColors.warningLight;
      case AppToastVariant.info:
        return isDark ? AppColors.surface2Dark : AppColors.surface1Light;
    }
  }

  Color _getIconColor(bool isDark) {
    switch (data.variant) {
      case AppToastVariant.success:
        return AppColors.success;
      case AppToastVariant.error:
        return AppColors.error;
      case AppToastVariant.warning:
        return AppColors.warning;
      case AppToastVariant.info:
        return isDark ? AppColors.info : AppColors.infoMuted;
    }
  }

  Color _getBorderColor(bool isDark) {
    switch (data.variant) {
      case AppToastVariant.success:
        return AppColors.success.withOpacity(0.3);
      case AppToastVariant.error:
        return AppColors.error.withOpacity(0.3);
      case AppToastVariant.warning:
        return AppColors.warning.withOpacity(0.3);
      case AppToastVariant.info:
        return isDark ? AppColors.borderDark : AppColors.borderLight;
    }
  }

  IconData _getIcon() {
    switch (data.variant) {
      case AppToastVariant.success:
        return Icons.check_circle_rounded;
      case AppToastVariant.error:
        return Icons.error_rounded;
      case AppToastVariant.warning:
        return Icons.warning_rounded;
      case AppToastVariant.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark
        ? AppColors.foregroundDark
        : AppColors.foregroundLight;
    final mutedTextColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: _getBorderColor(isDark), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            if (data.config.showIcon) ...[
              Icon(_getIcon(), color: _getIconColor(isDark), size: 20),
              const SizedBox(width: 12),
            ],

            // Content
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data.title != null)
                    Text(
                      data.title!,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: textColor,
                      ),
                    ),
                  Text(
                    data.message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: data.title != null ? mutedTextColor : textColor,
                    ),
                  ),
                ],
              ),
            ),

            // Action button
            if (data.action != null && data.actionLabel != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  data.action?.call();
                  onDismiss?.call();
                },
                child: Text(
                  data.actionLabel!,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: _getIconColor(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standalone toast widget for custom positioning.
///
/// Use this when you need a toast-styled widget in a specific location
/// rather than using the overlay system.
///
/// ```dart
/// AppToastWidget(
///   message: 'Item added to cart',
///   variant: AppToastVariant.success,
/// )
/// ```
class AppToastWidget extends StatelessWidget {
  const AppToastWidget({
    super.key,
    required this.message,
    this.variant = AppToastVariant.info,
    this.title,
    this.showIcon = true,
    this.action,
    this.actionLabel,
    this.onDismiss,
  });

  final String message;
  final AppToastVariant variant;
  final String? title;
  final bool showIcon;
  final VoidCallback? action;
  final String? actionLabel;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return _AppToastWidget(
      data: _ToastData(
        message: message,
        variant: variant,
        title: title,
        action: action,
        actionLabel: actionLabel,
        config: AppToastConfig(showIcon: showIcon),
      ),
      onDismiss: onDismiss,
    );
  }
}
