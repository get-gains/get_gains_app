# AppRadio

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

---

## Purpose

Radio buttons for selecting a single option from a mutually exclusive set. Use radio buttons when users must choose exactly one option from a visible list of choices.

---

## Variants

| Variant | Purpose |
|---------|---------|
| `default` | Standard radio with label |
| `card` | Radio within a selectable card |
| `segment` | Segmented control appearance |

---

## Sizes

| Size | Circle Size | Dot Size | Label Style | Usage |
|------|-------------|----------|-------------|-------|
| `sm` | 16px | 8px | `bodySmall` | Compact lists, dense UIs |
| `md` | 20px | 10px | `bodyMedium` | Default, most contexts |
| `lg` | 24px | 12px | `bodyLarge` | Emphasized selections |

---

## States

| State | Border | Fill | Dot Color | Usage |
|-------|--------|------|-----------|-------|
| `unselected` | `border` | `transparent` | - | Default off |
| `selected` | `primary` | `transparent` | `primary` | Selected |
| `disabled` | `border` @ 50% | `transparent` | `primary` @ 50% | Non-interactive |
| `error` | `error` | `transparent` | - | Validation error |
| `focused` | `ring` (2px) | - | - | Keyboard focus |

---

## Specifications

### Anatomy

```
┌─────────────────────────────────────────────┐
│  (○) [Label]                                │
│      [Description]                          │
└─────────────────────────────────────────────┘
```

### Tokens

| Property | Token | Value |
|----------|-------|-------|
| Circle radius | `radiusFull` | 9999px |
| Border width | `borderMedium` | 2px |
| Border color (off) | `border` | `#363636` |
| Border color (on) | `primary` | `#E07D3B` |
| Dot color | `primary` | `#E07D3B` |
| Error border | `error` | `#F87171` |
| Focus ring | `ring` | `#E8844A` |
| Focus ring width | `borderMedium` | 2px |
| Disabled opacity | - | 0.5 |
| Animation duration | `durationFast` | 100ms |
| Animation curve | `curveDefault` | easeInOut |

### Spacing

| Property | Token | Value |
|----------|-------|-------|
| Circle to label | `spacing2` | 8px |
| Label to description | `spacing1` | 4px |
| Touch target min | - | 44px × 44px |
| Group item gap | `spacing3` | 12px |

---

## Implementation

### AppRadio Widget

```dart
import 'package:flutter/material.dart';

enum AppRadioSize { sm, md, lg }

class AppRadio<T> extends StatelessWidget {
  const AppRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.size = AppRadioSize.md,
    this.enabled = true,
    this.hasError = false,
    this.activeColor,
    this.focusNode,
    this.autofocus = false,
  });

  /// The value represented by this radio button.
  final T value;
  
  /// The currently selected value for the group.
  final T? groupValue;
  
  /// Called when this radio is selected.
  final ValueChanged<T?>? onChanged;
  
  final AppRadioSize size;
  final bool enabled;
  final bool hasError;
  final Color? activeColor;
  final FocusNode? focusNode;
  final bool autofocus;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final dimensions = _getDimensions();
    final isInteractive = enabled && onChanged != null;
    
    return Semantics(
      checked: _selected,
      enabled: isInteractive,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        onTap: isInteractive ? () => onChanged?.call(value) : null,
        child: Focus(
          focusNode: focusNode,
          autofocus: autofocus,
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                width: dimensions.circleSize,
                height: dimensions.circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getBorderColor(colors, isFocused),
                    width: isFocused ? 2 : 2,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeInOut,
                    width: _selected ? dimensions.dotSize : 0,
                    height: _selected ? dimensions.dotSize : 0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getDotColor(colors),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  _RadioDimensions _getDimensions() {
    return switch (size) {
      AppRadioSize.sm => _RadioDimensions(circleSize: 16, dotSize: 8),
      AppRadioSize.md => _RadioDimensions(circleSize: 20, dotSize: 10),
      AppRadioSize.lg => _RadioDimensions(circleSize: 24, dotSize: 12),
    };
  }

  Color _getBorderColor(ColorScheme colors, bool isFocused) {
    if (isFocused) {
      return activeColor ?? colors.primary;
    }
    if (hasError) {
      return colors.error;
    }
    if (!enabled) {
      return _selected
          ? (activeColor ?? colors.primary).withOpacity(0.5)
          : colors.outline.withOpacity(0.5);
    }
    if (_selected) {
      return activeColor ?? colors.primary;
    }
    return colors.outline;
  }

  Color _getDotColor(ColorScheme colors) {
    if (!enabled) {
      return (activeColor ?? colors.primary).withOpacity(0.5);
    }
    return activeColor ?? colors.primary;
  }
}

class _RadioDimensions {
  final double circleSize;
  final double dotSize;

  _RadioDimensions({required this.circleSize, required this.dotSize});
}
```

