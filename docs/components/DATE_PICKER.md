# AppDatePicker

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Date selection component for choosing single dates, date ranges, or date/time combinations. Designed for workout scheduling, progress tracking, and goal setting.

---

## Variants

| Component | Purpose |
|-----------|---------|
| `AppDatePicker` | Single date selection |
| `AppDateRangePicker` | Date range selection (start/end) |
| `AppDateTimePicker` | Combined date and time selection |
| `AppDateField` | Text field that opens date picker |
| `AppDateChip` | Compact date display with tap to edit |

---

## Specifications

### Picker Modes

| Mode | Display | Usage |
|------|---------|-------|
| `calendar` | Full calendar grid | Default, date browsing |
| `input` | Text input field | Quick entry, known dates |
| `calendarAndInput` | Both options | Flexible selection |

### Date Field Variants

| Variant | Style | Usage |
|---------|-------|-------|
| `outlined` | Border around field | Default form style |
| `filled` | Filled background | Dense forms |
| `underlined` | Bottom border only | Minimal style |

### Calendar Styling

- **Header background**: `surface1`
- **Selected date**: `primary` background
- **Today indicator**: `primary` text, no fill
- **Range fill**: `primary` at 12% opacity
- **Disabled dates**: `mutedForeground` at 50%
- **Weekend days**: Same as weekdays (no distinction)
- **Border radius**: `radiusLg` (16px)

### States

| State | Visual |
|-------|--------|
| Default | Standard appearance |
| Selected | Primary color fill |
| Today | Primary text, outlined |
| Disabled | Reduced opacity |
| Range start/end | Rounded primary pill |
| Range middle | Primary fill with 12% opacity |
| Hovered | Surface3 background |
| Focused | Ring indicator |

### Animation

- **Picker entrance**: Fade + scale from 0.95, `durationNormal`
- **Month transition**: Slide left/right, `durationSlow`
- **Selection feedback**: Scale pulse, `durationFast`

---

## Implementation

```dart
// lib/widgets/app_date_picker.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Date picker mode options
enum AppDatePickerMode {
  /// Calendar view only
  calendar,
  
  /// Text input only
  input,
  
  /// Both calendar and input available
  calendarAndInput,
}

/// Date field styling variants
enum AppDateFieldVariant { outlined, filled, underlined }

/// Shows a styled date picker dialog
///
/// Returns the selected date or null if cancelled.
///
/// Example:
/// ```dart
/// final date = await showAppDatePicker(
///   context: context,
///   initialDate: DateTime.now(),
///   firstDate: DateTime(2020),
///   lastDate: DateTime(2030),
/// );
/// ```
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  AppDatePickerMode mode = AppDatePickerMode.calendar,
  String? helpText,
  String? cancelText,
  String? confirmText,
  SelectableDayPredicate? selectableDayPredicate,
});

/// Shows a styled date range picker dialog
///
/// Returns the selected date range or null if cancelled.
///
/// Example:
/// ```dart
/// final range = await showAppDateRangePicker(
///   context: context,
///   firstDate: DateTime(2020),
///   lastDate: DateTime(2030),
/// );
/// ```
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  String? saveText,
  SelectableDayPredicate? selectableDayPredicate,
});

/// A text field that opens a date picker when tapped
///
/// Example:
/// ```dart
/// AppDateField(
///   label: 'Start Date',
///   value: _startDate,
///   onChanged: (date) => setState(() => _startDate = date),
/// )
/// ```
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.variant = AppDateFieldVariant.outlined,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.dateFormat,
    this.pickerMode = AppDatePickerMode.calendar,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? label;
  final String? hint;
  final AppDateFieldVariant variant;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final String? dateFormat;
  final AppDatePickerMode pickerMode;
}

/// A compact date chip that shows selected date
///
/// Example:
/// ```dart
/// AppDateChip(
///   value: _selectedDate,
///   onTap: () => _pickDate(),
///   format: 'MMM d, yyyy',
/// )
/// ```
class AppDateChip extends StatelessWidget {
  const AppDateChip({
    super.key,
    this.value,
    this.onTap,
    this.placeholder = 'Select date',
    this.format,
    this.showIcon = true,
    this.enabled = true,
  });

  final DateTime? value;
  final VoidCallback? onTap;
  final String placeholder;
  final String? format;
  final bool showIcon;
  final bool enabled;
}
```

---

## Usage Examples

### Basic Date Picker

```dart
DateTime? _selectedDate;

Future<void> _pickDate() async {
  final date = await showAppDatePicker(
    context: context,
    initialDate: _selectedDate ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
  );
  
  if (date != null) {
    setState(() => _selectedDate = date);
  }
}

