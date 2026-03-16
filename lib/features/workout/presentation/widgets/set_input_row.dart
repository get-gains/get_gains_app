import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../guidance/guidance.dart';

/// Set Input Row
///
/// A row for inputting set data (reps, weight, RPE).
/// Used in the exercise log card.
class SetInputRow extends StatelessWidget {
  const SetInputRow({
    super.key,
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.rpe,
    required this.isCompleted,
    required this.isActive,
    required this.targetReps,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onRpeChanged,
    required this.onComplete,
    required this.onTap,
  });

  final int setNumber;
  final int reps;
  final double weight;
  final int? rpe;
  final bool isCompleted;
  final bool isActive;
  final String targetReps;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int?> onRpeChanged;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    Color backgroundColor;
    Color borderColor;

    if (isCompleted) {
      backgroundColor = AppColors.success.withValues(alpha: 0.1);
      borderColor = AppColors.success.withValues(alpha: 0.3);
    } else if (isActive) {
      backgroundColor = primaryColor.withValues(alpha: 0.1);
      borderColor = primaryColor;
    } else {
      backgroundColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
      borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    }

    return GestureDetector(
      onTap: isCompleted ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        ),
        child: Row(
          children: [
            // Set number indicator
            _SetIndicator(
              number: setNumber,
              isCompleted: isCompleted,
              isActive: isActive,
            ),

            const SizedBox(width: 12),

            // Reps input
            Expanded(
              child: _NumberInput(
                label: 'Reps',
                value: reps,
                hint: targetReps,
                enabled: !isCompleted && isActive,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onRepsChanged(value);
                },
              ),
            ),

            const SizedBox(width: 12),

            // Weight input
            Expanded(
              child: _NumberInput(
                label: 'Weight (kg)',
                value: weight.toInt(),
                decimals: true,
                enabled: !isCompleted && isActive,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onWeightChanged(value.toDouble());
                },
              ),
            ),

            const SizedBox(width: 12),

            // Complete button / check
            if (isCompleted)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RpeInfoIcon(rpe: rpe),
                  const SizedBox(width: 4),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              )
            else if (isActive)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RpeInfoIcon(rpe: rpe),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onComplete();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact RPE indicator with info icon that shows RPE scale explanation.
class _RpeInfoIcon extends StatelessWidget {
  const _RpeInfoIcon({required this.rpe});

  final int? rpe;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRpeSheet(context),
      child: Tooltip(
        message: 'RPE Info',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rpe != null)
              Text(
                '$rpe',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  void _showRpeSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'RPE Scale (Rate of Perceived Exertion)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'RPE helps you track workout intensity. Use this scale to gauge how hard each set felt.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const Divider(height: 24),
              ...kRpeScaleEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _rpeColor(entry.level, isDark),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.level}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.label,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              entry.description,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _rpeColor(int level, bool isDark) {
    if (level <= 3) return Colors.green;
    if (level <= 5) return Colors.lightGreen;
    if (level <= 7) return Colors.orange;
    if (level <= 9) return Colors.deepOrange;
    return Colors.red;
  }
}

class _SetIndicator extends StatelessWidget {
  const _SetIndicator({
    required this.number,
    required this.isCompleted,
    required this.isActive,
  });

  final int number;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    Color backgroundColor;
    Color textColor;

    if (isCompleted) {
      backgroundColor = AppColors.success;
      textColor = Colors.white;
    } else if (isActive) {
      backgroundColor = primaryColor;
      textColor = Colors.white;
    } else {
      backgroundColor = isDark
          ? AppColors.surface2Dark
          : AppColors.surface2Light;
      textColor = isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.label,
    required this.value,
    this.hint,
    this.decimals = false,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String? hint;
  final bool decimals;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Decrement button
            if (enabled)
              GestureDetector(
                onTap: value > 0 ? () => onChanged(value - 1) : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: value > 0
                        ? primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: value > 0
                        ? primaryColor
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                  ),
                ),
              ),

            // Value
            Expanded(
              child: GestureDetector(
                onTap: enabled ? () => _showNumberPicker(context) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    decimals ? value.toStringAsFixed(0) : value.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: enabled
                          ? null
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              ),
            ),

            // Increment button
            if (enabled)
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.add, size: 16, color: primaryColor),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showNumberPicker(BuildContext context) async {
    final controller = TextEditingController(text: value.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter $label'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(
            hintText: hint ?? 'Enter value',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final parsed =
                  int.tryParse(controller.text) ??
                  double.tryParse(controller.text)?.toInt();
              Navigator.of(context).pop(parsed);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}