### AppRadioListTile Widget

```dart
class AppRadioListTile<T> extends StatelessWidget {
  const AppRadioListTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.secondary,
    this.enabled = true,
    this.hasError = false,
    this.radioSize = AppRadioSize.md,
    this.controlAffinity = ListTileControlAffinity.leading,
    this.contentPadding,
    this.dense = false,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? secondary;
  final bool enabled;
  final bool hasError;
  final AppRadioSize radioSize;
  final ListTileControlAffinity controlAffinity;
  final EdgeInsetsGeometry? contentPadding;
  final bool dense;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final radio = AppRadio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: enabled ? onChanged : null,
      size: radioSize,
      enabled: enabled,
      hasError: hasError,
    );

    return InkWell(
      onTap: enabled && onChanged != null
          ? () => onChanged?.call(value)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: contentPadding ??
            EdgeInsets.symmetric(
              horizontal: 16,
              vertical: dense ? 8 : 12,
            ),
        child: Row(
          children: [
            if (controlAffinity == ListTileControlAffinity.leading) ...[
              radio,
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
                      fontWeight: _selected ? FontWeight.w500 : null,
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
              radio,
            ],
          ],
        ),
      ),
    );
  }
}
```

### AppRadioGroup Widget

```dart
class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({
    super.key,
    required this.items,
    required this.groupValue,
    required this.onChanged,
    this.itemBuilder,
    this.subtitleBuilder,
    this.enabled = true,
    this.hasError = false,
    this.errorText,
    this.radioSize = AppRadioSize.md,
    this.spacing = 12,
    this.direction = Axis.vertical,
    this.controlAffinity = ListTileControlAffinity.leading,
  });

  final List<T> items;
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final Widget Function(T item)? itemBuilder;
  final Widget Function(T item)? subtitleBuilder;
  final bool enabled;
  final bool hasError;
  final String? errorText;
  final AppRadioSize radioSize;
  final double spacing;
  final Axis direction;
  final ListTileControlAffinity controlAffinity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final children = items.map((item) {
      return AppRadioListTile<T>(
        value: item,
        groupValue: groupValue,
        onChanged: enabled ? onChanged : null,
        title: itemBuilder?.call(item) ?? Text(item.toString()),
        subtitle: subtitleBuilder?.call(item),
        radioSize: radioSize,
        enabled: enabled,
        hasError: hasError,
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: controlAffinity,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (direction == Axis.horizontal)
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: children,
          )
        else
          ...children.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < children.length - 1 ? spacing : 0,
              ),
              child: child,
            );
          }),
        if (hasError && errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
```

### AppRadioCard Widget

```dart
class AppRadioCard<T> extends StatelessWidget {
  const AppRadioCard({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.child,
    this.enabled = true,
    this.padding,
    this.borderRadius,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget child;
  final bool enabled;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return GestureDetector(
      onTap: enabled && onChanged != null
          ? () => onChanged?.call(value)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selected
              ? colors.primary.withOpacity(0.08)
              : colors.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          border: Border.all(
            color: _selected ? colors.primary : colors.outline,
            width: _selected ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Row(
            children: [
              Expanded(child: child),
              const SizedBox(width: 12),
              AppRadio<T>(
                value: value,
                groupValue: groupValue,
                onChanged: enabled ? onChanged : null,
                enabled: enabled,
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

## Usage Examples

### Basic Radio Group

```dart
String? _selectedGender;

AppRadioGroup<String>(
  items: ['Male', 'Female', 'Other', 'Prefer not to say'],
  groupValue: _selectedGender,
  onChanged: (value) {
    setState(() => _selectedGender = value);
  },
)
```

### Different Sizes

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    AppRadio<int>(
      value: 1,
      groupValue: 1,
      onChanged: (_) {},
      size: AppRadioSize.sm,
    ),
    AppRadio<int>(
      value: 1,
      groupValue: 1,
      onChanged: (_) {},
      size: AppRadioSize.md,
    ),
    AppRadio<int>(
      value: 1,
      groupValue: 1,
      onChanged: (_) {},
      size: AppRadioSize.lg,
    ),
  ],
)
```

### Radio List Tile with Descriptions

