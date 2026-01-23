// lib/widgets/app_dialog.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Shows a customized dialog following the design system.
///
/// Example usage:
/// ```dart
/// showAppDialog(
///   context: context,
///   builder: (context) => AppDialogContent(
///     title: 'Dialog Title',
///     content: Text('Dialog content here'),
///     actions: [
///       AppDialogAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
///       AppDialogAction(label: 'Confirm', onPressed: () => confirm(), isPrimary: true),
///     ],
///   ),
/// );
/// ```
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black.withOpacity(isDark ? 0.7 : 0.5),
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    builder: builder,
  );
}

/// Shows an alert dialog with title, message, and single action.
///
/// Example usage:
/// ```dart
/// await showAppAlertDialog(
///   context: context,
///   title: 'Error',
///   message: 'Something went wrong. Please try again.',
///   actionLabel: 'OK',
/// );
/// ```
Future<void> showAppAlertDialog({
  required BuildContext context,
  required String title,
  String? message,
  String actionLabel = 'OK',
  IconData? icon,
  Color? iconColor,
  bool barrierDismissible = true,
}) {
  return showAppDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AppAlertDialog(
      title: title,
      message: message,
      actionLabel: actionLabel,
      icon: icon,
      iconColor: iconColor,
    ),
  );
}

/// Shows a confirmation dialog with confirm and cancel actions.
///
/// Returns `true` if confirmed, `false` if cancelled, `null` if dismissed.
///
/// Example usage:
/// ```dart
/// final confirmed = await showAppConfirmDialog(
///   context: context,
///   title: 'Delete Workout?',
///   message: 'This action cannot be undone.',
///   confirmLabel: 'Delete',
///   isDestructive: true,
/// );
///
/// if (confirmed == true) {
///   deleteWorkout();
/// }
/// ```
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  IconData? icon,
  bool barrierDismissible = true,
}) {
  return showAppDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      icon: icon,
    ),
  );
}

/// Shows an input dialog with text field.
///
/// Returns the entered text, or `null` if cancelled.
///
/// Example usage:
/// ```dart
/// final name = await showAppInputDialog(
///   context: context,
///   title: 'Rename Workout',
///   hintText: 'Enter new name',
///   initialValue: workout.name,
///   confirmLabel: 'Save',
/// );
///
/// if (name != null) {
///   renameWorkout(name);
/// }
/// ```
Future<String?> showAppInputDialog({
  required BuildContext context,
  required String title,
  String? message,
  String? hintText,
  String? initialValue,
  String confirmLabel = 'Save',
  String cancelLabel = 'Cancel',
  TextInputType keyboardType = TextInputType.text,
  int? maxLength,
  String? Function(String?)? validator,
  bool barrierDismissible = true,
}) {
  return showAppDialog<String>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AppInputDialog(
      title: title,
      message: message,
      hintText: hintText,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
    ),
  );
}

/// Shows a selection dialog with list of options.
///
/// Returns the selected value, or `null` if cancelled.
///
/// Example usage:
/// ```dart
/// final sortBy = await showAppSelectionDialog<String>(
///   context: context,
///   title: 'Sort By',
///   options: [
///     AppSelectionOption(value: 'name', label: 'Name'),
///     AppSelectionOption(value: 'date', label: 'Date'),
///     AppSelectionOption(value: 'duration', label: 'Duration'),
///   ],
///   selectedValue: currentSort,
/// );
/// ```
Future<T?> showAppSelectionDialog<T>({
  required BuildContext context,
  required String title,
  required List<AppSelectionOption<T>> options,
  T? selectedValue,
  bool barrierDismissible = true,
}) {
  return showAppDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AppSelectionDialog<T>(
      title: title,
      options: options,
      selectedValue: selectedValue,
    ),
  );
}

