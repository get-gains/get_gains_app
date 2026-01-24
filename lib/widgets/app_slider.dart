// lib/widgets/app_slider.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Slider size options
enum AppSliderSize {
  /// Small (2px track, 16px thumb)
  sm,

  /// Medium (4px track, 20px thumb) - default
  md,

  /// Large (6px track, 24px thumb)
  lg,
}

/// A customizable slider component following the design system.
///
/// Example usage:
/// ```dart
/// AppSlider(
///   value: _volume,
///   onChanged: (value) => setState(() => _volume = value),
///   min: 0,
///   max: 100,
/// )
///
/// AppSlider(
///   value: _weight,
///   onChanged: (value) => setState(() => _weight = value),
///   min: 0,
///   max: 500,
///   divisions: 100,
///   showLabel: true,
///   labelBuilder: (value) => '${value.toInt()} lbs',
/// )
/// ```
class AppSlider extends StatefulWidget {
  const AppSlider({
    super.key,
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

  /// Current value
  final double value;

  /// Called when value changes
  final ValueChanged<double>? onChanged;

  /// Minimum value
  final double min;

  /// Maximum value
  final double max;

  /// Number of discrete divisions (null for continuous)
  final int? divisions;

  /// Size variant
  final AppSliderSize size;

  /// Active track color (filled portion)
  final Color? activeColor;

  /// Inactive track color (unfilled portion)
  final Color? inactiveColor;

  /// Thumb color
  final Color? thumbColor;

  /// Whether to show value label above thumb
  final bool showLabel;

  /// Custom label builder
  final String Function(double value)? labelBuilder;

  /// Called when drag starts
  final ValueChanged<double>? onChangeStart;

  /// Called when drag ends
  final ValueChanged<double>? onChangeEnd;

  /// Whether the slider is disabled
  final bool disabled;

  /// Whether to provide haptic feedback on divisions
  final bool hapticFeedback;

  @override
  State<AppSlider> createState() => _AppSliderState();
}

class _AppSliderState extends State<AppSlider> {
  double? _lastHapticValue;

  double get _trackHeight {
    switch (widget.size) {
      case AppSliderSize.sm:
        return 2;
      case AppSliderSize.md:
        return 4;
      case AppSliderSize.lg:
        return 6;
    }
  }

  double get _thumbRadius {
    switch (widget.size) {
      case AppSliderSize.sm:
        return 8;
      case AppSliderSize.md:
        return 10;
      case AppSliderSize.lg:
        return 12;
    }
  }

  double get _overlayRadius {
    switch (widget.size) {
      case AppSliderSize.sm:
        return 16;
      case AppSliderSize.md:
        return 20;
      case AppSliderSize.lg:
        return 24;
    }
  }

  void _handleChange(double value) {
    if (widget.disabled) return;

    // Haptic feedback on divisions
    if (widget.hapticFeedback && widget.divisions != null) {
      if (_lastHapticValue != value) {
        HapticFeedback.selectionClick();
        _lastHapticValue = value;
      }
    }

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor =
        widget.activeColor ??
        (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final inactiveColor =
        widget.inactiveColor ??
        (isDark ? AppColors.secondaryDark : AppColors.secondaryLight);
    final thumbColor = widget.thumbColor ?? activeColor;

    final effectiveActiveColor = widget.disabled
        ? activeColor.withOpacity(0.5)
        : activeColor;
    final effectiveInactiveColor = widget.disabled
        ? inactiveColor.withOpacity(0.5)
        : inactiveColor;
    final effectiveThumbColor = widget.disabled
        ? thumbColor.withOpacity(0.5)
        : thumbColor;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: _trackHeight,
        activeTrackColor: effectiveActiveColor,
        inactiveTrackColor: effectiveInactiveColor,
        thumbColor: effectiveThumbColor,
        overlayColor: activeColor.withOpacity(0.12),
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: _thumbRadius,
          elevation: 2,
          pressedElevation: 4,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: _overlayRadius),
        trackShape: const RoundedRectSliderTrackShape(),
        tickMarkShape: widget.divisions != null
            ? RoundSliderTickMarkShape(tickMarkRadius: _trackHeight / 2)
            : SliderTickMarkShape.noTickMark,
        activeTickMarkColor: effectiveActiveColor,
        inactiveTickMarkColor: effectiveInactiveColor,
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        valueIndicatorColor: isDark
            ? AppColors.surface3Dark
            : AppColors.cardLight,
        valueIndicatorTextStyle: AppTextStyles.labelMedium.copyWith(
          color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
        ),
        showValueIndicator: widget.showLabel
            ? ShowValueIndicator.always
            : ShowValueIndicator.never,
      ),
      child: Slider(
        value: widget.value,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        label: widget.showLabel
            ? (widget.labelBuilder?.call(widget.value) ??
                  widget.value.toStringAsFixed(
                    widget.divisions != null ? 0 : 1,
                  ))
            : null,
        onChanged: widget.disabled ? null : _handleChange,
        onChangeStart: widget.onChangeStart,
        onChangeEnd: widget.onChangeEnd,
      ),
    );
  }
}

