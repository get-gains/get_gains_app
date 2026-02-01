// lib/features/subscription/presentation/widgets/upgrade_prompt.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../providers/subscription_guard.dart';

/// Shows an upgrade prompt when a feature requires subscription
///
/// Can be used as:
/// - Inline widget (when feature is disabled)
/// - Bottom sheet content
/// - Dialog content
class UpgradePrompt extends StatelessWidget {
  const UpgradePrompt({
    super.key,
    required this.requiredTier,
    this.tierName,
    this.title,
    this.description,
    this.onUpgrade,
    this.onDismiss,
    this.compact = false,
  });

  /// The tier required for this feature
  final int requiredTier;

  /// The display name of the required tier (from plan name)
  /// If not provided, defaults to 'Subscription'
  final String? tierName;

  /// Custom title (defaults to tier-based message)
  final String? title;

  /// Custom description
  final String? description;

  /// Called when user taps upgrade button
  final VoidCallback? onUpgrade;

  /// Called when user dismisses the prompt
  final VoidCallback? onDismiss;

  /// Use compact layout for inline display
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayTierName = tierName ?? 'Subscription';

    if (compact) {
      return _buildCompact(context, isDark, displayTierName);
    }

    return _buildFull(context, isDark, displayTierName);
  }

  Widget _buildCompact(BuildContext context, bool isDark, String tierName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 20,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title ?? 'Requires $tierName',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ),
          ),
          if (onUpgrade != null)
            TextButton(onPressed: onUpgrade, child: const Text('Upgrade')),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context, bool isDark, String tierName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? AppColors.primaryDark : AppColors.primaryLight,
                (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    .withValues(alpha: 0.7),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          title ?? 'Upgrade to $tierName',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Description
        Text(
          description ??
              'This feature requires a $tierName subscription to access.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Buttons
        Row(
          children: [
            if (onDismiss != null)
              Expanded(
                child: AppButton.outline(
                  label: 'Maybe Later',
                  onPressed: onDismiss,
                ),
              ),
            if (onDismiss != null && onUpgrade != null)
              const SizedBox(width: 12),
            if (onUpgrade != null)
              Expanded(
                child: AppButton.primary(
                  label: 'View Plans',
                  onPressed: onUpgrade,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Shows an upgrade bottom sheet
///
/// Use when access is denied to a feature.
/// [tierName] - The display name of the required tier (from plan name)
Future<void> showUpgradeSheet({
  required BuildContext context,
  required int requiredTier,
  String? tierName,
  String? title,
  String? description,
  VoidCallback? onUpgrade,
}) {
  return showAppBottomSheet(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(24),
      child: UpgradePrompt(
        requiredTier: requiredTier,
        tierName: tierName,
        title: title,
        description: description,
        onUpgrade: onUpgrade ?? () => Navigator.of(context).pop(),
        onDismiss: () => Navigator.of(context).pop(),
      ),
    ),
  );
}