/// Base dialog container with consistent styling.
class AppDialogContainer extends StatelessWidget {
  const AppDialogContainer({
    super.key,
    required this.child,
    this.width,
    this.maxWidth = 400,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  /// Dialog content
  final Widget child;

  /// Fixed width
  final double? width;

  /// Maximum width
  final double maxWidth;

  /// Custom padding
  final EdgeInsets? padding;

  /// Background color
  final Color? backgroundColor;

  /// Border radius
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing5,
        vertical: AppTheme.spacing6,
      ),
      child: Container(
        width: width,
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding ?? const EdgeInsets.all(AppTheme.spacing5),
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Standard dialog content with title, content, and actions.
class AppDialogContent extends StatelessWidget {
  const AppDialogContent({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.titleWidget,
    this.content,
    this.contentWidget,
    this.actions = const [],
    this.actionsAlignment = MainAxisAlignment.end,
    this.actionsDirection = Axis.horizontal,
  });

  /// Optional icon at the top
  final IconData? icon;

  /// Icon color
  final Color? iconColor;

  /// Icon background color
  final Color? iconBackgroundColor;

  /// Title text
  final String title;

  /// Custom title widget
  final Widget? titleWidget;

  /// Content text
  final String? content;

  /// Custom content widget
  final Widget? contentWidget;

  /// Action buttons
  final List<Widget> actions;

  /// Alignment of actions
  final MainAxisAlignment actionsAlignment;

  /// Direction of actions layout
  final Axis actionsDirection;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveIconColor =
        iconColor ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final effectiveIconBgColor =
        iconBackgroundColor ?? effectiveIconColor.withOpacity(0.1);

    return AppDialogContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          if (icon != null) ...[
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: effectiveIconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: effectiveIconColor),
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
          ],

          // Title
          titleWidget ??
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
                textAlign: icon != null ? TextAlign.center : TextAlign.start,
              ),

          // Content
          if (content != null || contentWidget != null) ...[
            const SizedBox(height: AppTheme.spacing2),
            contentWidget ??
                Text(
                  content!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  textAlign: icon != null ? TextAlign.center : TextAlign.start,
                ),
          ],

          // Actions
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing5),
            if (actionsDirection == Axis.horizontal)
              Row(
                mainAxisAlignment: actionsAlignment,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (actionsAlignment == MainAxisAlignment.end &&
                        i == actions.length - 1)
                      Expanded(child: actions[i])
                    else if (actionsAlignment == MainAxisAlignment.spaceBetween)
                      Expanded(child: actions[i])
                    else
                      actions[i],
                    if (i < actions.length - 1)
                      const SizedBox(width: AppTheme.spacing3),
                  ],
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    actions[i],
                    if (i < actions.length - 1)
                      const SizedBox(height: AppTheme.spacing2),
                  ],
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// Dialog action button.
class AppDialogAction extends StatefulWidget {
  const AppDialogAction({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isLoading = false,
    this.expanded = false,
  });

  /// Button label
  final String label;

  /// Callback when pressed
  final VoidCallback? onPressed;

  /// Whether this is the primary action
  final bool isPrimary;

  /// Whether this is a destructive action
  final bool isDestructive;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Whether the button should expand
  final bool expanded;

  @override
  State<AppDialogAction> createState() => _AppDialogActionState();
}

class _AppDialogActionState extends State<AppDialogAction> {
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
      fgColor = widget.isDestructive
          ? AppColors.error
          : (isDark ? AppColors.foregroundDark : AppColors.foregroundLight);
    }

    if (_isPressed) {
      bgColor = bgColor.withOpacity(0.8);
    }

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Center(
        child: widget.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Text(
                widget.label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );

    if (widget.expanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onPressed != null && !widget.isLoading
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onPressed != null && !widget.isLoading
          ? widget.onPressed
          : null,
      child: MouseRegion(
        cursor: widget.onPressed != null && !widget.isLoading
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: button,
      ),
    );
  }
}

/// Simple alert dialog.
class AppAlertDialog extends StatelessWidget {
  const AppAlertDialog({
    super.key,
    required this.title,
    this.message,
    this.actionLabel = 'OK',
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? message;
  final String actionLabel;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return AppDialogContent(
      icon: icon,
      iconColor: iconColor,
      title: title,
      content: message,
      actionsDirection: Axis.vertical,
      actions: [
        AppDialogAction(
          label: actionLabel,
          onPressed: () => Navigator.of(context).pop(),
          isPrimary: true,
          expanded: true,
        ),
      ],
    );
  }
}

/// Confirmation dialog with two actions.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
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
    return AppDialogContent(
      icon: icon,
      iconColor: isDestructive ? AppColors.error : null,
      iconBackgroundColor: isDestructive
          ? AppColors.error.withOpacity(0.1)
          : null,
      title: title,
      content: message,
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Expanded(
          child: AppDialogAction(
            label: cancelLabel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        const SizedBox(width: AppTheme.spacing3),
        Expanded(
          child: AppDialogAction(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
            isPrimary: true,
            isDestructive: isDestructive,
          ),
        ),
      ],
    );
  }
}

