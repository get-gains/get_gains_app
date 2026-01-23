# AppDialog

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Modal dialogs for confirmations, alerts, inputs, and selections. Interrupts user flow for important interactions.

---

## Variants

| Variant | Purpose | Actions |
|---------|---------|---------|
| `alert` | Information only | Single dismiss |
| `confirm` | Yes/No decisions | Two buttons |
| `input` | Text input collection | Confirm/Cancel |
| `selection` | Choice from options | Dynamic based on options |
| `loading` | Processing state | None (auto-dismiss) |

---

## Specifications

### Layout

- **Min width**: 280px
- **Max width**: 400px (or 90% of screen)
- **Padding**: `spacing5` (20px) content
- **Corner radius**: `radiusXl` (16px)
- **Button gap**: `spacing3` (12px)

### Animation

- **Duration**: `durationNormal` (300ms)
- **Curve**: `easeOutCubic`
- **Barrier**: `Colors.black54`

---

## Implementation

```dart
// lib/widgets/app_dialog.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.icon,
    required this.title,
    this.content,
    required this.actions,
    this.alignment = CrossAxisAlignment.center,
  });

  final Widget? icon;
  final String title;
  final Widget? content;
  final List<Widget> actions;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 280,
          maxWidth: screenWidth * 0.9 > 400 ? 400 : screenWidth * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: alignment,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: AppTextStyles.titleLarge,
                textAlign: alignment == CrossAxisAlignment.center 
                    ? TextAlign.center 
                    : TextAlign.start,
              ),
              if (content != null) ...[
                const SizedBox(height: 12),
                DefaultTextStyle(
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                  ),
                  textAlign: alignment == CrossAxisAlignment.center 
                      ? TextAlign.center 
                      : TextAlign.start,
                  child: content!,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: actions.map((action) => Expanded(child: action)).toList()
                  ..insertAll(
                    1,
                    List.generate(
                      actions.length - 1,
                      (_) => const SizedBox(width: 12),
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Helper Functions

### showAppAlertDialog

Single-action informational dialog.

```dart
Future<void> showAppAlertDialog(
  BuildContext context, {
  Widget? icon,
  required String title,
  String? message,
  String buttonText = 'OK',
  VoidCallback? onPressed,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black54,
    transitionDuration: AppTheme.durationNormal,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) => AppDialog(
      icon: icon,
      title: title,
      content: message != null ? Text(message) : null,
      actions: [
        AppButton(
          label: buttonText,
          onPressed: () {
            Navigator.of(context).pop();
            onPressed?.call();
          },
        ),
      ],
    ),
  );
}
```

### showAppConfirmDialog

Two-action confirmation dialog.

```dart
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  Widget? icon,
  required String title,
  String? message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black54,
    transitionDuration: AppTheme.durationNormal,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) => AppDialog(
      icon: icon,
      title: title,
      content: message != null ? Text(message) : null,
      actions: [
        AppButton(
          label: cancelText,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: confirmText,
          variant: destructive ? AppButtonVariant.destructive : AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}
```

### showAppInputDialog

Dialog with text input field.

```dart
Future<String?> showAppInputDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? initialValue,
  String? hintText,
  String confirmText = 'Save',
  String cancelText = 'Cancel',
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String)? validator,
}) async {
  final controller = TextEditingController(text: initialValue);
  final formKey = GlobalKey<FormState>();

  final result = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black54,
    transitionDuration: AppTheme.durationNormal,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return AppDialog(
        title: title,
        alignment: CrossAxisAlignment.start,
        content: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message != null) ...[
                Text(message),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: controller,
                autofocus: true,
                maxLines: maxLines,
                keyboardType: keyboardType,
                validator: validator != null ? (v) => validator(v ?? '') : null,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: cancelText,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(null),
          ),
          AppButton(
            label: confirmText,
            onPressed: () {
              if (formKey.currentState?.validate() ?? true) {
                Navigator.of(context).pop(controller.text);
              }
            },
          ),
        ],
      );
    },
  );
  
  controller.dispose();
  return result;
}
```

### showAppSelectionDialog

Dialog with selection options.

```dart
Future<T?> showAppSelectionDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  required List<SelectionOption<T>> options,
  T? initialValue,
}) async {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black54,
    transitionDuration: AppTheme.durationNormal,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Dialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleLarge),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ...options.map((option) => _SelectionTile<T>(
                  option: option,
                  selected: option.value == initialValue,
                  onTap: () => Navigator.of(context).pop(option.value),
                )),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class SelectionOption<T> {
  const SelectionOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

class _SelectionTile<T> extends StatelessWidget {
  const _SelectionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SelectionOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            if (option.icon != null) ...[
              Icon(option.icon, color: selected ? primary : null),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: selected ? primary : null,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                  if (option.subtitle != null)
                    Text(
                      option.subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: primary),
          ],
        ),
      ),
    );
  }
}
```

### showAppLoadingDialog

Non-dismissible loading indicator.

```dart
Future<T> showAppLoadingDialog<T>(
  BuildContext context, {
  required Future<T> future,
  String? message,
}) async {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: AppTheme.durationFast,
    pageBuilder: (context, animation, secondaryAnimation) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message, style: AppTextStyles.bodyMedium),
              ],
            ],
          ),
        ),
      );
    },
  );

  try {
    final result = await future;
    if (context.mounted) Navigator.of(context).pop();
    return result;
  } catch (e) {
    if (context.mounted) Navigator.of(context).pop();
    rethrow;
  }
}
```

---

## Usage Examples

```dart
// Alert dialog
await showAppAlertDialog(
  context,
  icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
  title: 'Workout Complete!',
  message: 'Great job! You burned 350 calories.',
  buttonText: 'Continue',
);

// Confirm dialog
final confirmed = await showAppConfirmDialog(
  context,
  icon: Icon(Icons.warning, color: Colors.orange, size: 48),
  title: 'Delete Workout?',
  message: 'This action cannot be undone.',
  confirmText: 'Delete',
  destructive: true,
);
if (confirmed) deleteWorkout();

// Input dialog
final workoutName = await showAppInputDialog(
  context,
  title: 'Rename Workout',
  initialValue: workout.name,
  hintText: 'Enter workout name',
  validator: (v) => v.isEmpty ? 'Name is required' : null,
);
if (workoutName != null) renameWorkout(workoutName);

// Selection dialog
final difficulty = await showAppSelectionDialog<Difficulty>(
  context,
  title: 'Select Difficulty',
  options: [
    SelectionOption(value: Difficulty.easy, label: 'Easy', icon: Icons.sentiment_satisfied),
    SelectionOption(value: Difficulty.medium, label: 'Medium', icon: Icons.sentiment_neutral),
    SelectionOption(value: Difficulty.hard, label: 'Hard', icon: Icons.sentiment_dissatisfied),
  ],
  initialValue: currentDifficulty,
);

// Loading dialog
final result = await showAppLoadingDialog(
  context,
  future: api.syncWorkouts(),
  message: 'Syncing...',
);
```

---

## Accessibility

- ✅ Focus trapped: Keyboard focus stays within dialog
- ✅ Semantic labels: Title announced on open
- ✅ Barrier dismissible: Can tap outside (except loading)
- ✅ Button order: Cancel left, confirm right (LTR)
- ✅ Escape key: Closes dismissible dialogs
- ✅ Min touch targets: 44px for all interactive elements
