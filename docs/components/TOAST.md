# AppToast

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Non-intrusive notifications that provide brief feedback about an action or event. Toasts appear temporarily and auto-dismiss, ideal for confirmations, warnings, and error messages.

---

## Variants

| Variant | Purpose | Colors |
|---------|---------|--------|
| `info` | Neutral information | `surface2` bg, `info` icon |
| `success` | Positive feedback | `successMuted` bg, `success` icon |
| `warning` | Caution messages | `warningMuted` bg, `warning` icon |
| `error` | Error messages | `errorMuted` bg, `error` icon |

---

## Specifications

### Styling

- **Border radius**: `radiusMd` (12px)
- **Padding**: 16px horizontal, 12px vertical
- **Max width**: 400px
- **Icon size**: 20px
- **Shadow**: 8px blur, 4px offset

### Animation

- **Duration**: 250ms enter/exit
- **Curve**: `easeOutCubic` (enter), `easeInCubic` (exit)
- **Default display**: 3 seconds
- **Direction**: Slide from top/bottom edge

### Layout

```
┌─────────────────────────────────────────┐
│ [🔵] Title (optional)        [Action]   │
│      Message text here                  │
└─────────────────────────────────────────┘
```

---

## Setup

### 1. Add Toast Overlay

Wrap your app with `AppToastOverlay`:

```dart
// main.dart
MaterialApp(
  builder: (context, child) {
    return AppToastOverlay(child: child!);
  },
  // ... other config
)
```

### 2. Show Toasts

Call toast methods from anywhere:

```dart
AppToast.success(context, 'Workout saved!');
AppToast.error(context, 'Failed to save');
AppToast.warning(context, 'Low battery');
AppToast.info(context, 'New feature available');
```

---

## Implementation

```dart
// lib/widgets/app_toast.dart

enum AppToastVariant { info, success, warning, error }
enum AppToastPosition { top, bottom }

class AppToastConfig {
  const AppToastConfig({
    this.duration = const Duration(seconds: 3),
    this.position = AppToastPosition.bottom,
    this.showIcon = true,
    this.dismissible = true,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final Duration duration;
  final AppToastPosition position;
  final bool showIcon;
  final bool dismissible;
  final EdgeInsets margin;

  static const AppToastConfig defaults = AppToastConfig();
}

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    AppToastVariant variant = AppToastVariant.info,
    String? title,
    VoidCallback? action,
    String? actionLabel,
    AppToastConfig config = AppToastConfig.defaults,
  });

  static void success(BuildContext context, String message, {...});
  static void error(BuildContext context, String message, {...});
  static void warning(BuildContext context, String message, {...});
  static void info(BuildContext context, String message, {...});
  static void dismissAll();
}

class AppToastOverlay extends StatefulWidget {
  const AppToastOverlay({required this.child});
  final Widget child;
}
```

---

## Usage Examples

### Basic Success Toast

```dart
AppToast.success(context, 'Changes saved successfully!');
```

### Error with Title

```dart
AppToast.error(
  context,
  'Please check your connection and try again.',
  title: 'Network Error',
);
```

### Toast with Action

```dart
AppToast.info(
  context,
  'Item moved to trash.',
  action: () => undoDelete(),
  actionLabel: 'Undo',
);
```

### Custom Duration

```dart
AppToast.warning(
  context,
  'Your session will expire in 5 minutes.',
  config: AppToastConfig(
    duration: Duration(seconds: 5),
  ),
);
```

### Top Position

```dart
AppToast.success(
  context,
  'New workout added!',
  config: AppToastConfig(
    position: AppToastPosition.top,
  ),
);
```

### Non-Dismissible

```dart
AppToast.info(
  context,
  'Syncing data...',
  config: AppToastConfig(
    dismissible: false,
    duration: Duration(seconds: 10),
  ),
);
```

### Full Customization

```dart
AppToast.show(
  context,
  message: 'Workout completed! You burned 320 calories.',
  variant: AppToastVariant.success,
  title: 'Great Job! 🎉',
  action: () => shareWorkout(),
  actionLabel: 'Share',
  config: AppToastConfig(
    duration: Duration(seconds: 5),
    position: AppToastPosition.top,
    showIcon: true,
    dismissible: true,
  ),
);
```

### Dismiss All Toasts

```dart
// Clear all visible toasts (useful before navigation)
AppToast.dismissAll();
```

### Standalone Toast Widget

For custom positioning without the overlay system:

```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 200),
  child: showConfirmation
    ? AppToastWidget(
        message: 'Item added to favorites',
        variant: AppToastVariant.success,
      )
    : SizedBox.shrink(),
)
```

---

## Toast Queue Behavior

- Multiple toasts stack vertically
- Each toast has independent timing
- Toasts can be swiped to dismiss (when `dismissible: true`)
- New toasts appear at the edge (top or bottom)

---

## Accessibility

- Toasts are announced by screen readers
- Minimum 3-second display for readability
- Action buttons have clear labels
- Color is not the only indicator (icons included)
- Sufficient contrast ratios for all variants

---

## Best Practices

1. **Keep messages brief** — 1-2 lines maximum
2. **Use appropriate variants** — Match variant to message type
3. **Don't overuse** — Reserve for important feedback
4. **Provide actions when useful** — "Undo" for destructive actions
5. **Consider timing** — Longer duration for complex messages
6. **Position thoughtfully** — Bottom for general, top for urgent

---

## When to Use

| Scenario | Use Toast? | Alternative |
|----------|------------|-------------|
| Form saved | ✅ Yes | — |
| Item deleted | ✅ Yes (with Undo) | — |
| Network error | ✅ Yes | AppErrorState for persistent |
| Validation error | ⚠️ Maybe | Inline field errors better |
| Critical error | ❌ No | AppDialog |
| Loading state | ❌ No | AppProgress |
| Confirmation needed | ❌ No | AppDialog.confirm |

---

## Related Components

- [AppDialog](./DIALOG.md) — Modal dialogs for important messages
- [AppProgress](./PROGRESS.md) — Loading indicators
- [AppEmptyState](./EMPTY_STATE.md) — Persistent state displays
