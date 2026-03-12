# AppSwitch

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

---

## Purpose

Toggle switch for binary on/off states. Use switches for settings that take effect immediately without requiring a save action.

---

## Variants

| Variant | Purpose |
|---------|---------|
| `default` | Standard toggle switch |
| `labeled` | Switch with on/off labels |
| `icon` | Switch with icons for on/off states |

---

## Sizes

| Size | Track Height | Track Width | Thumb Size | Usage |
|------|--------------|-------------|------------|-------|
| `sm` | 20px | 36px | 16px | Compact lists, dense UIs |
| `md` | 24px | 44px | 20px | Default, most contexts |
| `lg` | 28px | 52px | 24px | Emphasized settings |

---

## States

| State | Track Color (Off) | Track Color (On) | Thumb Color | Usage |
|-------|-------------------|------------------|-------------|-------|
| `default` | `muted` | `primary` | `foreground` | Normal state |
| `disabled` | `muted` @ 50% | `primary` @ 50% | `mutedForeground` | Non-interactive |
| `focused` | + `ring` border | + `ring` border | - | Keyboard navigation |
| `loading` | `muted` | - | Spinner | Async toggle |

---

## Specifications

### Anatomy

```
┌─────────────────────────────────────────────┐
│  [Label]                        [Switch]    │
│  [Description]                              │
└─────────────────────────────────────────────┘
```

### Tokens

| Property | Token | Value |
|----------|-------|-------|
| Track radius | `radiusFull` | 9999px |
| Thumb radius | `radiusFull` | 9999px |
| Track border | `borderThin` | 1px |
| Off track color | `muted` | `#363636` |
| On track color | `primary` | `#E07D3B` |
| Thumb color | `foreground` | `#FFFFFF` |
| Disabled opacity | - | 0.5 |
| Focus ring | `ring` | `#E8844A` |
| Focus ring width | `borderMedium` | 2px |
| Animation duration | `durationNormal` | 200ms |
| Animation curve | `curveDefault` | easeInOut |

### Spacing

| Property | Token | Value |
|----------|-------|-------|
| Label gap | `spacing3` | 12px |
| Description gap | `spacing1` | 4px |
| Touch target min | - | 44px × 44px |

---

## Implementation

### AppSwitch Widget

```dart
import 'package:flutter/material.dart';

enum AppSwitchSize { sm, md, lg }

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = AppSwitchSize.md,
    this.enabled = true,
    this.loading = false,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.focusNode,
    this.autofocus = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final AppSwitchSize size;
  final bool enabled;
  final bool loading;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final dimensions = _getDimensions();
    final isInteractive = enabled && !loading && onChanged != null;
    
    return Semantics(
      toggled: value,
      enabled: isInteractive,
      child: GestureDetector(
        onTap: isInteractive ? () => onChanged?.call(!value) : null,
        child: Focus(
          focusNode: focusNode,
          autofocus: autofocus,
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: dimensions.trackWidth,
                height: dimensions.trackHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  color: _getTrackColor(colors),
                  border: isFocused
                      ? Border.all(color: colors.primary, width: 2)
                      : null,
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: dimensions.thumbSize,
                    height: dimensions.thumbSize,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getThumbColor(colors),
                    ),
                    child: loading
                        ? Padding(
                            padding: const EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  _SwitchDimensions _getDimensions() {
    return switch (size) {
      AppSwitchSize.sm => _SwitchDimensions(
          trackWidth: 36,
          trackHeight: 20,
          thumbSize: 16,
        ),
      AppSwitchSize.md => _SwitchDimensions(
          trackWidth: 44,
          trackHeight: 24,
          thumbSize: 20,
        ),
      AppSwitchSize.lg => _SwitchDimensions(
          trackWidth: 52,
          trackHeight: 28,
          thumbSize: 24,
        ),
    };
  }

  Color _getTrackColor(ColorScheme colors) {
    if (!enabled) {
      return value
          ? (activeColor ?? colors.primary).withOpacity(0.5)
          : (inactiveColor ?? colors.surfaceContainerHighest).withOpacity(0.5);
    }
    return value
        ? (activeColor ?? colors.primary)
        : (inactiveColor ?? colors.surfaceContainerHighest);
  }

  Color _getThumbColor(ColorScheme colors) {
    if (!enabled) {
      return (thumbColor ?? colors.onPrimary).withOpacity(0.7);
    }
    return thumbColor ?? colors.onPrimary;
  }
}

class _SwitchDimensions {
  final double trackWidth;
  final double trackHeight;
  final double thumbSize;

  _SwitchDimensions({
    required this.trackWidth,
    required this.trackHeight,
    required this.thumbSize,
  });
}
```

