// lib/widgets/app_progress.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Progress indicator size options
enum AppProgressSize {
  /// Small (2px track height / 16px circular)
  sm,

  /// Medium (4px track height / 24px circular) - default
  md,

  /// Large (8px track height / 40px circular)
  lg,
}

/// A customizable linear progress indicator following the design system.
///
/// Example usage:
/// ```dart
/// // Determinate progress
/// AppLinearProgress(
///   value: 0.65,
///   showLabel: true,
/// )
///
/// // Indeterminate progress
/// AppLinearProgress(
///   value: null,
/// )
///
/// // With custom colors
/// AppLinearProgress(
///   value: 0.8,
///   color: AppColors.success,
///   backgroundColor: AppColors.successLight,
/// )
/// ```
class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({
    super.key,
    this.value,
    this.size = AppProgressSize.md,
    this.color,
    this.backgroundColor,
    this.showLabel = false,
    this.labelPosition = AppProgressLabelPosition.end,
    this.label,
    this.borderRadius,
  });

  /// Progress value from 0.0 to 1.0. Null for indeterminate.
  final double? value;

  /// Size of the progress indicator
  final AppProgressSize size;

  /// Color of the progress indicator
  final Color? color;

  /// Background/track color
  final Color? backgroundColor;

  /// Whether to show the percentage label
  final bool showLabel;

  /// Position of the label
  final AppProgressLabelPosition labelPosition;

  /// Custom label (overrides percentage)
  final String? label;

  /// Custom border radius
  final BorderRadius? borderRadius;

  double get _height {
    switch (size) {
      case AppProgressSize.sm:
        return 2;
      case AppProgressSize.md:
        return 4;
      case AppProgressSize.lg:
        return 8;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppProgressSize.sm:
        return 10;
      case AppProgressSize.md:
        return 12;
      case AppProgressSize.lg:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progressColor =
        color ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.secondaryDark : AppColors.secondaryLight);
    final radius = borderRadius ?? BorderRadius.circular(_height / 2);

    final labelText =
        label ?? (value != null ? '${(value! * 100).toInt()}%' : '');

    Widget progressBar = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: _height,
        child: value != null
            ? LinearProgressIndicator(
                value: value,
                backgroundColor: bgColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                borderRadius: radius,
              )
            : LinearProgressIndicator(
                backgroundColor: bgColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                borderRadius: radius,
              ),
      ),
    );

    if (!showLabel) return progressBar;

    final labelWidget = Text(
      labelText,
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamilyMono,
        fontSize: _fontSize,
        fontWeight: FontWeight.w500,
        color: isDark
            ? AppColors.mutedForegroundDark
            : AppColors.mutedForegroundLight,
      ),
    );

    switch (labelPosition) {
      case AppProgressLabelPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [labelWidget, const SizedBox(height: 4), progressBar],
        );
      case AppProgressLabelPosition.bottom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [progressBar, const SizedBox(height: 4), labelWidget],
        );
      case AppProgressLabelPosition.start:
        return Row(
          children: [
            labelWidget,
            const SizedBox(width: 8),
            Expanded(child: progressBar),
          ],
        );
      case AppProgressLabelPosition.end:
        return Row(
          children: [
            Expanded(child: progressBar),
            const SizedBox(width: 8),
            labelWidget,
          ],
        );
    }
  }
}

/// Position for progress label
enum AppProgressLabelPosition { top, bottom, start, end }

/// A customizable circular progress indicator following the design system.
///
/// Example usage:
/// ```dart
/// // Determinate circular progress
/// AppCircularProgress(
///   value: 0.75,
///   showLabel: true,
/// )
///
/// // Indeterminate spinner
/// AppCircularProgress(
///   value: null,
///   size: AppProgressSize.sm,
/// )
///
/// // With custom content in center
/// AppCircularProgress(
///   value: 0.5,
///   size: AppProgressSize.lg,
///   child: Icon(Icons.fitness_center),
/// )
/// ```
class AppCircularProgress extends StatelessWidget {
  const AppCircularProgress({
    super.key,
    this.value,
    this.size = AppProgressSize.md,
    this.color,
    this.backgroundColor,
    this.strokeWidth,
    this.showLabel = false,
    this.label,
    this.child,
  });

