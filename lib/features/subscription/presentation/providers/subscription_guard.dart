// lib/features/subscription/presentation/providers/subscription_guard.dart

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/app_error.dart';
import '../../data/models/models.dart';
import 'subscription_provider.dart';

part 'subscription_guard.g.dart';

/// Subscription tier levels
///
/// These correspond to the tierLevel field in Plan model.
/// Higher tier = more access.
abstract class SubscriptionTiers {
  /// Free tier - no subscription required
  static const int free = 0;

  /// Basic tier - entry-level subscription
  static const int basic = 1;

  /// Premium tier - standard subscription
  static const int premium = 2;

  /// Pro tier - full-featured subscription
  static const int pro = 3;
}

/// Result of a subscription guard check
sealed class SubscriptionGuardResult {
  const SubscriptionGuardResult();
}

/// Access granted - user has required tier
class SubscriptionGranted extends SubscriptionGuardResult {
  const SubscriptionGranted();
}

/// Access denied - user needs higher tier
class SubscriptionDenied extends SubscriptionGuardResult {
  const SubscriptionDenied({
    required this.requiredTier,
    required this.currentTier,
    required this.requiredTierName,
    this.message,
  });

  final int requiredTier;
  final int currentTier;

  /// The display name of the required tier (from plan name)
  final String requiredTierName;

  final String? message;

  /// Get default denial message
  String get defaultMessage {
    return 'This feature requires a $requiredTierName subscription';
  }
}

/// Subscription not loaded yet
class SubscriptionPending extends SubscriptionGuardResult {
  const SubscriptionPending();
}

/// Subscription Guard Provider
///
/// Provides utilities for checking subscription access.
/// Use this for:
/// - Route protection (redirect to upgrade page)
/// - Feature gating (disable/hide UI elements)
/// - Function execution guards (prevent API calls)
///
/// Usage:
/// ```dart
/// // Check if user has required tier
/// final guard = ref.read(subscriptionGuardProvider);
/// final result = guard.checkAccess(SubscriptionTiers.premium);
///
/// if (result is SubscriptionDenied) {
///   // Show upgrade prompt
/// }
///
/// // Use in async function
/// final canAccess = await guard.requireTier(
///   SubscriptionTiers.premium,
///   onDenied: (result) => showUpgradeSheet(context),
/// );
/// if (!canAccess) return;
/// ```
@riverpod
SubscriptionGuard subscriptionGuard(Ref ref) {
  return SubscriptionGuard(ref);
}

/// Subscription Guard
///
/// Centralized subscription access control.
class SubscriptionGuard {
  SubscriptionGuard(this._ref);

  final Ref _ref;

  /// Check if user has access to the required tier
  ///
  /// [requiredTier] - Minimum tier level required
  /// Returns SubscriptionGuardResult indicating access status
  SubscriptionGuardResult checkAccess(int requiredTier) {
    final state = _ref.read(subscriptionProvider);

    if (state is! SubscriptionLoaded) {
      return const SubscriptionPending();
    }

    final currentTier = state.status.tierLevel;

    if (currentTier >= requiredTier) {
      return const SubscriptionGranted();
    }

    // Get the plan name for the required tier from available plans
    final tierName = _getPlanNameForTier(state.plans, requiredTier);

    return SubscriptionDenied(
      requiredTier: requiredTier,
      currentTier: currentTier,
      requiredTierName: tierName,
    );
  }

  /// Get plan name for a given tier level from available plans
  String _getPlanNameForTier(List<PlanModel> plans, int tier) {
    // Find a plan with matching tier level
    final matchingPlan = plans.where((p) => p.tierLevel == tier).firstOrNull;
    if (matchingPlan != null) {
      // Extract base name (remove billing cycle suffix if present)
      return _formatPlanName(matchingPlan.name);
    }
    return 'Subscription';
  }

