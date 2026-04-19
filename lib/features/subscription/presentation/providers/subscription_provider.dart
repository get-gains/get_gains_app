// lib/features/subscription/presentation/providers/subscription_provider.dart

import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/models.dart';
import '../../data/subscription_repository.dart';
import '../../services/revenuecat_error_mapper.dart';
import '../../services/revenuecat_service.dart';

part 'subscription_provider.g.dart';

/// Subscription UI State
sealed class SubscriptionState {
  const SubscriptionState();
}

/// Initial state - not yet loaded
class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

/// Loading subscription data
class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

/// Subscription data loaded
class SubscriptionLoaded extends SubscriptionState {
  const SubscriptionLoaded({
    required this.status,
    this.currentOffering,
    this.purchaseInProgress = false,
    this.purchaseError,
  });

  /// Current subscription status (from backend — source of truth)
  final SubscriptionStatusModel status;

  /// Current RC offering (packages to display)
  final Offering? currentOffering;

  /// Whether a purchase is currently in progress
  final bool purchaseInProgress;

  /// Error message from last purchase attempt
  final String? purchaseError;

  SubscriptionLoaded copyWith({
    SubscriptionStatusModel? status,
    Offering? currentOffering,
    bool? purchaseInProgress,
    String? purchaseError,
  }) {
    return SubscriptionLoaded(
      status: status ?? this.status,
      currentOffering: currentOffering ?? this.currentOffering,
      purchaseInProgress: purchaseInProgress ?? this.purchaseInProgress,
      purchaseError: purchaseError,
    );
  }
}

/// Error loading subscription data
class SubscriptionError extends SubscriptionState {
  const SubscriptionError({required this.error});

  final AppError error;
}

/// Subscription State Notifier
///
/// Manages subscription state for the app:
/// - Loads subscription status from backend (source of truth)
/// - Loads RC offerings for paywall display
/// - Handles purchase flow via RevenueCat SDK
/// - Polls backend with backoff after purchase for webhook reconciliation
@Riverpod(keepAlive: true)
class SubscriptionNotifier extends _$SubscriptionNotifier {
  late SubscriptionRepository _repository;
  late RevenueCatService _rcService;

  @override
  SubscriptionState build() {
    _repository = ref.watch(subscriptionRepositoryProvider);
    _rcService = ref.watch(revenueCatServiceProvider);

    // Auto-load on first access
    Future.microtask(() => load());

    return const SubscriptionInitial();
  }

  /// Load subscription status and RC offerings in parallel.
  Future<void> load() async {
    state = const SubscriptionLoading();

    AppLogger.debug('Loading subscription data', tag: 'SubProvider');

    // Fetch backend status and RC offerings in parallel
    final results = await Future.wait([
      _repository.getSubscriptionStatus(),
      _fetchOfferings(),
    ]);

    final statusResult = results[0] as dynamic;
    final offering = results[1] as Offering?;

    if (statusResult.isFailure) {
      state = SubscriptionError(error: statusResult.error as AppError);
      return;
    }

    final status = statusResult.value as SubscriptionStatusModel;

    state = SubscriptionLoaded(
      status: status,
      currentOffering: offering,
    );

    AppLogger.info(
      'Subscription loaded: isSubscribed=${status.isSubscribed}, tier=${status.tier}',
      tag: 'SubProvider',
    );
  }

