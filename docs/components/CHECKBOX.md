# AppCheckbox

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

---

## Purpose

Checkbox input for selecting one or more items from a list, or for acknowledging terms/conditions. Use checkboxes when selections require explicit submission (unlike switches which apply immediately).

---

## Variants

| Variant | Purpose |
|---------|---------|
| `default` | Standard checkbox with label |
| `indeterminate` | Parent checkbox with mixed child states |
| `card` | Checkbox within a selectable card |

---

## Sizes

| Size | Box Size | Icon Size | Label Style | Usage |
|------|----------|-----------|-------------|-------|
| `sm` | 16px | 12px | `bodySmall` | Compact lists, dense UIs |
| `md` | 20px | 14px | `bodyMedium` | Default, most contexts |
| `lg` | 24px | 18px | `bodyLarge` | Emphasized selections |

---

## States

| State | Box Color | Border | Check Color | Usage |
|-------|-----------|--------|-------------|-------|
| `unchecked` | `transparent` | `border` | - | Default off |
| `checked` | `primary` | `primary` | `primaryForeground` | Selected |
| `indeterminate` | `primary` | `primary` | `primaryForeground` | Partial selection |
| `disabled` | `muted` @ 50% | `border` @ 50% | `mutedForeground` | Non-interactive |
| `error` | `transparent` | `error` | - | Validation error |
| `focused` | - | `ring` (2px) | - | Keyboard focus |

---

## Specifications

### Anatomy

```
┌─────────────────────────────────────────────┐
│  [□] [Label]                                │
│      [Helper/Error text]                    │
└─────────────────────────────────────────────┘
```

### Tokens

| Property | Token | Value |
|----------|-------|-------|
| Box radius | `radiusSm` | 4px |
| Border width | `borderThin` | 1px |
| Border color (off) | `border` | `#363636` |
| Border color (on) | `primary` | `#E07D3B` |
| Fill color (on) | `primary` | `#E07D3B` |
| Check color | `primaryForeground` | `#FFFFFF` |
| Error border | `error` | `#F87171` |
| Focus ring | `ring` | `#E8844A` |
| Focus ring width | `borderMedium` | 2px |
| Disabled opacity | - | 0.5 |
| Animation duration | `durationFast` | 100ms |
| Animation curve | `curveDefault` | easeInOut |

### Spacing

| Property | Token | Value |
|----------|-------|-------|
| Box to label | `spacing2` | 8px |
| Label to helper | `spacing1` | 4px |
| Touch target min | - | 44px × 44px |
| Group item gap | `spacing3` | 12px |

---

## Implementation

### AppCheckbox Widget

```dart
import 'package:flutter/material.dart';

enum AppCheckboxSize { sm, md, lg }

enum AppCheckboxState { unchecked, checked, indeterminate }

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.size = AppCheckboxSize.md,
    this.enabled = true,
    this.hasError = false,
    this.activeColor,
    this.checkColor,
    this.focusNode,
    this.autofocus = false,
  });

  /// Current value. If tristate is true, can be null (indeterminate).
  final bool? value;
  
  /// Called when the checkbox is tapped.
  final ValueChanged<bool?>? onChanged;
  
  /// If true, allows three states: checked, unchecked, indeterminate (null).
  final bool tristate;
  
  final AppCheckboxSize size;
  final bool enabled;
  final bool hasError;
  final Color? activeColor;
  final Color? checkColor;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final dimensions = _getDimensions();
    final isInteractive = enabled && onChanged != null;
    
    return Semantics(
      checked: value ?? false,
      mixed: tristate && value == null,
      enabled: isInteractive,
      child: GestureDetector(
        onTap: isInteractive ? () => _handleTap() : null,
        child: Focus(
          focusNode: focusNode,
          autofocus: autofocus,
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                width: dimensions.boxSize,
                height: dimensions.boxSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _getFillColor(colors),
                  border: Border.all(
                    color: _getBorderColor(colors, isFocused),
                    width: isFocused ? 2 : 1,
                  ),
                ),
                child: _buildIcon(colors, dimensions),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (tristate) {
      // Cycle: unchecked -> checked -> indeterminate -> unchecked
      switch (value) {
        case false:
          onChanged?.call(true);
        case true:
          onChanged?.call(null);
        case null:
          onChanged?.call(false);
      }
    } else {
      onChanged?.call(!(value ?? false));
    }
  }

  _CheckboxDimensions _getDimensions() {
    return switch (size) {
      AppCheckboxSize.sm => _CheckboxDimensions(boxSize: 16, iconSize: 12),
      AppCheckboxSize.md => _CheckboxDimensions(boxSize: 20, iconSize: 14),
      AppCheckboxSize.lg => _CheckboxDimensions(boxSize: 24, iconSize: 18),
    };
  }

  Color _getFillColor(ColorScheme colors) {
    if (!enabled) {
      return value == true || value == null
          ? (activeColor ?? colors.primary).withOpacity(0.5)
          : Colors.transparent;
    }
    if (value == true || value == null) {
      return activeColor ?? colors.primary;
    }
    return Colors.transparent;
  }

  Color _getBorderColor(ColorScheme colors, bool isFocused) {
    if (isFocused) {
      return colors.primary;
    }
    if (hasError) {
      return colors.error;
    }
    if (!enabled) {
      return colors.outline.withOpacity(0.5);
    }
    if (value == true || value == null) {
      return activeColor ?? colors.primary;
    }
    return colors.outline;
  }

  Widget? _buildIcon(ColorScheme colors, _CheckboxDimensions dimensions) {
    final iconColor = !enabled
        ? (checkColor ?? colors.onPrimary).withOpacity(0.7)
        : (checkColor ?? colors.onPrimary);

    if (value == true) {
      return Icon(
        Icons.check,
        size: dimensions.iconSize,
        color: iconColor,
      );
    }
    if (value == null) {
      // Indeterminate state - horizontal line
      return Icon(
        Icons.remove,
        size: dimensions.iconSize,
        color: iconColor,
      );
    }
    return null;
  }
}

class _CheckboxDimensions {
  final double boxSize;
  final double iconSize;

  _CheckboxDimensions({required this.boxSize, required this.iconSize});
}
```