// Trigger button
AppButton(
  label: _selectedDate?.toString() ?? 'Select Date',
  onPressed: _pickDate,
)
```

### Date Field in Form

```dart
AppDateField(
  label: 'Workout Date',
  hint: 'Choose a date',
  value: _workoutDate,
  onChanged: (date) => setState(() => _workoutDate = date),
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(Duration(days: 365)),
  prefixIcon: Icons.calendar_today,
)
```

### Date Range Selection

```dart
DateTimeRange? _dateRange;

Future<void> _pickDateRange() async {
  final range = await showAppDateRangePicker(
    context: context,
    initialDateRange: _dateRange,
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
    helpText: 'Select workout period',
  );
  
  if (range != null) {
    setState(() => _dateRange = range);
  }
}
```

### With Selectable Days

```dart
// Only allow weekdays
final date = await showAppDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
  selectableDayPredicate: (day) {
    return day.weekday != DateTime.saturday && 
           day.weekday != DateTime.sunday;
  },
);
```

### Date Chip in Header

```dart
Row(
  children: [
    Text('Workouts for', style: AppTextStyles.bodyMedium),
    SizedBox(width: AppTheme.spacing2),
    AppDateChip(
      value: _selectedDate,
      onTap: () => _pickDate(),
      format: 'EEEE, MMM d',
    ),
  ],
)
```

### Date Field Variants

```dart
// Outlined (default)
AppDateField(
  label: 'Start Date',
  value: _date,
  onChanged: (d) => setState(() => _date = d),
  variant: AppDateFieldVariant.outlined,
)

// Filled
AppDateField(
  label: 'Start Date',
  value: _date,
  onChanged: (d) => setState(() => _date = d),
  variant: AppDateFieldVariant.filled,
)

// Underlined
AppDateField(
  label: 'Start Date',
  value: _date,
  onChanged: (d) => setState(() => _date = d),
  variant: AppDateFieldVariant.underlined,
)
```

### With Validation

```dart
AppDateField(
  label: 'Target Date',
  value: _targetDate,
  onChanged: (date) {
    setState(() {
      _targetDate = date;
      _validateDate();
    });
  },
  errorText: _dateError,
  helperText: 'Must be within 30 days',
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(Duration(days: 30)),
)

void _validateDate() {
  if (_targetDate == null) {
    _dateError = 'Please select a date';
  } else if (_targetDate!.isBefore(DateTime.now())) {
    _dateError = 'Date must be in the future';
  } else {
    _dateError = null;
  }
}
```

### Date Time Picker

```dart
DateTime? _appointmentTime;

Future<void> _pickDateTime() async {
  // Pick date first
  final date = await showAppDatePicker(
    context: context,
    initialDate: _appointmentTime ?? DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(Duration(days: 365)),
  );
  
  if (date == null) return;
  
  // Then pick time
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(_appointmentTime ?? DateTime.now()),
  );
  
  if (time == null) return;
  
  setState(() {
    _appointmentTime = DateTime(
      date.year, date.month, date.day,
      time.hour, time.minute,
    );
  });
}
```

---

## Date Formatting

The component uses standard date formatting patterns:

| Pattern | Example | Usage |
|---------|---------|-------|
| `'MMM d, yyyy'` | Jan 23, 2026 | Default display |
| `'EEEE, MMM d'` | Thursday, Jan 23 | Day emphasis |
| `'MM/dd/yyyy'` | 01/23/2026 | Compact numeric |
| `'yyyy-MM-dd'` | 2026-01-23 | ISO format |
| `'d MMM'` | 23 Jan | Minimal |

```dart
// Using intl package for formatting
import 'package:intl/intl.dart';

AppDateField(
  value: _date,
  onChanged: (d) => setState(() => _date = d),
  dateFormat: 'EEEE, MMMM d, yyyy', // Thursday, January 23, 2026
)
```

---

## Accessibility

### Keyboard Navigation

- **Tab**: Move between picker elements
- **Arrow keys**: Navigate calendar grid
- **Enter/Space**: Select focused date
- **Escape**: Close picker

### Screen Reader Support

```dart
AppDateField(
  label: 'Workout Date',
  value: _date,
  onChanged: (d) => setState(() => _date = d),
  // Semantics automatically provided
)
```

### Considerations

- Always provide meaningful `label` text
- Use `helpText` to explain date constraints
- Error messages should be descriptive
- Ensure sufficient touch targets (44x44px minimum)
- Support for different date formats and locales

---

## Best Practices

1. **Set reasonable date bounds** - Don't allow dates that don't make sense
2. **Show current selection clearly** - User should always know what's selected
3. **Use appropriate mode** - Calendar for browsing, input for known dates
4. **Validate on change** - Provide immediate feedback
5. **Consider locale** - Format dates appropriately for the user's region
6. **Disable invalid dates** - Use `selectableDayPredicate` to prevent bad selections

---

## Related Components

- [AppTextField](./TEXT_FIELD.md) - Base text input component
- [AppDialog](./DIALOG.md) - Modal dialog patterns
- [AppBottomSheet](./BOTTOM_SHEET.md) - Alternative picker presentation
