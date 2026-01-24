# AppSlider

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Input control for selecting a value or range from a continuous or discrete set. Ideal for settings like volume, weight, intensity, or filtering ranges.

---

## Variants

| Component | Purpose |
|-----------|---------|
| `AppSlider` | Single value selection |
| `AppRangeSlider` | Range selection (min/max) |
| `AppLabeledSlider` | Slider with header label and value display |

---

## Specifications

### Size Variants

| Size | Track Height | Thumb Radius | Overlay Radius |
|------|-------------|--------------|----------------|
| `sm` | 2px | 8px | 16px |
| `md` | 4px | 10px | 20px |
| `lg` | 6px | 12px | 24px |

### Styling

- **Active track**: `primary` color
- **Inactive track**: `secondary` color
- **Thumb**: Matches active color, 2px elevation
- **Overlay**: Primary at 12% opacity
- **Value indicator**: `surface3` background, `foreground` text
- **Thumb pressed elevation**: 4px

### States

| State | Behavior |
|-------|----------|
| Default | Full opacity colors |
| Dragging | Elevated thumb, value label visible |
| Disabled | 50% opacity, non-interactive |
| Focused | Overlay visible around thumb |

---

## Implementation

```dart
// lib/widgets/app_slider.dart

enum AppSliderSize { sm, md, lg }

class AppSlider extends StatefulWidget {
  const AppSlider({
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.size = AppSliderSize.md,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.showLabel = false,
    this.labelBuilder,
    this.onChangeStart,
    this.onChangeEnd,
    this.disabled = false,
    this.hapticFeedback = true,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  // ... additional properties
}

class AppRangeSlider extends StatefulWidget {
  const AppRangeSlider({
    required this.values,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    // ... similar properties
  });

  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
}

class AppLabeledSlider extends StatelessWidget {
  const AppLabeledSlider({
    required this.value,
    required this.onChanged,
    required this.label,
    this.valueLabel,
    this.minLabel,
    this.maxLabel,
    // ... additional properties
  });
}
```

---

## Usage Examples

### Basic Slider

```dart
double _volume = 0.5;

AppSlider(
  value: _volume,
  onChanged: (value) => setState(() => _volume = value),
)
```

### Slider with Divisions

```dart
double _rating = 3;

AppSlider(
  value: _rating,
  onChanged: (value) => setState(() => _rating = value),
  min: 1,
  max: 5,
  divisions: 4,
  showLabel: true,
)
```

### Custom Label Builder

```dart
double _weight = 150;

AppSlider(
  value: _weight,
  onChanged: (value) => setState(() => _weight = value),
  min: 50,
  max: 300,
  divisions: 250,
  showLabel: true,
  labelBuilder: (value) => '${value.toInt()} lbs',
)
```

### Range Slider

```dart
RangeValues _priceRange = RangeValues(20, 80);

AppRangeSlider(
  values: _priceRange,
  onChanged: (values) => setState(() => _priceRange = values),
  min: 0,
  max: 100,
  divisions: 20,
  showLabels: true,
  labelBuilder: (value) => '\$${value.toInt()}',
)
```

### Labeled Slider

```dart
double _intensity = 0.7;

AppLabeledSlider(
  value: _intensity,
  onChanged: (value) => setState(() => _intensity = value),
  label: 'Workout Intensity',
  valueLabel: '${(_intensity * 100).toInt()}%',
  min: 0,
  max: 1,
  divisions: 10,
  minLabel: 'Easy',
  maxLabel: 'Hard',
)
```

### Different Sizes

```dart
// Small - subtle UI
AppSlider(
  value: _value,
  onChanged: (v) => setState(() => _value = v),
  size: AppSliderSize.sm,
)

// Large - primary input
AppSlider(
  value: _value,
  onChanged: (v) => setState(() => _value = v),
  size: AppSliderSize.lg,
)
```

### Custom Colors

```dart
AppSlider(
  value: _progress,
  onChanged: (value) => setState(() => _progress = value),
  activeColor: AppColors.success,
  inactiveColor: AppColors.successLight,
)
```

### With Change Callbacks

```dart
AppSlider(
  value: _volume,
  onChanged: (value) => setState(() => _volume = value),
  onChangeStart: (value) {
    // User started dragging
    _showVolumeOverlay();
  },
  onChangeEnd: (value) {
    // User finished dragging
    _hideVolumeOverlay();
    _saveVolumeSetting(value);
  },
)
```

### Disabled State

```dart
AppSlider(
  value: _lockedValue,
  onChanged: null, // or disabled: true
  disabled: true,
)
```

### Without Haptic Feedback

```dart
AppSlider(
  value: _value,
  onChanged: (v) => setState(() => _value = v),
  divisions: 10,
  hapticFeedback: false,
)
```

### Weight Selector Example

```dart
class WeightSelector extends StatefulWidget {
  @override
  State<WeightSelector> createState() => _WeightSelectorState();
}

class _WeightSelectorState extends State<WeightSelector> {
  double _weight = 135;

  @override
  Widget build(BuildContext context) {
    return AppLabeledSlider(
      value: _weight,
      onChanged: (value) => setState(() => _weight = value),
      label: 'Target Weight',
      valueLabel: '${_weight.toInt()} lbs',
      min: 50,
      max: 400,
      divisions: 350,
      minLabel: '50 lbs',
      maxLabel: '400 lbs',
      size: AppSliderSize.lg,
    );
  }
}
```

### Filter Range Example

```dart
class PriceFilter extends StatefulWidget {
  @override
  State<PriceFilter> createState() => _PriceFilterState();
}

class _PriceFilterState extends State<PriceFilter> {
  RangeValues _range = RangeValues(0, 100);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price Range'),
        SizedBox(height: 8),
        AppRangeSlider(
          values: _range,
          onChanged: (values) => setState(() => _range = values),
          min: 0,
          max: 200,
          divisions: 40,
          showLabels: true,
          labelBuilder: (v) => '\$${v.toInt()}',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$0'),
            Text('\$200'),
          ],
        ),
      ],
    );
  }
}
```

---

## Accessibility

- Slider value is announced by screen readers
- Keyboard navigation supported (arrow keys)
- Haptic feedback for division changes
- Clear visual feedback for current value
- Labels provide context for min/max values
- Thumb meets minimum touch target (44x44px via overlay)

---

## Best Practices

1. **Use divisions for discrete values** — Helps users select precise values
2. **Show value labels** — Users need to see the current value
3. **Provide min/max context** — Use `minLabel`/`maxLabel` or show range
4. **Use appropriate size** — `lg` for primary inputs, `sm` for compact UI
5. **Consider step size** — Match divisions to meaningful increments
6. **Add haptic feedback** — Helps users feel divisions (enabled by default)

---

## When to Use

| Scenario | Use Slider? | Alternative |
|----------|-------------|-------------|
| Volume control | ✅ Yes | — |
| Filter range | ✅ Yes (Range) | — |
| Rating 1-5 | ⚠️ Maybe | Radio buttons |
| Precise number | ❌ No | TextField |
| On/Off toggle | ❌ No | Switch |
| Multiple choice | ❌ No | Checkbox/Radio |

---

## Related Components

- [AppTextField](./TEXT_FIELD.md) — For precise numeric input
- [AppSwitch](./SWITCH.md) — For binary on/off states
- [AppProgress](./PROGRESS.md) — For display-only progress