### AppCheckboxListTile Widget

```dart
class AppCheckboxListTile extends StatelessWidget {
  const AppCheckboxListTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.secondary,
    this.tristate = false,
    this.enabled = true,
    this.hasError = false,
    this.errorText,
    this.checkboxSize = AppCheckboxSize.md,
    this.controlAffinity = ListTileControlAffinity.leading,
    this.contentPadding,
    this.dense = false,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? secondary;
  final bool tristate;
  final bool enabled;
  final bool hasError;
  final String? errorText;
  final AppCheckboxSize checkboxSize;
  final ListTileControlAffinity controlAffinity;
  final EdgeInsetsGeometry? contentPadding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final checkbox = AppCheckbox(
      value: value,
      onChanged: enabled ? onChanged : null,
      tristate: tristate,
      size: checkboxSize,
      enabled: enabled,
      hasError: hasError,
    );

    return InkWell(
      onTap: enabled && onChanged != null
          ? () {
              if (tristate) {
                switch (value) {
                  case false:
                    onChanged?.call(true);
                  case true:
                    onChanged?.call(null);
                  case null:
                    onChanged?.call(false);
                }
              } else {
                onChanged?.call(!(value ?? false));
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: contentPadding ??
            EdgeInsets.symmetric(
              horizontal: 16,
              vertical: dense ? 8 : 12,
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (controlAffinity == ListTileControlAffinity.leading) ...[
                  checkbox,
                  const SizedBox(width: 12),
                ],
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
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
                                : theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.5),
                          ),
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (secondary != null) ...[
                  const SizedBox(width: 12),
                  secondary!,
                ],
                if (controlAffinity == ListTileControlAffinity.trailing) ...[
                  const SizedBox(width: 12),
                  checkbox,
                ],
              ],
            ),
            if (hasError && errorText != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  errorText!,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.error,
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
```

### AppCheckboxGroup Widget

```dart
class AppCheckboxGroup<T> extends StatelessWidget {
  const AppCheckboxGroup({
    super.key,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    this.itemBuilder,
    this.enabled = true,
    this.checkboxSize = AppCheckboxSize.md,
    this.spacing = 12,
    this.direction = Axis.vertical,
  });

  final List<T> items;
  final Set<T> selectedValues;
  final ValueChanged<Set<T>> onChanged;
  final Widget Function(T item)? itemBuilder;
  final bool enabled;
  final AppCheckboxSize checkboxSize;
  final double spacing;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final children = items.map((item) {
      final isSelected = selectedValues.contains(item);
      
      return AppCheckboxListTile(
        value: isSelected,
        onChanged: enabled
            ? (_) {
                final newValues = Set<T>.from(selectedValues);
                if (isSelected) {
                  newValues.remove(item);
                } else {
                  newValues.add(item);
                }
                onChanged(newValues);
              }
            : null,
        title: itemBuilder?.call(item) ?? Text(item.toString()),
        checkboxSize: checkboxSize,
        enabled: enabled,
        dense: true,
        contentPadding: EdgeInsets.zero,
      );
    }).toList();

    if (direction == Axis.horizontal) {
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((child) {
        final index = children.indexOf(child);
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < children.length - 1 ? spacing : 0,
          ),
          child: child,
        );
      }).toList(),
    );
  }
}
```