  /// Progress value from 0.0 to 1.0. Null for indeterminate.
  final double? value;

  /// Size of the progress indicator
  final AppProgressSize size;

  /// Color of the progress indicator
  final Color? color;

  /// Background/track color
  final Color? backgroundColor;

  /// Custom stroke width
  final double? strokeWidth;

  /// Whether to show the percentage label in center
  final bool showLabel;

  /// Custom label (overrides percentage)
  final String? label;

  /// Custom child widget in center
  final Widget? child;

  double get _diameter {
    switch (size) {
      case AppProgressSize.sm:
        return 16;
      case AppProgressSize.md:
        return 24;
      case AppProgressSize.lg:
        return 40;
    }
  }

  double get _strokeWidth {
    if (strokeWidth != null) return strokeWidth!;
    switch (size) {
      case AppProgressSize.sm:
        return 2;
      case AppProgressSize.md:
        return 3;
      case AppProgressSize.lg:
        return 4;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppProgressSize.sm:
        return 8;
      case AppProgressSize.md:
        return 10;
      case AppProgressSize.lg:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progressColor =
        color ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.secondaryDark : AppColors.secondaryLight);

    Widget indicator;

    if (value != null) {
      indicator = CircularProgressIndicator(
        value: value,
        backgroundColor: bgColor,
        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        strokeWidth: _strokeWidth,
        strokeCap: StrokeCap.round,
      );
    } else {
      indicator = CircularProgressIndicator(
        backgroundColor: bgColor,
        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        strokeWidth: _strokeWidth,
        strokeCap: StrokeCap.round,
      );
    }

    // If no center content needed, return simple indicator
    if (!showLabel && child == null) {
      return SizedBox(width: _diameter, height: _diameter, child: indicator);
    }

    // With center content
    return SizedBox(
      width: _diameter,
      height: _diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          indicator,
          if (child != null)
            child!
          else if (showLabel && value != null)
            Text(
              label ?? '${(value! * 100).toInt()}%',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamilyMono,
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
        ],
      ),
    );
  }
}

