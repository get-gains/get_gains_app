import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

Future<bool?> showAdGateDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: isDark
              ? AppColors.cardDark
              : AppColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.movie_creation_outlined,
                  size: 48,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'Watch an Ad to Compare',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'A short ad will play. Close it to continue to the form comparison.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
