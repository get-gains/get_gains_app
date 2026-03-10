// lib/features/subscription/presentation/widgets/upgrade_prompt.dart

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/subscription_model.dart';
import '../models/subscription_feature.dart';

/// Shows an upgrade prompt when a feature requires subscription.
///
/// Accepts a [SubscriptionFeature] for contextual benefit messaging and
/// analytics tracking. Supports full and compact display modes, and
/// handles PAST_DUE / PENDING subscription states with distinct CTAs.
///
/// Can be used as:
/// - Inline widget (when feature is disabled)
/// - Bottom sheet content
/// - Dialog content
class UpgradePrompt extends StatelessWidget {
  const UpgradePrompt({
    super.key,
    this.feature,
    this.requiredTier = 1,
    this.tierName,
    this.title,
    this.description,
    this.onUpgrade,
    this.onDismiss,
    this.compact = false,
    this.subscriptionStatus,
  });

  /// The subscription feature driving contextual messaging.
  ///
  /// When provided, [feature.benefitDescription] is used as the default
  /// description and [feature.analyticsKey] can be used for tracking.
  final SubscriptionFeature? feature;

  /// The tier required for this feature
  final int requiredTier;

  /// The display name of the required tier (from plan name).
  /// If not provided, defaults to 'Subscription'.
  final String? tierName;

  /// Custom title (overrides feature-based default)
  final String? title;

  /// Custom description (overrides feature-based default)
  final String? description;

  /// Called when user taps upgrade / view plans button.
  /// Not used for PAST_DUE (which deep-links to store) or PENDING.
  final VoidCallback? onUpgrade;

  /// Called when user dismisses the prompt
  final VoidCallback? onDismiss;

  /// Use compact layout for inline display.
  ///
  /// Compact mode renders a small inline card with benefit text and a
  /// "Learn More" link. Non-compact renders the full modal-triggering CTA.
  final bool compact;

  /// Current subscription status for special-case treatment.
  ///
  /// - [SubscriptionStatus.pastDue]: Shows "Update payment method" billing
  ///   resolution CTA with deep link to Play Store / App Store subscription
  ///   management.
  /// - [SubscriptionStatus.pending]: Shows "Your subscription is being
  ///   processed" informational message with no action required.
  /// - Other statuses or `null`: Standard upgrade prompt.
  final SubscriptionStatus? subscriptionStatus;

  /// Effective description derived from [description], [feature], or default.
  String _effectiveDescription(String tierName) {
    if (description != null) return description!;
    if (feature != null) return feature!.benefitDescription;
    return 'This feature requires a $tierName subscription to access.';
  }

  /// Effective title derived from [title], status, or default.
  String _effectiveTitle(String tierName) {
    if (title != null) return title!;
    if (subscriptionStatus == SubscriptionStatus.pastDue) {
      return 'Payment Update Required';
    }
    if (subscriptionStatus == SubscriptionStatus.pending) {
      return 'Subscription Processing';
    }
    return 'Upgrade to $tierName';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayTierName = tierName ?? 'Subscription';

    // PAST_DUE: billing resolution CTA
    if (subscriptionStatus == SubscriptionStatus.pastDue) {
      if (compact) {
        return _buildCompactPastDue(context, isDark);
      }
      return _buildFullPastDue(context, isDark);
    }

    // PENDING: informational only
    if (subscriptionStatus == SubscriptionStatus.pending) {
      if (compact) {
        return _buildCompactPending(context, isDark);
      }
      return _buildFullPending(context, isDark);
    }

    // Standard upgrade prompt
    if (compact) {
      return _buildCompact(context, isDark, displayTierName);
    }
    return _buildFull(context, isDark, displayTierName);
  }

  // ── Compact: standard ──────────────────────────────────────

  Widget _buildCompact(BuildContext context, bool isDark, String tierName) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, size: 20, color: primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _effectiveDescription(tierName),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: primary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed:
                onUpgrade ??
                () => showUpgradeSheet(
                  context: context,
                  feature: feature,
                  requiredTier: requiredTier,
                ),
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  // ── Full: standard ─────────────────────────────────────────

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
          _effectiveTitle(tierName),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Description
        Text(
          _effectiveDescription(tierName),
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

  // ── Compact: PAST_DUE ──────────────────────────────────────

  Widget _buildCompactPastDue(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Colors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your payment needs updating',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.amber.shade800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => _openSubscriptionManagement(),
            child: const Text('Fix'),
          ),
        ],
      ),
    );
  }

  // ── Full: PAST_DUE ────────────────────────────────────────

  Widget _buildFullPastDue(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 36,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Update Required',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your subscription payment could not be processed. '
          'Please update your payment method to continue accessing '
          'coach features.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            if (onDismiss != null)
              Expanded(
                child: AppButton.outline(label: 'Later', onPressed: onDismiss),
              ),
            if (onDismiss != null) const SizedBox(width: 12),
            Expanded(
              child: AppButton.primary(
                label: 'Update Payment Method',
                icon: Icons.credit_card,
                onPressed: () => _openSubscriptionManagement(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Compact: PENDING ───────────────────────────────────────

  Widget _buildCompactPending(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your subscription is being processed',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.blue.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Full: PENDING ──────────────────────────────────────────

  Widget _buildFullPending(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Subscription Processing',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your subscription is being processed. '
          'This usually takes just a moment. '
          'You\'ll have full access once it\'s confirmed.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (onDismiss != null)
          SizedBox(
            width: double.infinity,
            child: AppButton.outline(label: 'OK', onPressed: onDismiss),
          ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  /// Opens the platform's subscription management page.
  ///
  /// - Android: Google Play Store subscription management
  /// - iOS: App Store subscription management
  static Future<void> _openSubscriptionManagement() async {
    final Uri uri;
    if (Platform.isIOS) {
      uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else {
      // Android — Google Play subscription management
      uri = Uri.parse('https://play.google.com/store/account/subscriptions');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Shows an upgrade bottom sheet with contextual feature messaging.
///
/// Accepts a [SubscriptionFeature] to display feature-specific benefit text,
/// a "View Plans" action button, and a dismiss/close option.
///
/// For PAST_DUE status pass [subscriptionStatus] to show billing CTA instead.
/// For PENDING status pass [subscriptionStatus] to show informational message.
Future<void> showUpgradeSheet({
  required BuildContext context,
  SubscriptionFeature? feature,
  int requiredTier = 1,
  String? tierName,
  String? title,
  String? description,
  VoidCallback? onUpgrade,
  SubscriptionStatus? subscriptionStatus,
}) {
  return showAppBottomSheet(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(24),
      child: UpgradePrompt(
        feature: feature,
        requiredTier: requiredTier,
        tierName: tierName,
        title: title,
        description: description,
        subscriptionStatus: subscriptionStatus,
        onUpgrade: onUpgrade ?? () => Navigator.of(context).pop(),
        onDismiss: () => Navigator.of(context).pop(),
      ),
    ),
  );
}
