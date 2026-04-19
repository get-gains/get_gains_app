// lib/core/access/access_guard.dart

import '../../features/subscription/data/models/subscription_tier.dart';

/// Describes what access level a route, widget, or function call requires.
class AccessRequirement {
  const AccessRequirement({this.requireAuth = true, this.requireTier});

  /// Whether the caller must be authenticated.
  final bool requireAuth;

  /// Minimum tier needed. `null` = no tier check.
  final SubscriptionTier? requireTier;
}

/// Result of evaluating an [AccessRequirement].
sealed class AccessDecision {
  const AccessDecision();
}

class AccessGranted extends AccessDecision {
  const AccessGranted();
}

class AccessPending extends AccessDecision {
  const AccessPending();
}

class AccessDeniedUnauthenticated extends AccessDecision {
  const AccessDeniedUnauthenticated();
}

class AccessDeniedTier extends AccessDecision {
  const AccessDeniedTier({required this.required, required this.current});

  final SubscriptionTier required;
  final SubscriptionTier current;
}
