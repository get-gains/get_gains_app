// lib/features/subscription/presentation/providers/subscription_guard.dart
//
// LEGACY — will be replaced by AccessGuard in Session 2.
// Adapted to compile with the new 2-tier model (FREE/PREMIUM).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/app_error.dart';
import '../../data/models/models.dart';
import '../models/subscription_feature.dart';
import '../widgets/upgrade_prompt.dart';
import 'subscription_provider.dart';

part 'subscription_guard.g.dart';

/// Subscription tier levels (legacy compat — maps to 2-tier model)
abstract class SubscriptionTiers {
  static const int free = 0;
  static const int basic = 1;
  static const int premium = 2;
  static const int pro = 3;
}

/// Result of a subscription guard check
sealed class SubscriptionGuardResult {
  const SubscriptionGuardResult();
}

class SubscriptionGranted extends SubscriptionGuardResult {
  const SubscriptionGranted();
}

class SubscriptionDenied extends SubscriptionGuardResult {
  const SubscriptionDenied({
    required this.requiredTier,
    required this.currentTier,
    required this.requiredTierName,
    this.message,
  });

  final int requiredTier;
  final int currentTier;
  final String requiredTierName;
  final String? message;

  String get defaultMessage {
    return 'This feature requires a $requiredTierName subscription';
  }
}

class SubscriptionPending extends SubscriptionGuardResult {
  const SubscriptionPending();
}

@riverpod
SubscriptionGuard subscriptionGuard(Ref ref) {
  return SubscriptionGuard(ref);
}

class SubscriptionGuard {
  SubscriptionGuard(this._ref);

  final Ref _ref;

  /// Map the new 2-tier model to legacy int tier.
  int _tierToInt(SubscriptionTier tier) =>
      tier == SubscriptionTier.premium ? SubscriptionTiers.premium : SubscriptionTiers.free;

  SubscriptionGuardResult checkAccess(int requiredTier) {
    final state = _ref.read(subscriptionProvider);

    if (state is SubscriptionError) {
      return requiredTier <= 0
          ? const SubscriptionGranted()
          : SubscriptionDenied(
              requiredTier: requiredTier,
              currentTier: 0,
              requiredTierName: 'Premium',
            );
    }

    if (state is! SubscriptionLoaded) {
      return const SubscriptionPending();
    }

    final currentTier = _tierToInt(state.status.subscriptionTier);

    if (currentTier >= requiredTier) {
      return const SubscriptionGranted();
    }

    return SubscriptionDenied(
      requiredTier: requiredTier,
      currentTier: currentTier,
      requiredTierName: 'Premium',
    );
  }

  bool hasTier(int requiredTier) {
    final result = checkAccess(requiredTier);
    return result is SubscriptionGranted;
  }

  bool get isSubscribed => hasTier(SubscriptionTiers.basic);

  int get currentTier {
    final state = _ref.read(subscriptionProvider);
    if (state is SubscriptionLoaded) {
      return _tierToInt(state.status.subscriptionTier);
    }
    return 0;
  }

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
        AppLogger.debug('Waiting for subscription to load', tag: 'SubGuard');
        await _waitForSubscription();
        return requireTier(requiredTier, onDenied: onDenied);
    }
  }

  Future<void> _waitForSubscription() async {
    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final state = _ref.read(subscriptionProvider);
      if (state is SubscriptionLoaded || state is SubscriptionError) {
        return;
      }
    }
  }
}

extension SubscriptionGuardExtension on SubscriptionGuard {
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

@riverpod
bool hasTierAccess(Ref ref, int requiredTier) {
  final guard = ref.watch(subscriptionGuardProvider);
  return guard.hasTier(requiredTier);
}

/// Legacy gating widget — will be replaced by AccessGated in Session 2.
class SubscriptionGatedWidget extends ConsumerWidget {
  const SubscriptionGatedWidget({
    super.key,
    required this.requiredTier,
    required this.child,
    this.fallback,
    this.feature,
    this.compact = false,
    this.showLockedOverlay = false,
  });

  final int requiredTier;
  final Widget child;
  final Widget? fallback;
  final SubscriptionFeature? feature;
  final bool compact;
  final bool showLockedOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);

    if (subState is SubscriptionInitial || subState is SubscriptionLoading) {
      return _buildLoadingSkeleton(context);
    }

    if (subState is! SubscriptionLoaded) {
      return child;
    }

    final guard = ref.read(subscriptionGuardProvider);
    if (guard.hasTier(requiredTier)) {
      return child;
    }

    final subscriptionStatus = subState.status.subscription?.status;

    return _buildFallback(context, subscriptionStatus: subscriptionStatus);
  }

  Widget _buildFallback(
    BuildContext context, {
    SubscriptionStatus? subscriptionStatus,
  }) {
    if (fallback != null) return fallback!;

    if (feature != null) {
      return UpgradePrompt(
        feature: feature,
        requiredTier: requiredTier,
        compact: compact,
        subscriptionStatus: subscriptionStatus,
      );
    }

    return const SizedBox.shrink();
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