---

## Usage Examples

### Basic Checkbox

```dart
bool _agreeToTerms = false;

AppCheckbox(
  value: _agreeToTerms,
  onChanged: (value) {
    setState(() => _agreeToTerms = value ?? false);
  },
)
```

### Different Sizes

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    AppCheckbox(
      value: true,
      onChanged: (_) {},
      size: AppCheckboxSize.sm,
    ),
    AppCheckbox(
      value: true,
      onChanged: (_) {},
      size: AppCheckboxSize.md,
    ),
    AppCheckbox(
      value: true,
      onChanged: (_) {},
      size: AppCheckboxSize.lg,
    ),
  ],
)
```

### Checkbox with Label

```dart
AppCheckboxListTile(
  value: _newsletter,
  onChanged: (value) {
    setState(() => _newsletter = value ?? false);
  },
  title: const Text('Subscribe to newsletter'),
  subtitle: const Text('Get weekly workout tips and updates'),
)
```

### Indeterminate State (Select All Pattern)

```dart
// Parent checkbox for "select all"
AppCheckboxListTile(
  value: _allSelected ? true : (_someSelected ? null : false),
  onChanged: (value) {
    setState(() {
      if (value == true) {
        _selectedItems = Set.from(_allItems);
      } else {
        _selectedItems.clear();
      }
    });
  },
  tristate: true,
  title: const Text('Select All'),
)

// Child checkboxes
for (final item in _allItems)
  AppCheckboxListTile(
    value: _selectedItems.contains(item),
    onChanged: (value) {
      setState(() {
        if (value == true) {
          _selectedItems.add(item);
        } else {
          _selectedItems.remove(item);
        }
      });
    },
    title: Text(item.name),
  ),
```

### Error State

```dart
AppCheckboxListTile(
  value: _agreeToTerms,
  onChanged: (value) {
    setState(() => _agreeToTerms = value ?? false);
  },
  title: const Text('I agree to the Terms and Conditions'),
  hasError: !_agreeToTerms && _submitted,
  errorText: !_agreeToTerms && _submitted
      ? 'You must agree to continue'
      : null,
)
```

### Checkbox Group

```dart
final _selectedWorkoutTypes = <String>{};

AppCheckboxGroup<String>(
  items: ['Strength', 'Cardio', 'Flexibility', 'HIIT'],
  selectedValues: _selectedWorkoutTypes,
  onChanged: (values) {
    setState(() => _selectedWorkoutTypes = values);
  },
  itemBuilder: (item) => Text(item),
)
```

### Trailing Checkbox (Selection List)

```dart
AppCheckboxListTile(
  value: _selected,
  onChanged: (value) => setState(() => _selected = value ?? false),
  title: const Text('Premium Membership'),
  subtitle: const Text('\$9.99/month'),
  leading: const Icon(Icons.star),
  controlAffinity: ListTileControlAffinity.trailing,
)
```

### Disabled State

```dart
AppCheckboxListTile(
  value: true,
  onChanged: null,
  enabled: false,
  title: const Text('Premium Feature'),
  subtitle: const Text('Upgrade to unlock'),
)
```

---

## Accessibility

### Semantic Properties

- Uses `Semantics` with `checked` and `mixed` for screen readers
- Announces state changes (checked, unchecked, indeterminate)

### Keyboard Navigation

- Focusable via Tab key
- Toggle with Space or Enter
- Clear focus ring indicator

### Touch Targets

- Minimum touch target: 44×44px
- `AppCheckboxListTile` expands tap area to full row

### Best Practices

```dart
// ✅ Always provide a label
AppCheckboxListTile(
  title: const Text('Enable notifications'),
  ...
)

// ✅ Group related checkboxes
AppCheckboxGroup(
  items: workoutTypes,
  ...
)

// ❌ Avoid standalone checkbox without context
AppCheckbox(value: true, onChanged: (_) {})
```

---

## When to Use

| Use Checkbox | Use Switch |
|--------------|------------|
| Form submission required | Immediate effect |
| Multiple selections | Single binary toggle |
| Terms/acknowledgments | Settings/preferences |
| Selection from a list | On/off features |

---

## Related Components

- [AppSwitch](./SWITCH.md) - For immediate toggle actions
- [AppRadio](./RADIO.md) - For single selection from options
- [AppListTile](./LIST_TILE.md) - Base list item component

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-23 | Initial documentation |