```dart
enum WorkoutFrequency { beginner, intermediate, advanced }

WorkoutFrequency? _frequency;

Column(
  children: [
    AppRadioListTile<WorkoutFrequency>(
      value: WorkoutFrequency.beginner,
      groupValue: _frequency,
      onChanged: (value) => setState(() => _frequency = value),
      title: const Text('Beginner'),
      subtitle: const Text('1-2 workouts per week'),
      leading: const Icon(Icons.fitness_center),
    ),
    AppRadioListTile<WorkoutFrequency>(
      value: WorkoutFrequency.intermediate,
      groupValue: _frequency,
      onChanged: (value) => setState(() => _frequency = value),
      title: const Text('Intermediate'),
      subtitle: const Text('3-4 workouts per week'),
      leading: const Icon(Icons.fitness_center),
    ),
    AppRadioListTile<WorkoutFrequency>(
      value: WorkoutFrequency.advanced,
      groupValue: _frequency,
      onChanged: (value) => setState(() => _frequency = value),
      title: const Text('Advanced'),
      subtitle: const Text('5+ workouts per week'),
      leading: const Icon(Icons.fitness_center),
    ),
  ],
)
```

### Radio Cards (Plan Selection)

```dart
enum Plan { free, pro, enterprise }

Plan? _selectedPlan;

Column(
  children: [
    AppRadioCard<Plan>(
      value: Plan.free,
      groupValue: _selectedPlan,
      onChanged: (value) => setState(() => _selectedPlan = value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Free', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Basic features for getting started',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '\$0/month',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    AppRadioCard<Plan>(
      value: Plan.pro,
      groupValue: _selectedPlan,
      onChanged: (value) => setState(() => _selectedPlan = value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Pro', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Popular',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Advanced features for serious athletes',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '\$9.99/month',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ],
)
```

### With Error State

```dart
AppRadioGroup<String>(
  items: ['Option 1', 'Option 2', 'Option 3'],
  groupValue: _selectedOption,
  onChanged: (value) => setState(() => _selectedOption = value),
  hasError: _selectedOption == null && _submitted,
  errorText: _selectedOption == null && _submitted
      ? 'Please select an option'
      : null,
)
```

### Trailing Radio (Selection List)

```dart
AppRadioListTile<String>(
  value: 'metric',
  groupValue: _unitSystem,
  onChanged: (value) => setState(() => _unitSystem = value),
  title: const Text('Metric'),
  subtitle: const Text('kg, cm'),
  controlAffinity: ListTileControlAffinity.trailing,
)
```

### Horizontal Layout

```dart
AppRadioGroup<String>(
  items: ['S', 'M', 'L', 'XL'],
  groupValue: _size,
  onChanged: (value) => setState(() => _size = value),
  direction: Axis.horizontal,
  spacing: 16,
)
```

### Disabled State

```dart
AppRadioListTile<String>(
  value: 'premium',
  groupValue: _tier,
  onChanged: null,
  enabled: false,
  title: const Text('Premium'),
  subtitle: const Text('Upgrade to unlock'),
)
```

---

## Accessibility

### Semantic Properties

- Uses `Semantics` with `checked` and `inMutuallyExclusiveGroup`
- Screen readers announce selection state
- Indicates mutually exclusive nature

### Keyboard Navigation

- Focusable via Tab key within group
- Arrow keys to navigate between options
- Space or Enter to select
- Clear focus ring indicator

### Touch Targets

- Minimum touch target: 44×44px
- `AppRadioListTile` expands tap area to full row

### Best Practices

```dart
// ✅ Group related radios with clear labels
AppRadioGroup<String>(
  items: ['Daily', 'Weekly', 'Monthly'],
  ...
)

// ✅ Provide descriptions for complex options
AppRadioListTile(
  title: const Text('Push Notifications'),
  subtitle: const Text('Receive real-time updates'),
  ...
)

// ❌ Avoid standalone radio without group context
AppRadio(value: 'a', groupValue: 'a', onChanged: (_) {})
```

---

## When to Use

| Use Radio | Use Checkbox | Use Switch |
|-----------|--------------|------------|
| Single selection required | Multiple selections | Immediate toggle |
| Visible options (2-7) | Any number of options | Binary on/off |
| Mutually exclusive | Independent options | Settings/preferences |
| Form submission | Form submission | No submission needed |

---

## Related Components

- [AppCheckbox](./CHECKBOX.md) - For multiple selections
- [AppSwitch](./SWITCH.md) - For immediate toggle actions
- [AppListTile](./LIST_TILE.md) - Base list item component

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-23 | Initial documentation |
