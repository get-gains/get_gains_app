# AppProgress

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Visual indicators for progress, loading states, and multi-step flows. Includes linear, circular, ring, step, and skeleton variants.

---

## Variants

| Variant | Purpose | Modes |
|---------|---------|-------|
| `linear` | Progress along a track | Determinate, indeterminate |
| `circular` | Compact progress indicator | Determinate, indeterminate |
| `ring` | Goal/stat display | Center content |
| `step` | Multi-step flow indicator | Dots with labels |
| `skeleton` | Loading placeholder | Shimmer animation |

---

## Specifications

### Size Variants

| Size | Linear Height | Circular Diameter | Stroke Width |
|------|--------------|-------------------|--------------|
| `sm` | 2px | 16px | 2px |
| `md` | 4px | 24px | 3px |
| `lg` | 8px | 40px | 4px |

### Styling

- **Track color**: `muted` at 50%
- **Fill color**: `primary` (default), customizable
- **Border radius**: `radiusFull` for rounded ends
- **Animation**: `durationSlow` (300ms) for value changes

---

## Implementation

### Linear Progress

```dart
// lib/widgets/app_progress.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

enum AppProgressSize { sm, md, lg }
enum AppProgressLabelPosition { top, bottom, start, end }

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
  });

  final double? value; // null for indeterminate
  final AppProgressSize size;
  final Color? color;
  final Color? backgroundColor;
  final bool showLabel;
  final AppProgressLabelPosition labelPosition;
  final String? label;

  double get _height => switch (size) {
    AppProgressSize.sm => 2,
    AppProgressSize.md => 4,
    AppProgressSize.lg => 8,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final trackColor = backgroundColor ?? (isDark ? AppColors.mutedDark : AppColors.mutedLight).withOpacity(0.5);
    final labelText = label ?? (value != null ? '${(value! * 100).round()}%' : '');

    Widget progressBar = ClipRRect(
      borderRadius: BorderRadius.circular(_height / 2),
      child: SizedBox(
        height: _height,
        child: value != null
            ? _DeterminateLinear(value: value!, color: progressColor, trackColor: trackColor)
            : _IndeterminateLinear(color: progressColor, trackColor: trackColor),
      ),
    );

    if (!showLabel) return progressBar;

    final labelWidget = Text(
      labelText,
      style: AppTextStyles.labelSmall.copyWith(
        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
      ),
    );

    return switch (labelPosition) {
      AppProgressLabelPosition.top => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [labelWidget, const SizedBox(height: 4), progressBar],
      ),
      AppProgressLabelPosition.bottom => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [progressBar, const SizedBox(height: 4), labelWidget],
      ),
      AppProgressLabelPosition.start => Row(
        children: [labelWidget, const SizedBox(width: 8), Expanded(child: progressBar)],
      ),
      AppProgressLabelPosition.end => Row(
        children: [Expanded(child: progressBar), const SizedBox(width: 8), labelWidget],
      ),
    };
  }
}

class _DeterminateLinear extends StatelessWidget {
  const _DeterminateLinear({required this.value, required this.color, required this.trackColor});
  final double value;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Container(color: trackColor),
          AnimatedContainer(
            duration: AppTheme.durationNormal,
            width: constraints.maxWidth * value.clamp(0, 1),
            color: color,
          ),
        ],
      ),
    );
  }
}

class _IndeterminateLinear extends StatefulWidget {
  const _IndeterminateLinear({required this.color, required this.trackColor});
  final Color color;
  final Color trackColor;

  @override
  State<_IndeterminateLinear> createState() => _IndeterminateLinearState();
}

class _IndeterminateLinearState extends State<_IndeterminateLinear> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final barWidth = width * 0.3;
          final position = _controller.value * (width + barWidth) - barWidth;
          return Stack(
            children: [
              Container(color: widget.trackColor),
              Positioned(left: position, width: barWidth, top: 0, bottom: 0, child: Container(color: widget.color)),
            ],
          );
        },
      ),
    );
  }
}
```

### Circular Progress

```dart
class AppCircularProgress extends StatelessWidget {
  const AppCircularProgress({
    super.key,
    this.value,
    this.size = AppProgressSize.md,
    this.color,
    this.backgroundColor,
    this.strokeWidth,
    this.showLabel = false,
  });

  final double? value;
  final AppProgressSize size;
  final Color? color;
  final Color? backgroundColor;
  final double? strokeWidth;
  final bool showLabel;

  double get _diameter => switch (size) {
    AppProgressSize.sm => 16,
    AppProgressSize.md => 24,
    AppProgressSize.lg => 40,
  };

  double get _strokeWidth => strokeWidth ?? switch (size) {
    AppProgressSize.sm => 2,
    AppProgressSize.md => 3,
    AppProgressSize.lg => 4,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final trackColor = backgroundColor ?? (isDark ? AppColors.mutedDark : AppColors.mutedLight).withOpacity(0.5);

    Widget indicator = SizedBox(
      width: _diameter,
      height: _diameter,
      child: value != null
          ? CircularProgressIndicator(
              value: value,
              strokeWidth: _strokeWidth,
              valueColor: AlwaysStoppedAnimation(progressColor),
              backgroundColor: trackColor,
              strokeCap: StrokeCap.round,
            )
          : CircularProgressIndicator(
              strokeWidth: _strokeWidth,
              valueColor: AlwaysStoppedAnimation(progressColor),
              backgroundColor: trackColor,
              strokeCap: StrokeCap.round,
            ),
    );

    if (!showLabel || value == null) return indicator;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(height: 4),
        Text(
          '${(value! * 100).round()}%',
          style: AppTextStyles.labelSmall.copyWith(
            color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
          ),
        ),
      ],
    );
  }
}
```