/// Input dialog with text field.
class AppInputDialog extends StatefulWidget {
  const AppInputDialog({
    super.key,
    required this.title,
    this.message,
    this.hintText,
    this.initialValue,
    this.confirmLabel = 'Save',
    this.cancelLabel = 'Cancel',
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.validator,
  });

  final String title;
  final String? message;
  final String? hintText;
  final String? initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;

  @override
  State<AppInputDialog> createState() => _AppInputDialogState();
}

class _AppInputDialogState extends State<AppInputDialog> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.validator != null) {
      final error = widget.validator!(_controller.text);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppDialogContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            widget.title,
            style: AppTextStyles.headlineSmall.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
          ),

          // Message
          if (widget.message != null) ...[
            const SizedBox(height: AppTheme.spacing2),
            Text(
              widget.message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
          ],

          // Text field
          const SizedBox(height: AppTheme.spacing4),
          TextField(
            controller: _controller,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTextStyles.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              errorText: _error,
              filled: true,
              fillColor: isDark ? AppColors.inputDark : AppColors.inputLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing4,
                vertical: AppTheme.spacing3,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(
                  color: isDark ? AppColors.ringDark : AppColors.ringLight,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
          ),

          // Actions
          const SizedBox(height: AppTheme.spacing5),
          Row(
            children: [
              Expanded(
                child: AppDialogAction(
                  label: widget.cancelLabel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppTheme.spacing3),
              Expanded(
                child: AppDialogAction(
                  label: widget.confirmLabel,
                  onPressed: _submit,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Selection option for selection dialog.
class AppSelectionOption<T> {
  const AppSelectionOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  /// Value of the option
  final T value;

  /// Display label
  final String label;

  /// Optional subtitle
  final String? subtitle;

  /// Optional leading icon
  final IconData? icon;
}

/// Selection dialog with list of options.
class AppSelectionDialog<T> extends StatelessWidget {
  const AppSelectionDialog({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
  });

  final String title;
  final List<AppSelectionOption<T>> options;
  final T? selectedValue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    return AppDialogContainer(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing5),
            child: Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),

          // Options
          ...options.map((option) {
            final isSelected = option.value == selectedValue;

            return _SelectionOptionTile(
              option: option,
              isSelected: isSelected,
              primaryColor: primaryColor,
              isDark: isDark,
              onTap: () => Navigator.of(context).pop(option.value),
            );
          }),
        ],
      ),
    );
  }
}

class _SelectionOptionTile<T> extends StatefulWidget {
  const _SelectionOptionTile({
    required this.option,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  final AppSelectionOption<T> option;
  final bool isSelected;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_SelectionOptionTile<T>> createState() =>
      _SelectionOptionTileState<T>();
}

class _SelectionOptionTileState<T> extends State<_SelectionOptionTile<T>> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing5,
          vertical: AppTheme.spacing3,
        ),
        decoration: BoxDecoration(
          color: _isPressed
              ? (widget.isDark
                    ? AppColors.secondaryDark
                    : AppColors.secondaryLight)
              : (widget.isSelected
                    ? widget.primaryColor.withOpacity(0.1)
                    : Colors.transparent),
        ),
        child: Row(
          children: [
            if (widget.option.icon != null) ...[
              Icon(
                widget.option.icon,
                size: 24,
                color: widget.isSelected
                    ? widget.primaryColor
                    : (widget.isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight),
              ),
              const SizedBox(width: AppTheme.spacing3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.option.label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: widget.isSelected
                          ? widget.primaryColor
                          : (widget.isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight),
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (widget.option.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.option.subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: widget.isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.isSelected)
              Icon(Icons.check, size: 20, color: widget.primaryColor),
          ],
        ),
      ),
    );
  }
}

/// Loading dialog to display during async operations.
///
/// Example usage:
/// ```dart
/// showAppLoadingDialog(
///   context: context,
///   message: 'Saving workout...',
/// );
///
/// await saveWorkout();
///
/// Navigator.of(context).pop(); // Dismiss loading dialog
/// ```
Future<void> showAppLoadingDialog({
  required BuildContext context,
  String? message,
}) {
  return showAppDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AppLoadingDialog(message: message),
  );
}

/// Loading dialog content.
class AppLoadingDialog extends StatelessWidget {
  const AppLoadingDialog({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppDialogContainer(
      maxWidth: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacing4),
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
        ],
      ),
    );
  }
}