### AppSwitchListTile Widget

```dart
class AppSwitchListTile extends StatelessWidget {
  const AppSwitchListTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.loading = false,
    this.switchSize = AppSwitchSize.md,
    this.contentPadding,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool enabled;
  final bool loading;
  final AppSwitchSize switchSize;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: enabled && !loading && onChanged != null
          ? () => onChanged?.call(!value)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: enabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: enabled
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppSwitch(
              value: value,
              onChanged: enabled && !loading ? onChanged : null,
              size: switchSize,
              enabled: enabled,
              loading: loading,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Usage Examples

### Basic Switch

```dart
bool _notifications = true;

AppSwitch(
  value: _notifications,
  onChanged: (value) {
    setState(() => _notifications = value);
  },
)
```

### Different Sizes

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    AppSwitch(
      value: true,
      onChanged: (_) {},
      size: AppSwitchSize.sm,
    ),
    AppSwitch(
      value: true,
      onChanged: (_) {},
      size: AppSwitchSize.md,
    ),
    AppSwitch(
      value: true,
      onChanged: (_) {},
      size: AppSwitchSize.lg,
    ),
  ],
)
```

### Disabled State

```dart
AppSwitch(
  value: true,
  onChanged: null, // or enabled: false
  enabled: false,
)
```

### Loading State

```dart
AppSwitch(
  value: _isEnabled,
  onChanged: (value) async {
    setState(() => _isLoading = true);
    await savePreference(value);
    setState(() {
      _isEnabled = value;
      _isLoading = false;
    });
  },
  loading: _isLoading,
)
```

### Switch List Tile (Settings Pattern)

```dart
AppSwitchListTile(
  value: _darkMode,
  onChanged: (value) {
    setState(() => _darkMode = value);
  },
  title: const Text('Dark Mode'),
  subtitle: const Text('Use dark theme throughout the app'),
  leading: Icon(
    _darkMode ? Icons.dark_mode : Icons.light_mode,
    color: Theme.of(context).colorScheme.primary,
  ),
)
```

### Custom Colors

```dart
AppSwitch(
  value: _premium,
  onChanged: (value) => setState(() => _premium = value),
  activeColor: Colors.amber,
  thumbColor: Colors.white,
)
```

### Settings List

```dart
Column(
  children: [
    AppSwitchListTile(
      value: _notifications,
      onChanged: (v) => setState(() => _notifications = v),
      title: const Text('Push Notifications'),
      subtitle: const Text('Receive workout reminders'),
      leading: const Icon(Icons.notifications_outlined),
    ),
    const Divider(height: 1),
    AppSwitchListTile(
      value: _sounds,
      onChanged: (v) => setState(() => _sounds = v),
      title: const Text('Sound Effects'),
      subtitle: const Text('Play sounds during workouts'),
      leading: const Icon(Icons.volume_up_outlined),
    ),
    const Divider(height: 1),
    AppSwitchListTile(
      value: _analytics,
      onChanged: (v) => setState(() => _analytics = v),
      title: const Text('Analytics'),
      subtitle: const Text('Help improve the app'),
      leading: const Icon(Icons.analytics_outlined),
    ),
  ],
)
```

---

## Accessibility

### Semantic Properties

- Uses `Semantics` widget with `toggled` and `enabled` properties
- Screen readers announce state changes
- Provides clear on/off state indication

### Keyboard Navigation

- Focusable via Tab key
- Toggle with Space or Enter
- Focus ring indicates current focus

### Touch Targets

- Minimum touch target: 44×44px
- `AppSwitchListTile` expands tap area to full row

### Best Practices

```dart
// ✅ Always provide context via label
AppSwitchListTile(
  title: const Text('Enable notifications'),
  subtitle: const Text('Get reminders for upcoming workouts'),
  ...
)

// ❌ Avoid standalone switches without labels
AppSwitch(value: true, onChanged: (_) {})
```

---

## When to Use

| Use Switch | Use Checkbox |
|------------|--------------|
| Immediate effect (no save button) | Requires form submission |
| Single binary setting | Multiple selections allowed |
| Settings/preferences | Selection in a list |
| Toggle features on/off | Acknowledge terms/conditions |

---

## Related Components

- [AppCheckbox](./CHECKBOX.md) - For form selections
- [AppListTile](./LIST_TILE.md) - Base list item component
- [AppRadio](./RADIO.md) - For single selection from options

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-23 | Initial documentation |
