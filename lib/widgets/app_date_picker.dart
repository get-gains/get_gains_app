// lib/widgets/app_date_picker.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_text_styles.dart';

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
enum AppDateFieldVariant {
  /// Border around field
  outlined,

  /// Filled background
  filled,

  /// Bottom border only
  underlined,
}

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
}) async {
  final DatePickerEntryMode entryMode;
  switch (mode) {
    case AppDatePickerMode.calendar:
      entryMode = DatePickerEntryMode.calendarOnly;
      break;
    case AppDatePickerMode.input:
      entryMode = DatePickerEntryMode.inputOnly;
      break;
    case AppDatePickerMode.calendarAndInput:
      entryMode = DatePickerEntryMode.calendar;
      break;
  }

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    currentDate: currentDate,
    initialEntryMode: entryMode,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    selectableDayPredicate: selectableDayPredicate,
    builder: (context, child) {
      return _AppDatePickerTheme(child: child!);
    },
  );
}

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
}) async {
  return showDateRangePicker(
    context: context,
    initialDateRange: initialDateRange,
    firstDate: firstDate,
    lastDate: lastDate,
    currentDate: currentDate,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    saveText: saveText,
    builder: (context, child) {
      return _AppDatePickerTheme(child: child!);
    },
  );
}

/// Theme wrapper for date pickers
class _AppDatePickerTheme extends StatelessWidget {
  const _AppDatePickerTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: AppColors.primaryDark,
            onPrimary: AppColors.primaryForegroundDark,
            surface: AppColors.surface1Dark,
            onSurface: AppColors.foregroundDark,
            surfaceContainerHighest: AppColors.surface2Dark,
            outline: AppColors.borderDark,
          )
        : ColorScheme.light(
            primary: AppColors.primaryLight,
            onPrimary: AppColors.primaryForegroundLight,
            surface: AppColors.surface1Light,
            onSurface: AppColors.foregroundLight,
            surfaceContainerHighest: AppColors.surface2Light,
            outline: AppColors.borderLight,
          );

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: colorScheme,
        datePickerTheme: DatePickerThemeData(
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          headerBackgroundColor: isDark
              ? AppColors.surface1Dark
              : AppColors.surface1Light,
          headerForegroundColor: isDark
              ? AppColors.foregroundDark
              : AppColors.foregroundLight,
          dayStyle: AppTextStyles.bodyMedium,
          weekdayStyle: AppTextStyles.labelSmall.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
          yearStyle: AppTextStyles.bodyMedium,
          rangePickerHeaderHeadlineStyle: AppTextStyles.headlineSmall,
          rangeSelectionBackgroundColor:
              (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withOpacity(0.12),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLg),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? AppColors.primaryDark : AppColors.primaryLight;
            }
            return null;
          }),
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark
                  ? AppColors.primaryForegroundDark
                  : AppColors.primaryForegroundLight;
            }
            if (states.contains(WidgetState.disabled)) {
              return (isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight)
                  .withOpacity(0.5);
            }
            return isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight;
          }),
          todayBorder: BorderSide(
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            width: 1,
          ),
          todayForegroundColor: WidgetStateProperty.all(
            isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
      ),
      child: child,
    );
  }
}

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
    this.selectableDayPredicate,
  });

  /// Currently selected date
  final DateTime? value;

  /// Called when a date is selected
  final ValueChanged<DateTime?> onChanged;

  /// Label text above the field
  final String? label;

  /// Hint text when no date is selected
  final String? hint;

  /// Visual variant of the field
  final AppDateFieldVariant variant;

  /// Earliest selectable date
  final DateTime? firstDate;

  /// Latest selectable date
  final DateTime? lastDate;

  /// Whether the field is interactive
  final bool enabled;

  /// Error message to display
  final String? errorText;

  /// Helper text below the field
  final String? helperText;

  /// Icon shown at the start of the field
  final IconData? prefixIcon;

  /// Date format pattern (e.g., 'MMM d, yyyy')
  final String? dateFormat;

  /// Mode of the date picker
  final AppDatePickerMode pickerMode;

  /// Predicate to determine which days are selectable
  final SelectableDayPredicate? selectableDayPredicate;

  String _formatDate(DateTime date) {
    final pattern = dateFormat ?? 'MMM d, yyyy';
    return DateFormat(pattern).format(date);
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showAppDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      mode: pickerMode,
      selectableDayPredicate: selectableDayPredicate,
    );

    if (date != null) {
      onChanged(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null && errorText!.isNotEmpty;

    final fillColor = _getFillColor(isDark);
    final borderColor = _getBorderColor(isDark, hasError);
    final textColor = isDark
        ? AppColors.foregroundDark
        : AppColors.foregroundLight;
    final hintColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final iconColor = prefixIcon != null ? hintColor : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: hasError ? AppColors.error : textColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
        ],
        GestureDetector(
          onTap: enabled ? () => _pickDate(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing4,
              vertical: AppTheme.spacing3,
            ),
            decoration: _getDecoration(
              isDark,
              hasError,
              fillColor,
              borderColor,
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, size: 20, color: iconColor),
                  const SizedBox(width: AppTheme.spacing3),
                ],
                Expanded(
                  child: Text(
                    value != null
                        ? _formatDate(value!)
                        : (hint ?? 'Select date'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: value != null ? textColor : hintColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: enabled ? hintColor : hintColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing1),
          Text(
            errorText!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: AppTheme.spacing1),
          Text(
            helperText!,
            style: AppTextStyles.bodySmall.copyWith(color: hintColor),
          ),
        ],
      ],
    );
  }

  Color _getFillColor(bool isDark) {
    switch (variant) {
      case AppDateFieldVariant.outlined:
        return Colors.transparent;
      case AppDateFieldVariant.filled:
        return isDark ? AppColors.inputDark : AppColors.inputLight;
      case AppDateFieldVariant.underlined:
        return Colors.transparent;
    }
  }

  Color _getBorderColor(bool isDark, bool hasError) {
    if (hasError) return AppColors.error;
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  BoxDecoration _getDecoration(
    bool isDark,
    bool hasError,
    Color fillColor,
    Color borderColor,
  ) {
    switch (variant) {
      case AppDateFieldVariant.outlined:
        return BoxDecoration(
          color: fillColor,
          border: Border.all(color: borderColor),
          borderRadius: AppTheme.borderRadiusMd,
        );
      case AppDateFieldVariant.filled:
        return BoxDecoration(
          color: fillColor,
          borderRadius: AppTheme.borderRadiusMd,
          border: hasError ? Border.all(color: borderColor) : null,
        );
      case AppDateFieldVariant.underlined:
        return BoxDecoration(
          color: fillColor,
          border: Border(bottom: BorderSide(color: borderColor)),
        );
    }
  }
}