### Progress Ring

```dart
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.value,
    this.size = 120,
    this.strokeWidth = 10,
    this.color,
    this.backgroundColor,
    this.label,
    this.sublabel,
    this.icon,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final String? label;
  final String? sublabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final trackColor = backgroundColor ?? (isDark ? AppColors.mutedDark : AppColors.mutedLight).withOpacity(0.3);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation(trackColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Progress
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0, 1)),
              duration: AppTheme.durationSlow,
              curve: Curves.easeOut,
              builder: (context, animatedValue, _) => CircularProgressIndicator(
                value: animatedValue,
                strokeWidth: strokeWidth,
                valueColor: AlwaysStoppedAnimation(progressColor),
                backgroundColor: Colors.transparent,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 24, color: progressColor),
                const SizedBox(height: 4),
              ],
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamilyMono,
                    fontSize: size * 0.2,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
                  ),
                ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Step Progress

```dart
class AppStepProgress extends StatelessWidget {
  const AppStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
    this.size = AppProgressSize.md,
    this.activeColor,
    this.inactiveColor,
  });

  final int currentStep;
  final int totalSteps;
  final List<String>? labels;
  final AppProgressSize size;
  final Color? activeColor;
  final Color? inactiveColor;

  double get _dotSize => switch (size) {
    AppProgressSize.sm => 8,
    AppProgressSize.md => 12,
    AppProgressSize.lg => 16,
  };

  double get _lineHeight => switch (size) {
    AppProgressSize.sm => 2,
    AppProgressSize.md => 3,
    AppProgressSize.lg => 4,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = activeColor ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final inactive = inactiveColor ?? (isDark ? AppColors.mutedDark : AppColors.mutedLight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isEven) {
              // Dot
              final stepIndex = index ~/ 2;
              final isComplete = stepIndex < currentStep;
              final isCurrent = stepIndex == currentStep;
              return AnimatedContainer(
                duration: AppTheme.durationNormal,
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  color: isComplete || isCurrent ? active : inactive,
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: active, width: 2) : null,
                ),
                child: isComplete ? Icon(Icons.check, size: _dotSize * 0.7, color: Colors.white) : null,
              );
            } else {
              // Line
              final lineIndex = index ~/ 2;
              final isComplete = lineIndex < currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: AppTheme.durationNormal,
                  height: _lineHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isComplete ? active : inactive,
                    borderRadius: BorderRadius.circular(_lineHeight / 2),
                  ),
                ),
              );
            }
          }),
        ),
        if (labels != null && labels!.length == totalSteps) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels!.asMap().entries.map((entry) {
              final isCurrent = entry.key == currentStep;
              return Text(
                entry.value,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isCurrent
                      ? active
                      : (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight),
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
```

### Skeleton

```dart
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  }) : isCircle = false;

  const AppSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        isCircle = true;

  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.surface2Dark : AppColors.mutedLight;
    final highlightColor = isDark ? AppColors.surface3Dark : AppColors.backgroundLight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.isCircle ? null : (widget.borderRadius ?? BorderRadius.circular(4)),
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          gradient: LinearGradient(
            begin: Alignment(-1 + _animation.value, 0),
            end: Alignment(_animation.value, 0),
            colors: [baseColor, highlightColor, baseColor],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
```

---

## Usage Examples

```dart
// Determinate linear progress
AppLinearProgress(
  value: 0.65,
  showLabel: true,
)

// Indeterminate linear progress (loading)
AppLinearProgress(value: null)

// Circular progress
AppCircularProgress(
  value: 0.75,
  showLabel: true,
  size: AppProgressSize.lg,
)

// Loading spinner
AppCircularProgress(value: null)

// Progress ring for goals
AppProgressRing(
  value: 0.75,
  size: 120,
  strokeWidth: 10,
  label: '750',
  sublabel: 'of 1000 cal',
)

// Step progress
AppStepProgress(
  currentStep: 2,
  totalSteps: 4,
  labels: ['Info', 'Details', 'Review', 'Confirm'],
)

// Skeleton loading
AppSkeleton(width: 200, height: 16)
AppSkeleton.circle(size: 48)
AppSkeleton(
  width: double.infinity,
  height: 100,
  borderRadius: BorderRadius.circular(16),
)

// Skeleton loading group
Column(
  children: [
    Row(
      children: [
        AppSkeleton.circle(size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 120, height: 14),
              const SizedBox(height: 8),
              AppSkeleton(width: 80, height: 12),
            ],
          ),
        ),
      ],
    ),
  ],
)
```

---

## Accessibility

- ✅ Progress values: Exposed to screen readers via semantics
- ✅ Indeterminate: Announced appropriately
- ✅ Step labels: Provide context for navigation
- ✅ Skeleton: Hidden from assistive technology (decorative)