/// A range slider for selecting a value range.
///
/// Example usage:
/// ```dart
/// AppRangeSlider(
///   values: RangeValues(_minWeight, _maxWeight),
///   onChanged: (values) => setState(() {
///     _minWeight = values.start;
///     _maxWeight = values.end;
///   }),
///   min: 0,
///   max: 500,
///   divisions: 50,
///   showLabels: true,
///   labelBuilder: (value) => '${value.toInt()} lbs',
/// )
/// ```
class AppRangeSlider extends StatefulWidget {
  const AppRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.size = AppSliderSize.md,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.showLabels = false,
    this.labelBuilder,
    this.onChangeStart,
    this.onChangeEnd,
    this.disabled = false,
    this.hapticFeedback = true,
  });

  /// Current range values
  final RangeValues values;

  /// Called when values change
  final ValueChanged<RangeValues>? onChanged;

  /// Minimum value
  final double min;

  /// Maximum value
  final double max;

  /// Number of discrete divisions
  final int? divisions;

  /// Size variant
  final AppSliderSize size;

  /// Active track color
  final Color? activeColor;

  /// Inactive track color
  final Color? inactiveColor;

  /// Thumb color
  final Color? thumbColor;

  /// Whether to show value labels
  final bool showLabels;

  /// Custom label builder
  final String Function(double value)? labelBuilder;

  /// Called when drag starts
  final ValueChanged<RangeValues>? onChangeStart;

  /// Called when drag ends
  final ValueChanged<RangeValues>? onChangeEnd;

  /// Whether the slider is disabled
  final bool disabled;

  /// Whether to provide haptic feedback
  final bool hapticFeedback;

  @override
  State<AppRangeSlider> createState() => _AppRangeSliderState();
}

class _AppRangeSliderState extends State<AppRangeSlider> {
  RangeValues? _lastHapticValues;

  double get _trackHeight {
    switch (widget.size) {
      case AppSliderSize.sm:
        return 2;
      case AppSliderSize.md:
        return 4;
      case AppSliderSize.lg:
        return 6;
    }
  }

  double get _thumbRadius {
    switch (widget.size) {
      case AppSliderSize.sm:
        return 8;
      case AppSliderSize.md:
        return 10;
      case AppSliderSize.lg:
        return 12;
    }
  }

  double get _overlayRadius {
    switch (widget.size) {
      case AppSliderSize.sm:
        return 16;
      case AppSliderSize.md:
        return 20;
      case AppSliderSize.lg:
        return 24;
    }
  }