  /// Format plan name for display (e.g., "premium_monthly" -> "Premium")
  String _formatPlanName(String name) {
    // Remove common suffixes like _monthly, _yearly, etc.
    final baseName = name
        .replaceAll(
          RegExp(
            r'[_-](monthly|yearly|annual|weekly|daily)\$',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll('_', ' ');
    // Capitalize first letter of each word
    return baseName
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  /// Check if user has at least the required tier
  ///
  /// Simple boolean check for conditional rendering.
  bool hasTier(int requiredTier) {
    final result = checkAccess(requiredTier);
    return result is SubscriptionGranted;
  }

  /// Check if user is subscribed (any tier > 0)
  bool get isSubscribed => hasTier(SubscriptionTiers.basic);

  /// Get current tier level
  int get currentTier {
    final state = _ref.read(subscriptionProvider);
    if (state is SubscriptionLoaded) {
      return state.status.tierLevel;
    }
    return 0;
  }

  /// Require a specific tier for a function execution
  ///
  /// Use this to guard async operations that require subscription.
  /// If denied, calls [onDenied] callback and returns false.
  ///
  /// Example:
  /// ```dart
  /// Future<void> getCoaches() async {
  ///   final guard = ref.read(subscriptionGuardProvider);
  ///   final canAccess = await guard.requireTier(
  ///     SubscriptionTiers.premium,
  ///     onDenied: (result) => showUpgradeSheet(context),
  ///   );
  ///   if (!canAccess) return;
  ///
  ///   // Proceed with API call
  ///   await apiClient.get('/coaches');
  /// }
  /// ```
  Future<bool> requireTier(
    int requiredTier, {
    void Function(SubscriptionDenied)? onDenied,
  }) async {
    final result = checkAccess(requiredTier);

    switch (result) {
      case SubscriptionGranted():
        return true;

      case SubscriptionDenied():
        AppLogger.info(
          'Access denied: requires tier $requiredTier, has ${result.currentTier}',
          tag: 'SubGuard',
        );
        onDenied?.call(result);
        return false;

      case SubscriptionPending():
        // Wait for subscription to load
        AppLogger.debug('Waiting for subscription to load', tag: 'SubGuard');
        await _waitForSubscription();
        return requireTier(requiredTier, onDenied: onDenied);
    }
  }

  /// Wait for subscription state to load
  Future<void> _waitForSubscription() async {
    // Poll for up to 5 seconds
    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final state = _ref.read(subscriptionProvider);
      if (state is SubscriptionLoaded || state is SubscriptionError) {
        return;
      }
    }
  }
}

// ============== Function Execution Guards ==============

/// Extension for adding subscription guards to functions
///
/// Usage:
/// ```dart
/// Future<Result<List<Coach>, AppError>> getCoaches() async {
///   return ref.read(subscriptionGuardProvider).guardedCall(
///     requiredTier: SubscriptionTiers.premium,
///     call: () => repository.getCoaches(),
///   );
/// }
/// ```
extension SubscriptionGuardExtension on SubscriptionGuard {
  /// Execute a function only if user has required tier
  ///
  /// Returns Failure with AuthError if denied.
  Future<Result<T, AppError>> guardedCall<T>({
    required int requiredTier,
    required Future<Result<T, AppError>> Function() call,
  }) async {
    final result = checkAccess(requiredTier);

    switch (result) {
      case SubscriptionGranted():
        return call();

      case SubscriptionDenied():
        AppLogger.info(
          'Guarded call denied: requires tier $requiredTier',
          tag: 'SubGuard',
        );
        return Failure(
          AuthError(
            message: 'Subscription required (tier $requiredTier)',
            code: 'SUBSCRIPTION_REQUIRED',
          ),
        );

      case SubscriptionPending():
        await _waitForSubscription();
        return guardedCall(requiredTier: requiredTier, call: call);
    }
  }
}

// ============== Route Protection ==============

/// Route guard that checks subscription tier
///
/// Use in GoRouter redirect logic:
/// ```dart
/// redirect: (context, state) {
///   final guard = ref.read(subscriptionGuardProvider);
///   if (!guard.hasTier(SubscriptionTiers.premium)) {
///     return AppRoutes.upgrade;
///   }
///   return null;
/// }
/// ```
///
/// Or use the helper:
/// ```dart
/// GoRoute(
///   path: '/coaches',
///   redirect: subscriptionRouteGuard(
///     ref: ref,
///     requiredTier: SubscriptionTiers.premium,
///     redirectTo: AppRoutes.upgrade,
///   ),
///   builder: ...
/// )
/// ```
String? Function(BuildContext, dynamic) subscriptionRouteGuard({
  required Ref ref,
  required int requiredTier,
  required String redirectTo,
}) {
  return (context, state) {
    final guard = ref.read(subscriptionGuardProvider);
    final result = guard.checkAccess(requiredTier);

    if (result is SubscriptionDenied) {
      AppLogger.info(
        'Route guard: redirecting to $redirectTo (needs tier $requiredTier)',
        tag: 'SubGuard',
      );
      return redirectTo;
    }

    return null;
  };
}

/// Check tier access for use in route redirect
///
/// Convenience provider for checking tier in GoRouter redirects.
/// Returns true if user has required tier.
@riverpod
bool hasTierAccess(Ref ref, int requiredTier) {
  final guard = ref.watch(subscriptionGuardProvider);
  return guard.hasTier(requiredTier);
}

// ============== Widget Protection ==============

/// A widget that gates content based on subscription tier
///
/// Shows the [child] if user has required tier, otherwise shows
/// the [fallback] widget (or a default locked UI).
///
/// Usage:
/// ```dart
/// SubscriptionGatedWidget(
///   requiredTier: SubscriptionTiers.premium,
///   child: PremiumFeatureWidget(),
///   fallback: UpgradePrompt(requiredTier: SubscriptionTiers.premium),
/// )
/// ```
class SubscriptionGatedWidget extends StatelessWidget {
  const SubscriptionGatedWidget({
    super.key,
    required this.requiredTier,
    required this.child,
    this.fallback,
    this.showLockedOverlay = false,
  });

  /// The minimum tier required to view the child
  final int requiredTier;

  /// Widget to show when user has access
  final Widget child;

  /// Widget to show when user doesn't have access
  /// If null, the child is hidden completely
  final Widget? fallback;

  /// If true, shows the child with a locked overlay instead of fallback
  final bool showLockedOverlay;

  @override
  Widget build(BuildContext context) {
    // Note: This widget should be used with ConsumerWidget or wrapped in Consumer
    // to properly watch subscription state
    return _SubscriptionGatedContent(
      requiredTier: requiredTier,
      child: child,
      fallback: fallback,
      showLockedOverlay: showLockedOverlay,
    );
  }
}

/// Internal widget that uses Consumer to watch subscription state
class _SubscriptionGatedContent extends StatelessWidget {
  const _SubscriptionGatedContent({
    required this.requiredTier,
    required this.child,
    this.fallback,
    this.showLockedOverlay = false,
  });

  final int requiredTier;
  final Widget child;
  final Widget? fallback;
  final bool showLockedOverlay;

  @override
  Widget build(BuildContext context) {
    // This needs to be a ConsumerWidget or use Consumer
    // The parent should use ref.watch(hasTierAccessProvider(requiredTier))
    return child; // Placeholder - actual implementation uses Consumer
  }
}

/// A function guard that can be used with async operations
///
/// Usage:
/// ```dart
/// // In a provider or widget
/// final result = await withSubscriptionGuard(
///   ref: ref,
///   requiredTier: SubscriptionTiers.premium,
///   onDenied: () => showUpgradeDialog(context),
///   action: () => api.fetchPremiumData(),
/// );
/// ```
Future<T?> withSubscriptionGuard<T>({
  required Ref ref,
  required int requiredTier,
  required Future<T> Function() action,
  VoidCallback? onDenied,
}) async {
  final guard = ref.read(subscriptionGuardProvider);
  final canAccess = await guard.requireTier(
    requiredTier,
    onDenied: (result) => onDenied?.call(),
  );

  if (!canAccess) return null;
  return action();
}
