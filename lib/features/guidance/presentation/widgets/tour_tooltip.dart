import 'package:flutter/material.dart';

import '../../data/models/tour_step_model.dart';

/// Styled tooltip card shown during a spotlight tour step.
///
/// Displays the step's [title] and [body], step-indicator dots,
/// and "Skip" / "Next" (or "Done") action buttons.
class TourTooltip extends StatelessWidget {
  const TourTooltip({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  final TourStepModel step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLast = stepIndex >= totalSteps - 1;
    final actionLabel = step.actionLabel ?? (isLast ? 'Done' : 'Next');

    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      offset: Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: 1.0,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: isDark
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    step.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Body
                  Text(step.body, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),

                  // Step dots + actions
                  Row(
                    children: [
                      // Step indicator dots
                      ...List.generate(totalSteps, (i) {
                        final isCurrent = i == stepIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            width: isCurrent ? 10 : 8,
                            height: isCurrent ? 10 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                        );
                      }),

                      const Spacer(),

                      // Skip
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          'Skip',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Next / Done
                      FilledButton(
                        onPressed: onNext,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(actionLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
