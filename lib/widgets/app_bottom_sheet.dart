// lib/widgets/app_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Shows a customized bottom sheet following the design system.
///
/// Example usage:
/// ```dart
/// showAppBottomSheet(
///   context: context,
///   builder: (context) => Column(
///     children: [
///       Text('Bottom Sheet Content'),
///       AppButton(label: 'Action', onPressed: () {}),
///     ],
///   ),
/// );
/// ```
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  double? maxHeight,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor:
        backgroundColor ?? (isDark ? AppColors.cardDark : AppColors.cardLight),
    shape:
        shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
    constraints: maxHeight != null
        ? BoxConstraints(maxHeight: maxHeight)
        : BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
    builder: (context) {
      return AppBottomSheetContent(
        showDragHandle: showDragHandle,
        child: builder(context),
      );
    },
  );
}

/// Shows a confirmation bottom sheet with title, message, and actions.
///
/// Example usage:
/// ```dart
/// final confirmed = await showAppConfirmSheet(
///   context: context,
///   title: 'Delete Workout?',
///   message: 'This action cannot be undone.',
///   confirmLabel: 'Delete',
///   isDestructive: true,
/// );
/// if (confirmed == true) {
///   deleteWorkout();
/// }
/// ```
Future<bool?> showAppConfirmSheet({
  required BuildContext context,
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  IconData? icon,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    builder: (context) => AppConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      icon: icon,
    ),
  );
}

/// Shows an action sheet with a list of options.
///
/// Example usage:
/// ```dart
/// final result = await showAppActionSheet<String>(
///   context: context,
///   title: 'Sort By',
///   actions: [
///     AppActionSheetItem(
///       label: 'Name',
///       value: 'name',
///       icon: Icons.sort_by_alpha,
///     ),
///     AppActionSheetItem(
///       label: 'Date',
///       value: 'date',
///       icon: Icons.calendar_today,
///     ),
///   ],
/// );
/// ```
Future<T?> showAppActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<AppActionSheetItem<T>> actions,
  bool showCancelButton = true,
  String cancelLabel = 'Cancel',
}) {
  return showAppBottomSheet<T>(
    context: context,
    builder: (context) => AppActionSheet<T>(
      title: title,
      message: message,
      actions: actions,
      showCancelButton: showCancelButton,
      cancelLabel: cancelLabel,
    ),
  );
}

/// Content wrapper for bottom sheets with drag handle.
class AppBottomSheetContent extends StatelessWidget {
  const AppBottomSheetContent({
    super.key,
    required this.child,
    this.showDragHandle = true,
    this.padding,
  });

  final Widget child;
  final bool showDragHandle;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle) ...[
          const SizedBox(height: AppTheme.spacing3),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.gray600 : AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppTheme.spacing3),
        ],
        Flexible(
          child: Padding(
            padding: padding ?? AppTheme.screenPadding,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// A bottom sheet header with title and optional close button.
class AppBottomSheetHeader extends StatelessWidget {
  const AppBottomSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showCloseButton = true,
    this.onClose,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
        if (showCloseButton && trailing == null)
          IconButton(
            onPressed: onClose ?? () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.secondaryDark
                  : AppColors.secondaryLight,
              shape: const CircleBorder(),
            ),
          ),
      ],
    );
  }
}

/// Confirmation sheet content.
class AppConfirmSheet extends StatelessWidget {
  const AppConfirmSheet({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        if (icon != null) ...[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppColors.error.withOpacity(0.15)
                  : (isDark
                        ? AppColors.primaryDark.withOpacity(0.15)
                        : AppColors.primaryLight.withOpacity(0.15)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: isDestructive
                  ? AppColors.error
                  : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: AppTheme.spacing5),
        ],

        // Title
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
          textAlign: TextAlign.center,
        ),

        // Message
        if (message != null) ...[
          const SizedBox(height: AppTheme.spacing2),
          Text(
            message!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: AppTheme.spacing6),

        // Actions
        Row(
          children: [
            Expanded(
              child: _SheetButton(
                label: cancelLabel,
                onPressed: () => Navigator.of(context).pop(false),
                isDestructive: false,
                isPrimary: false,
              ),
            ),
            const SizedBox(width: AppTheme.spacing3),
            Expanded(
              child: _SheetButton(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
                isDestructive: isDestructive,
                isPrimary: true,
              ),
            ),
          ],
        ),

        // Bottom safe area padding
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

/// Action sheet item definition.
class AppActionSheetItem<T> {
  const AppActionSheetItem({
    required this.label,
    required this.value,
    this.icon,
    this.subtitle,
    this.isDestructive = false,
    this.isSelected = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final String? subtitle;
  final bool isDestructive;
  final bool isSelected;
}

/// Action sheet content with list of options.
class AppActionSheet<T> extends StatelessWidget {
  const AppActionSheet({
    super.key,
    this.title,
    this.message,
    required this.actions,
    this.showCancelButton = true,
    this.cancelLabel = 'Cancel',
  });

  final String? title;
  final String? message;
  final List<AppActionSheetItem<T>> actions;
  final bool showCancelButton;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        if (title != null || message != null) ...[
          if (title != null)
            Text(
              title!,
              style: AppTextStyles.titleLarge.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
              textAlign: TextAlign.center,
            ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppTheme.spacing4),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ],

        // Actions
        ...actions.map(
          (action) => _ActionSheetTile<T>(
            action: action,
            onTap: () => Navigator.of(context).pop(action.value),
          ),
        ),

        // Cancel button
        if (showCancelButton) ...[
          const SizedBox(height: AppTheme.spacing2),
          _SheetButton(
            label: cancelLabel,
            onPressed: () => Navigator.of(context).pop(),
            isDestructive: false,
            isPrimary: false,
          ),
        ],

        // Bottom safe area padding
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

/// Individual action tile in action sheet.
class _ActionSheetTile<T> extends StatefulWidget {
  const _ActionSheetTile({required this.action, required this.onTap});

  final AppActionSheetItem<T> action;
  final VoidCallback onTap;

  @override
  State<_ActionSheetTile<T>> createState() => _ActionSheetTileState<T>();
}

class _ActionSheetTileState<T> extends State<_ActionSheetTile<T>> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final action = widget.action;

    Color textColor;
    if (action.isDestructive) {
      textColor = AppColors.error;
    } else if (action.isSelected) {
      textColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    } else {
      textColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing4,
          vertical: AppTheme.spacing3,
        ),
        decoration: BoxDecoration(
          color: _isPressed
              ? (isDark ? AppColors.secondaryDark : AppColors.secondaryLight)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            if (action.icon != null) ...[
              Icon(action.icon, size: 24, color: textColor),
              const SizedBox(width: AppTheme.spacing3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: textColor,
                      fontWeight: action.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (action.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (action.isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
          ],
        ),
      ),
    );
  }
}

/// Button used in bottom sheets.
class _SheetButton extends StatefulWidget {
  const _SheetButton({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final bool isPrimary;

  @override
  State<_SheetButton> createState() => _SheetButtonState();
}

class _SheetButtonState extends State<_SheetButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;

    if (widget.isPrimary) {
      if (widget.isDestructive) {
        bgColor = AppColors.error;
        fgColor = AppColors.white;
      } else {
        bgColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
        fgColor = AppColors.white;
      }
    } else {
      bgColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
      fgColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    }

    if (_isPressed) {
      bgColor = bgColor.withOpacity(0.8);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: AppTextStyles.labelLarge.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