  /// Refresh subscription status only (no offerings refetch).
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is! SubscriptionLoaded) {
      await load();
      return;
    }

    AppLogger.debug('Refreshing subscription status', tag: 'SubProvider');

    final result = await _repository.getSubscriptionStatus();

    result.when(
      success: (status) {
        state = currentState.copyWith(status: status);
        AppLogger.info(
          'Subscription refreshed: isSubscribed=${status.isSubscribed}, tier=${status.tier}',
          tag: 'SubProvider',
        );
      },
      failure: (error) {
        AppLogger.error(
          'Failed to refresh subscription',
          tag: 'SubProvider',
          error: error,
        );
        // Keep current state on refresh failure
      },
    );
  }

  /// Purchase a package via RevenueCat.
  ///
  /// After purchase succeeds, polls backend with backoff to wait
  /// for webhook reconciliation before declaring PREMIUM.
  Future<void> purchase(Package package) async {
    final currentState = state;
    if (currentState is! SubscriptionLoaded) return;

    state = currentState.copyWith(
      purchaseInProgress: true,
      purchaseError: null,
    );

    AppLogger.debug(
      'Starting purchase for: ${package.storeProduct.identifier}',
      tag: 'SubProvider',
    );

    try {
      await _rcService.purchase(package);

      // Purchase succeeded — poll backend with backoff for webhook lag
      await _pollForPremium(currentState);
    } on Exception catch (e) {
      final errorMsg = RevenueCatErrorMapper.mapError(e);

      if (RevenueCatErrorMapper.isUserCanceled(e)) {
        AppLogger.info('Purchase canceled by user', tag: 'SubProvider');
        state = currentState.copyWith(purchaseInProgress: false);
        return;
      }

      AppLogger.error('Purchase error: $errorMsg', tag: 'SubProvider');
      state = currentState.copyWith(
        purchaseInProgress: false,
        purchaseError: errorMsg,
      );
    }
  }

  /// Restore purchases via RevenueCat, then poll backend.
  Future<void> restorePurchases() async {
    final currentState = state;
    if (currentState is! SubscriptionLoaded) return;

    state = currentState.copyWith(purchaseInProgress: true);

    try {
      await _rcService.restorePurchases();
      await _pollForPremium(currentState);
    } on Exception catch (e) {
      final errorMsg = RevenueCatErrorMapper.mapError(e);
      AppLogger.error('Restore error: $errorMsg', tag: 'SubProvider');
      state = currentState.copyWith(
        purchaseInProgress: false,
        purchaseError: errorMsg,
      );
    }
  }

  /// Poll backend with backoff: 1s → 2s → 5s.
  /// Bail as soon as backend reports PREMIUM. Max ~8s total.
  Future<void> _pollForPremium(SubscriptionLoaded prePurchaseState) async {
    const delays = [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
    ];

    for (final delay in delays) {
      await refresh();

      final current = state;
      if (current is SubscriptionLoaded &&
          current.status.subscriptionTier == SubscriptionTier.premium) {
        state = current.copyWith(purchaseInProgress: false);
        AppLogger.info(
          'Backend confirmed PREMIUM after purchase',
          tag: 'SubProvider',
        );
        return;
      }

      await Future.delayed(delay);
    }

    // Final attempt
    await refresh();
    final finalState = state;
    if (finalState is SubscriptionLoaded) {
      state = finalState.copyWith(purchaseInProgress: false);
      if (finalState.status.subscriptionTier != SubscriptionTier.premium) {
        AppLogger.warning(
          'Backend still reports FREE after polling — webhook may be delayed',
          tag: 'SubProvider',
        );
      }
    }
  }

  /// Fetch current RC offering (null on failure — non-fatal).
  Future<Offering?> _fetchOfferings() async {
    try {
      final offerings = await _rcService.getOfferings();
      return offerings.current;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch RC offerings: $e',
        tag: 'SubProvider',
      );
      return null;
    }
  }
}

// ============== Convenience Providers ==============

/// Whether the user has an active subscription.
@riverpod
bool isSubscribed(Ref ref) {
  final state = ref.watch(subscriptionProvider);
  if (state is SubscriptionLoaded) {
    return state.status.isSubscribed;
  }
  return false;
}

/// Current subscription tier.
@riverpod
SubscriptionTier subscriptionTier(Ref ref) {
  final state = ref.watch(subscriptionProvider);
  if (state is SubscriptionLoaded) {
    return state.status.subscriptionTier;
  }
  return SubscriptionTier.free;
}

/// Available RC packages for purchase.
@riverpod
List<Package> availablePackages(Ref ref) {
  final state = ref.watch(subscriptionProvider);
  if (state is SubscriptionLoaded) {
    return state.currentOffering?.availablePackages ?? [];
  }
  return [];
}
