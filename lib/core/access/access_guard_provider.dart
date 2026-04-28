// lib/core/access/access_guard_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/subscription/data/models/models.dart';
import '../../features/subscription/presentation/providers/subscription_provider.dart';
import '../../providers/auth_state_provider.dart';
import '../utils/app_error.dart';
import '../utils/logger.dart';
import '../utils/result.dart';
import 'access_guard.dart';

part 'access_guard_provider.g.dart';

@riverpod
AccessGuard accessGuard(Ref ref) {
  return AccessGuard(ref);
}

class AccessGuard {
  AccessGuard(this._ref);

  final Ref _ref;

  /// Synchronous check reading current auth + subscription state.
  AccessDecision evaluate(AccessRequirement req) {
    // Auth check
    if (req.requireAuth) {
      final authState = _ref.read(authStateProvider);
      if (!authState.isAuthenticated) {
        return const AccessDeniedUnauthenticated();
      }
    }

    // Tier check
    if (req.requireTier != null) {
      final subState = _ref.read(subscriptionProvider);

      if (subState is SubscriptionInitial || subState is SubscriptionLoading) {
        return const AccessPending();
      }

      if (subState is SubscriptionError) {
        // On error, deny tier-gated access
        return AccessDeniedTier(
          required: req.requireTier!,
          current: SubscriptionTier.free,
        );
      }

      if (subState is SubscriptionLoaded) {
        final currentTier = subState.status.subscriptionTier;
        if (req.requireTier == SubscriptionTier.premium &&
            currentTier != SubscriptionTier.premium) {
          return AccessDeniedTier(
            required: req.requireTier!,
            current: currentTier,
          );
        }
      }
    }

    return const AccessGranted();
  }

  /// Async version — waits for subscription to load before evaluating.
  Future<AccessDecision> evaluateAsync(AccessRequirement req) async {
    final decision = evaluate(req);
    if (decision is! AccessPending) return decision;

    // Wait for subscription to resolve
    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final result = evaluate(req);
      if (result is! AccessPending) return result;
    }

    // Timed out — treat as denied
    AppLogger.warning(
      'AccessGuard timed out waiting for subscription',
      tag: 'AccessGuard',
    );
    return AccessDeniedTier(
      required: req.requireTier ?? SubscriptionTier.premium,
      current: SubscriptionTier.free,
    );
  }

  /// Wraps an API call behind an access check.
  Future<Result<T, AppError>> guardedCall<T>(
    AccessRequirement req,
    Future<Result<T, AppError>> Function() fn,
  ) async {
    final decision = await evaluateAsync(req);

    switch (decision) {
      case AccessGranted():
        return fn();
      case AccessDeniedUnauthenticated():
        return Failure(
          AuthError(
            message: 'Authentication required',
            transportCode: 'AUTH_REQUIRED',
          ),
        );
      case AccessDeniedTier(:final required):
        AppLogger.info(
          'Guarded call denied: requires ${required.name}',
          tag: 'AccessGuard',
        );
        return Failure(
          AuthError(
            message: 'Subscription required (${required.name})',
            transportCode: 'SUBSCRIPTION_REQUIRED',
          ),
        );
      case AccessPending():
        return Failure(
          AuthError(
            message: 'Subscription state pending',
            transportCode: 'SUBSCRIPTION_PENDING',
          ),
        );
    }
  }
}
