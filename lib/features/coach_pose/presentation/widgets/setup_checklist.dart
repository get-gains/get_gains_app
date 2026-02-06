import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../services/setup_validation_service.dart';

/// Displays setup validation checks as an animated checklist.
class SetupChecklist extends StatelessWidget {
  const SetupChecklist({super.key, required this.validation});

  final SetupValidationResult? validation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final checks = validation?.checks ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface1Dark.withValues(alpha: 0.9)
            : AppColors.cardLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist,
                size: 20,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Setup Checks',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (validation != null)
                Text(
                  '${validation!.passedCount}/${validation!.totalCount}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: validation!.allPassed
                        ? (isDark
                              ? AppColors.accentDark
                              : AppColors.accentLight)
                        : (isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...checks.map((check) => _CheckItem(check: check, isDark: isDark)),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.check, required this.isDark});

  final SetupCheck check;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final passedColor = isDark ? AppColors.accentDark : AppColors.accentLight;
    final failedColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final color = check.passed ? passedColor : failedColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              check.passed ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(check.passed),
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: check.passed
                        ? (isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight)
                        : (isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight),
                    fontWeight: check.passed
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
                if (check.message != null && !check.passed)
                  Text(
                    check.message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