/// A progress ring with stats, commonly used for fitness/goal tracking.
///
/// Example usage:
/// ```dart
/// AppProgressRing(
///   value: 0.75,
///   size: 120,
///   strokeWidth: 10,
///   label: '750',
///   sublabel: 'of 1000 cal',
/// )
/// ```
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.value,
    this.size = 80,
    this.strokeWidth = 8,
    this.color,
    this.backgroundColor,
    this.label,
    this.sublabel,
    this.icon,
  });

  /// Progress value from 0.0 to 1.0
  final double value;

  /// Diameter of the ring
  final double size;

  /// Width of the stroke
  final double strokeWidth;

  /// Color of the progress ring
  final Color? color;

  /// Background/track color
  final Color? backgroundColor;

  /// Main label text (e.g., "750")
  final String? label;

  /// Sub label text (e.g., "of 1000 cal")
  final String? sublabel;

  /// Optional icon instead of text
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progressColor =
        color ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.secondaryDark : AppColors.secondaryLight);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(bgColor),
              strokeWidth: strokeWidth,
            ),
          ),
          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(icon, size: size * 0.3, color: progressColor)
              else if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamilyMono,
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                ),
              if (sublabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  sublabel!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamilySans,
                    fontSize: size * 0.1,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A step progress indicator for multi-step flows.
///
/// Example usage:
/// ```dart
/// AppStepProgress(
///   currentStep: 2,
///   totalSteps: 4,
///   labels: ['Info', 'Details', 'Review', 'Confirm'],
/// )
/// ```
class AppStepProgress extends StatelessWidget {
  const AppStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
    this.activeColor,
    this.inactiveColor,
    this.completedColor,
    this.showLabels = true,
    this.size = AppProgressSize.md,
  });

  /// Current step (1-indexed)
  final int currentStep;

  /// Total number of steps
  final int totalSteps;

  /// Labels for each step
  final List<String>? labels;

  /// Color for current step
  final Color? activeColor;

  /// Color for inactive steps
  final Color? inactiveColor;

  /// Color for completed steps
  final Color? completedColor;

  /// Whether to show labels
  final bool showLabels;

  /// Size variant
  final AppProgressSize size;

  double get _dotSize {
    switch (size) {
      case AppProgressSize.sm:
        return 8;
      case AppProgressSize.md:
        return 12;
      case AppProgressSize.lg:
        return 16;
    }
  }

  double get _lineHeight {
    switch (size) {
      case AppProgressSize.sm:
        return 2;
      case AppProgressSize.md:
        return 3;
      case AppProgressSize.lg:
        return 4;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppProgressSize.sm:
        return 10;
      case AppProgressSize.md:
        return 12;
      case AppProgressSize.lg:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final active =
        activeColor ??
        (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final inactive =
        inactiveColor ??
        (isDark ? AppColors.secondaryDark : AppColors.secondaryLight);
    final completed = completedColor ?? active;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            // Even indices are dots, odd indices are lines
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              final stepNumber = stepIndex + 1;
              final isCompleted = stepNumber < currentStep;
              final isActive = stepNumber == currentStep;

              Color dotColor;
              if (isCompleted) {
                dotColor = completed;
              } else if (isActive) {
                dotColor = active;
              } else {
                dotColor = inactive;
              }

              return Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: active.withOpacity(0.3), width: 3)
                      : null,
                ),
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        size: _dotSize * 0.7,
                        color: AppColors.white,
                      )
                    : null,
              );
            } else {
              // Line between dots
              final beforeStep = (index + 1) ~/ 2;
              final isCompletedLine = beforeStep < currentStep;

              return Expanded(
                child: Container(
                  height: _lineHeight,
                  margin: EdgeInsets.symmetric(
                    horizontal: size == AppProgressSize.sm ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompletedLine ? completed : inactive,
                    borderRadius: BorderRadius.circular(_lineHeight / 2),
                  ),
                ),
              );
            }
          }),
        ),
        if (showLabels && labels != null && labels!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final stepNumber = index + 1;
              final isCompleted = stepNumber < currentStep;
              final isActive = stepNumber == currentStep;

              return SizedBox(
                width: _dotSize + 40, // Approximate label width
                child: Text(
                  labels!.length > index ? labels![index] : '',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamilySans,
                    fontSize: _fontSize,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive || isCompleted
                        ? (isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight)
                        : (isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// A skeleton/shimmer loading placeholder.
///
/// Example usage:
/// ```dart
/// // Text skeleton
/// AppSkeleton(
///   width: 200,
///   height: 16,
/// )
///
/// // Circle skeleton (avatar)
/// AppSkeleton.circle(size: 48)
///
/// // Card skeleton
/// AppSkeleton(
///   width: double.infinity,
///   height: 100,
///   borderRadius: BorderRadius.circular(16),
/// )
/// ```
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  }) : _isCircle = false,
       _circleSize = null;

  /// Creates a circular skeleton
  const AppSkeleton.circle({
    super.key,
    required double size,
    this.baseColor,
    this.highlightColor,
  }) : _isCircle = true,
       _circleSize = size,
       width = null,
       height = null,
       borderRadius = null;

  /// Width of the skeleton
  final double? width;

  /// Height of the skeleton
  final double? height;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Base/background color
  final Color? baseColor;

  /// Highlight/shimmer color
  final Color? highlightColor;

  final bool _isCircle;
  final double? _circleSize;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base =
        widget.baseColor ??
        (isDark ? AppColors.secondaryDark : AppColors.gray200);
    final highlight =
        widget.highlightColor ??
        (isDark ? AppColors.surface2Dark : AppColors.gray100);

    if (widget._isCircle) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: widget._circleSize,
            height: widget._circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [base, highlight, base],
                stops: [
                  (_animation.value - 0.3).clamp(0.0, 1.0),
                  _animation.value.clamp(0.0, 1.0),
                  (_animation.value + 0.3).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusSm),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
