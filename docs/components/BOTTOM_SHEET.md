# AppBottomSheet

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Modal sheets that slide up from the bottom of the screen. Used for actions, confirmations, options, and additional content.

---

## Variants

| Variant | Purpose | Components |
|---------|---------|------------|
| `standard` | Custom content | Drag handle, content area |
| `confirm` | Confirmation dialogs | Icon, title, message, buttons |
| `action` | List of options | Title, action items, cancel |

---

## Specifications

### Container Styling

- **Background**: `card` color
- **Border radius**: `radiusXl` (20px) top corners
- **Drag handle**: 32×4px centered bar, `mutedForeground`
- **Max height**: 90% of screen
- **Padding**: `spacing5` (20px) horizontal

### Animation

- **Duration**: `durationSlow` (300ms)
- **Curve**: `Curves.easeOut` for enter, `Curves.easeIn` for exit

---

## Implementation

### Base Components

```dart
// lib/widgets/app_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Drag handle widget for bottom sheets
class AppBottomSheetHandle extends StatelessWidget {
  const AppBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 32,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Content wrapper for bottom sheets
class AppBottomSheetContent extends StatelessWidget {
  const AppBottomSheetContent({
    super.key,
    required this.child,
    this.showDragHandle = true,
    this.padding,
  });

  final Widget child;
  final bool showDragHandle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle) const AppBottomSheetHandle(),
            Flexible(
              child: Padding(
                padding: padding ?? const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header for bottom sheets
class AppBottomSheetHeader extends StatelessWidget {
  const AppBottomSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showCloseButton = false,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showCloseButton;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (showCloseButton)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose ?? () => Navigator.pop(context),
              color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
            ),
        ],
      ),
    );
  }
}
```

### Helper Functions

```dart
/// Show a standard bottom sheet
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool showDragHandle = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = true,
  Color? backgroundColor,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) => AppBottomSheetContent(
      showDragHandle: showDragHandle,
      child: builder(context),
    ),
  );
}

/// Show a confirmation bottom sheet
Future<bool?> showAppConfirmSheet({
  required BuildContext context,
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  IconData? icon,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showAppBottomSheet<bool>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (isDestructive ? AppColors.error : (isDark ? AppColors.primaryDark : AppColors.primaryLight))
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: isDestructive ? AppColors.error : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
          ),
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppButton.outline(
                label: cancelLabel,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isDestructive
                  ? AppButton.destructive(
                      label: confirmLabel,
                      onPressed: () => Navigator.pop(context, true),
                    )
                  : AppButton(
                      label: confirmLabel,
                      onPressed: () => Navigator.pop(context, true),
                    ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Action sheet item
class AppActionSheetItem<T> {
  const AppActionSheetItem({
    required this.label,
    required this.value,
    this.icon,
    this.isSelected = false,
    this.isDestructive = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final bool isSelected;
  final bool isDestructive;
}

/// Show an action sheet
Future<T?> showAppActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<AppActionSheetItem<T>> actions,
  bool showCancel = true,
  String cancelLabel = 'Cancel',
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showAppBottomSheet<T>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
        ...actions.map((action) => _ActionItem(
          action: action,
          onTap: () => Navigator.pop(context, action.value),
        )),
        if (showCancel) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: AppButton.ghost(
              label: cancelLabel,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ActionItem<T> extends StatelessWidget {
  const _ActionItem({
    required this.action,
    required this.onTap,
  });

  final AppActionSheetItem<T> action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = action.isDestructive
        ? AppColors.error
        : (isDark ? AppColors.foregroundDark : AppColors.foregroundLight);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (action.icon != null) ...[
                Icon(action.icon, size: 22, color: color),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  action.label,
                  style: AppTextStyles.bodyLarge.copyWith(color: color),
                ),
              ),
              if (action.isSelected)
                Icon(Icons.check, size: 20, color: isDark ? AppColors.primaryDark : AppColors.primaryLight),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Usage Examples

```dart
// Custom content bottom sheet
showAppBottomSheet(
  context: context,
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppBottomSheetHeader(
        title: 'Options',
        showCloseButton: true,
      ),
      // Custom content here
      MyCustomWidget(),
    ],
  ),
)

// Confirmation sheet
final confirmed = await showAppConfirmSheet(
  context: context,
  title: 'Delete Workout?',
  message: 'This action cannot be undone.',
  confirmLabel: 'Delete',
  isDestructive: true,
  icon: Icons.delete_outline,
);

if (confirmed == true) {
  deleteWorkout();
}

// Action sheet for selection
final sortOption = await showAppActionSheet<String>(
  context: context,
  title: 'Sort Workouts',
  actions: [
    AppActionSheetItem(
      label: 'Most Recent',
      value: 'recent',
      icon: Icons.access_time,
      isSelected: currentSort == 'recent',
    ),
    AppActionSheetItem(
      label: 'Name (A-Z)',
      value: 'name',
      icon: Icons.sort_by_alpha,
      isSelected: currentSort == 'name',
    ),
    AppActionSheetItem(
      label: 'Duration',
      value: 'duration',
      icon: Icons.timer,
      isSelected: currentSort == 'duration',
    ),
  ],
);

if (sortOption != null) {
  setSortOption(sortOption);
}

// Action sheet with destructive option
final action = await showAppActionSheet<String>(
  context: context,
  actions: [
    AppActionSheetItem(label: 'Edit', value: 'edit', icon: Icons.edit),
    AppActionSheetItem(label: 'Duplicate', value: 'duplicate', icon: Icons.copy),
    AppActionSheetItem(
      label: 'Delete',
      value: 'delete',
      icon: Icons.delete,
      isDestructive: true,
    ),
  ],
);

// Scrollable content
showAppBottomSheet(
  context: context,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.5,
    maxChildSize: 0.9,
    minChildSize: 0.3,
    expand: false,
    builder: (context, scrollController) => ListView.builder(
      controller: scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) => ListTile(title: Text(items[index])),
    ),
  ),
)
```

---

## Accessibility

- ✅ Dismissible: Can be dismissed with back gesture/button
- ✅ Focus trap: Focus trapped within sheet when open
- ✅ Drag handle: Provides visual affordance for dragging
- ✅ Button labels: Clear and descriptive
- ✅ Destructive actions: Visually distinct (error color)
