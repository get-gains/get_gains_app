# AppSnackbar

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Brief feedback messages that appear at the bottom of the screen. Unlike toasts, snackbars can contain an action and integrate with Flutter's `ScaffoldMessenger` system. Use for confirmations, undo actions, and contextual feedback.

---

## Variants

| Variant | Purpose | Background Color | Icon |
|---------|---------|------------------|------|
| `info` | Neutral information | `surface3` / `gray800` | `info_outline` |
| `success` | Positive feedback | `#1B4332` / `#166534` | `check_circle_outline` |
| `warning` | Caution messages | `#78350F` / `warningMuted` | `warning_amber` |
| `error` | Error messages | `errorMuted` / `#B91C1C` | `error_outline` |

---

## Specifications

### Styling

| Property | Value | Token |
|----------|-------|-------|
| Border radius | 12px | `radiusMd` |
| Horizontal padding | 16px | `spacing4` |
| Vertical padding | 14px | - |
| Icon size | 20px | - |
| Icon gap | 12px | `spacing3` |
| Elevation | 4 | - |
| Margin (floating) | 16px all | `spacing4` |

### Typography

| Element | Style |
|---------|-------|
| Message | `bodyMedium`, white |
| Action label | `labelLarge`, variant accent color |

### Animation

- **Duration**: 4 seconds (default)
- **Behavior**: Floating or fixed
- **Dismiss**: Horizontal swipe

---

## Implementation

### Static Helper Methods

```dart
class AppSnackbar {
  /// Show a snackbar with full customization
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarVariant variant = AppSnackbarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    AppSnackbarConfig config = AppSnackbarConfig.defaults,
  });

  /// Convenience methods
  static void success(BuildContext context, String message, {...});
  static void error(BuildContext context, String message, {...});
  static void warning(BuildContext context, String message, {...});
  static void info(BuildContext context, String message, {...});

  /// Hide snackbars
  static void hide(BuildContext context);
  static void hideAll(BuildContext context);
}
```

### Configuration

```dart
class AppSnackbarConfig {
  const AppSnackbarConfig({
    this.duration = const Duration(seconds: 4),
    this.behavior = SnackBarBehavior.floating,
    this.showIcon = true,
    this.dismissible = true,
    this.margin = const EdgeInsets.all(16),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  static const AppSnackbarConfig defaults = AppSnackbarConfig();
}
```

---

## Usage Examples

### Basic Snackbar

```dart
// Simple message
AppSnackbar.info(context, 'Settings updated');

// Success feedback
AppSnackbar.success(context, 'Workout saved successfully!');

// Error message
AppSnackbar.error(context, 'Failed to connect to server');

// Warning
AppSnackbar.warning(context, 'You have unsaved changes');
```

### Snackbar with Action

```dart
// Undo action
AppSnackbar.show(
  context,
  message: 'Exercise deleted',
  variant: AppSnackbarVariant.info,
  actionLabel: 'Undo',
  onAction: () {
    // Restore the deleted item
    exerciseRepository.restore(exerciseId);
  },
);

// Retry on error
AppSnackbar.error(
  context,
  'Network error occurred',
  actionLabel: 'Retry',
  onAction: () => fetchData(),
);
```

### Custom Configuration

```dart
// Longer duration
AppSnackbar.success(
  context,
  'Your progress has been synced',
  config: const AppSnackbarConfig(
    duration: Duration(seconds: 6),
  ),
);

// Fixed behavior (not floating)
AppSnackbar.info(
  context,
  'New message received',
  config: const AppSnackbarConfig(
    behavior: SnackBarBehavior.fixed,
    showIcon: false,
  ),
);

// Non-dismissible
AppSnackbar.warning(
  context,
  'Processing...',
  config: const AppSnackbarConfig(
    dismissible: false,
    duration: Duration(seconds: 10),
  ),
);
```

### Programmatic Dismissal

```dart
// Show loading snackbar
AppSnackbar.info(
  context,
  'Uploading...',
  config: const AppSnackbarConfig(
    duration: Duration(minutes: 5),
    dismissible: false,
  ),
);

// Hide when done
await uploadFile();
AppSnackbar.hide(context);
AppSnackbar.success(context, 'Upload complete!');
```

### Using AppSnackbarWidget Directly

For custom overlay implementations:

```dart
// As a widget
AppSnackbarWidget(
  message: 'Item removed',
  variant: AppSnackbarVariant.warning,
  actionLabel: 'Undo',
  onAction: () => restoreItem(),
  onDismiss: () => hideSnackbar(),
)
```

---

## Comparison: Snackbar vs Toast

| Feature | AppSnackbar | AppToast |
|---------|-------------|----------|
| Action button | ✅ Yes | ✅ Yes |
| Position | Bottom only | Top or bottom |
| Stacking | No (replaces) | Yes (multiple) |
| Integration | ScaffoldMessenger | Custom overlay |
| Use case | Undo actions, confirmations | Notifications, alerts |

### When to Use Snackbar

- User-initiated actions needing confirmation
- Operations with undo capability
- Single message at a time
- Standard Material Design pattern

### When to Use Toast

- Multiple notifications
- Top-positioned alerts
- System-initiated messages
- Custom animations needed

---

## Accessibility

| Feature | Implementation |
|---------|----------------|
| Screen reader | Message announced automatically |
| Action focus | Action button receives focus |
| Dismiss | Supports horizontal swipe |
| Duration | Minimum 4 seconds for readability |
| Contrast | High contrast backgrounds |

### Accessibility Guidelines

```dart
// Ensure sufficient time for users to read and act
AppSnackbar.show(
  context,
  message: 'Long message that needs time to read',
  config: const AppSnackbarConfig(
    duration: Duration(seconds: 8),
  ),
);

// For critical actions, consider using a dialog instead
if (isCriticalAction) {
  showAppConfirmDialog(context, ...);
} else {
  AppSnackbar.success(context, 'Action completed');
}
```

---

## Do's and Don'ts

### ✅ Do

- Use for brief, contextual feedback
- Provide undo actions for destructive operations
- Keep messages concise (under 50 characters)
- Use appropriate variant for context

### ❌ Don't

- Don't use for critical errors requiring acknowledgment
- Don't show multiple snackbars simultaneously
- Don't use for long-form messages
- Don't rely solely on color to convey meaning

---

## Related Components

- [AppToast](./TOAST.md) - Overlay notifications
- [AppDialog](./DIALOG.md) - Modal confirmations
- [AppBottomSheet](./BOTTOM_SHEET.md) - Complex actions