/// A compact date chip that shows selected date
///
/// Displays a date in a chip format with optional edit capability.
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
    this.selected = false,
  });

  /// Currently selected date
  final DateTime? value;

  /// Called when the chip is tapped
  final VoidCallback? onTap;

  /// Text shown when no date is selected
  final String placeholder;

  /// Date format pattern
  final String? format;

  /// Whether to show calendar icon
  final bool showIcon;

  /// Whether the chip is interactive
  final bool enabled;

  /// Whether the chip appears selected
  final bool selected;

  String _formatDate(DateTime date) {
    final pattern = format ?? 'MMM d, yyyy';
    return DateFormat(pattern).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = selected
        ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
        : (isDark ? AppColors.secondaryDark : AppColors.secondaryLight);
    final foregroundColor = selected
        ? (isDark
              ? AppColors.primaryForegroundDark
              : AppColors.primaryForegroundLight)
        : (isDark ? AppColors.foregroundDark : AppColors.foregroundLight);
    final mutedColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing3,
          vertical: AppTheme.spacing2,
        ),
        decoration: BoxDecoration(
          color: enabled ? backgroundColor : backgroundColor.withOpacity(0.5),
          borderRadius: AppTheme.borderRadiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: enabled
                    ? (value != null ? foregroundColor : mutedColor)
                    : mutedColor.withOpacity(0.5),
              ),
              const SizedBox(width: AppTheme.spacing2),
            ],
            Text(
              value != null ? _formatDate(value!) : placeholder,
              style: AppTextStyles.labelMedium.copyWith(
                color: enabled
                    ? (value != null ? foregroundColor : mutedColor)
                    : mutedColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A date range display chip
///
/// Shows a date range in compact format.
class AppDateRangeChip extends StatelessWidget {
  const AppDateRangeChip({
    super.key,
    this.startDate,
    this.endDate,
    this.onTap,
    this.placeholder = 'Select dates',
    this.format,
    this.showIcon = true,
    this.enabled = true,
  });

  /// Start date of the range
  final DateTime? startDate;

  /// End date of the range
  final DateTime? endDate;

  /// Called when the chip is tapped
  final VoidCallback? onTap;

  /// Text shown when no dates are selected
  final String placeholder;

  /// Date format pattern
  final String? format;

  /// Whether to show calendar icon
  final bool showIcon;

  /// Whether the chip is interactive
  final bool enabled;

  String _formatDate(DateTime date) {
    final pattern = format ?? 'MMM d';
    return DateFormat(pattern).format(date);
  }

  String _getDisplayText() {
    if (startDate == null && endDate == null) {
      return placeholder;
    }
    if (startDate != null && endDate != null) {
      return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
    }
    if (startDate != null) {
      return 'From ${_formatDate(startDate!)}';
    }
    return 'Until ${_formatDate(endDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = startDate != null || endDate != null;

    final backgroundColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;
    final foregroundColor = isDark
        ? AppColors.foregroundDark
        : AppColors.foregroundLight;
    final mutedColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing3,
          vertical: AppTheme.spacing2,
        ),
        decoration: BoxDecoration(
          color: enabled ? backgroundColor : backgroundColor.withOpacity(0.5),
          borderRadius: AppTheme.borderRadiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                Icons.date_range_outlined,
                size: 16,
                color: enabled
                    ? (hasValue ? foregroundColor : mutedColor)
                    : mutedColor.withOpacity(0.5),
              ),
              const SizedBox(width: AppTheme.spacing2),
            ],
            Text(
              _getDisplayText(),
              style: AppTextStyles.labelMedium.copyWith(
                color: enabled
                    ? (hasValue ? foregroundColor : mutedColor)
                    : mutedColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
