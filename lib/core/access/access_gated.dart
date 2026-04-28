// lib/core/access/access_gated.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/subscription/data/models/models.dart';
import '../../features/subscription/presentation/models/subscription_feature.dart';
import '../../features/subscription/presentation/providers/subscription_provider.dart';
import '../../features/subscription/presentation/widgets/upgrade_prompt.dart';
import 'access_guard.dart';
import 'access_guard_provider.dart';

/// Declarative widget that gates [child] behind an [AccessRequirement].
///
/// Replaces the legacy `SubscriptionGatedWidget`. Shows a loading skeleton
/// while subscription state resolves, then either renders [child] on
/// [AccessGranted] or a fallback (custom [denied] or default [UpgradePrompt]).
class AccessGated extends ConsumerWidget {
  const AccessGated({
    super.key,
    required this.requires,
    required this.child,
    this.feature,
    this.compact = false,
    this.loading,
    this.denied,
  });

  /// What access level is needed.
  final AccessRequirement requires;

  /// Shown when access is granted.
  final Widget child;

  /// Feature context for the default [UpgradePrompt] fallback.
  final SubscriptionFeature? feature;

  /// Compact mode for inline display of fallback.
  final bool compact;

  /// Custom loading widget (defaults to skeleton container).
  final Widget? loading;

  /// Custom denied builder. Receives the [AccessDecision] that caused denial.
  /// If null, renders [UpgradePrompt] with [feature] context.
  final Widget Function(AccessDecision)? denied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guard = ref.read(accessGuardProvider);
    // Watch subscription state to rebuild reactively
    final subState = ref.watch(subscriptionProvider);

    final decision = guard.evaluate(requires);

    switch (decision) {
      case AccessGranted():
        return child;
      case AccessPending():
        return loading ?? _buildLoadingSkeleton(context);
      case AccessDeniedUnauthenticated():
      case AccessDeniedTier():
        if (denied != null) return denied!(decision);

        // Default: UpgradePrompt with subscription status context
        SubscriptionStatus? subscriptionStatus;
        if (subState is SubscriptionLoaded) {
          subscriptionStatus = subState.status.subscription?.status;
        }

        return UpgradePrompt(
          feature: feature,
          compact: compact,
          subscriptionStatus: subscriptionStatus,
        );
    }
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: compact ? 48 : 120,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