  void _handleChange(RangeValues values) {
    if (widget.disabled) return;

    if (widget.hapticFeedback && widget.divisions != null) {
      if (_lastHapticValues != values) {
        HapticFeedback.selectionClick();
        _lastHapticValues = values;
      }
    }

    widget.onChanged?.call(values);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor =
        widget.activeColor ??
        (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final inactiveColor =
        widget.inactiveColor ??
        (isDark ? AppColors.secondaryDark : AppColors.secondaryLight);
    final thumbColor = widget.thumbColor ?? activeColor;

    final effectiveActiveColor = widget.disabled
        ? activeColor.withOpacity(0.5)
        : activeColor;
    final effectiveInactiveColor = widget.disabled
        ? inactiveColor.withOpacity(0.5)
        : inactiveColor;
    final effectiveThumbColor = widget.disabled
        ? thumbColor.withOpacity(0.5)
        : thumbColor;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: _trackHeight,
        activeTrackColor: effectiveActiveColor,
        inactiveTrackColor: effectiveInactiveColor,
        thumbColor: effectiveThumbColor,
        overlayColor: activeColor.withOpacity(0.12),
        rangeThumbShape: RoundRangeSliderThumbShape(
          enabledThumbRadius: _thumbRadius,
          elevation: 2,
          pressedElevation: 4,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: _overlayRadius),
        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
        tickMarkShape: widget.divisions != null
            ? RoundSliderTickMarkShape(tickMarkRadius: _trackHeight / 2)
            : SliderTickMarkShape.noTickMark,
        activeTickMarkColor: effectiveActiveColor,
        inactiveTickMarkColor: effectiveInactiveColor,
        rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
        valueIndicatorColor: isDark
            ? AppColors.surface3Dark
            : AppColors.cardLight,
        valueIndicatorTextStyle: AppTextStyles.labelMedium.copyWith(
          color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
        ),
        showValueIndicator: widget.showLabels
            ? ShowValueIndicator.always
            : ShowValueIndicator.never,
      ),
      child: RangeSlider(
        values: widget.values,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        labels: widget.showLabels
            ? RangeLabels(
                widget.labelBuilder?.call(widget.values.start) ??
                    widget.values.start.toStringAsFixed(
                      widget.divisions != null ? 0 : 1,
                    ),
                widget.labelBuilder?.call(widget.values.end) ??
                    widget.values.end.toStringAsFixed(
                      widget.divisions != null ? 0 : 1,
                    ),
              )
            : null,
        onChanged: widget.disabled ? null : _handleChange,
        onChangeStart: widget.onChangeStart,
        onChangeEnd: widget.onChangeEnd,
      ),
    );
  }
}

/// A slider with labels displayed below/above the track.
///
/// Example usage:
/// ```dart
/// AppLabeledSlider(
///   value: _intensity,
///   onChanged: (value) => setState(() => _intensity = value),
///   label: 'Intensity',
///   valueLabel: '${(_intensity * 100).toInt()}%',
///   min: 0,
///   max: 1,
/// )
/// ```
class AppLabeledSlider extends StatelessWidget {
  const AppLabeledSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.valueLabel,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.size = AppSliderSize.md,
    this.activeColor,
    this.disabled = false,
    this.minLabel,
    this.maxLabel,
  });

  /// Current value
  final double value;

  /// Called when value changes
  final ValueChanged<double>? onChanged;

  /// Label displayed above the slider
  final String label;

  /// Value label displayed on the right
  final String? valueLabel;

  /// Minimum value
  final double min;

  /// Maximum value
  final double max;

  /// Number of divisions
  final int? divisions;

  /// Size variant
  final AppSliderSize size;

  /// Active track color
  final Color? activeColor;

  /// Whether disabled
  final bool disabled;

  /// Label for minimum value (shown below track)
  final String? minLabel;

  /// Label for maximum value (shown below track)
  final String? maxLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark
        ? AppColors.foregroundDark
        : AppColors.foregroundLight;
    final mutedColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: disabled ? mutedColor : textColor,
              ),
            ),
            if (valueLabel != null)
              Text(
                valueLabel!,
                style: AppTextStyles.titleSmall.copyWith(
                  color: disabled
                      ? mutedColor
                      : activeColor ??
                            (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight),
                  fontFamily: AppTextStyles.fontFamilyMono,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Slider
        AppSlider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          divisions: divisions,
          size: size,
          activeColor: activeColor,
          disabled: disabled,
        ),

        // Min/max labels
        if (minLabel != null || maxLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  minLabel ?? '',
                  style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                ),
                Text(
                  maxLabel ?? '',
                  style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
