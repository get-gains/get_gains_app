// lib/features/subscription/presentation/providers/subscription_provider.dart

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/models.dart';
import '../../data/subscription_repository.dart';
import '../../services/in_app_purchase_service.dart';

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
    required this.plans,
    this.purchaseInProgress = false,
    this.purchaseError,
  });

  /// Current subscription status
  final SubscriptionStatusModel status;

  /// Available plans for purchase
  final List<PlanModel> plans;

  /// Whether a purchase is currently in progress
  final bool purchaseInProgress;

  /// Error message from last purchase attempt
  final String? purchaseError;

  SubscriptionLoaded copyWith({
    SubscriptionStatusModel? status,
    List<PlanModel>? plans,
    bool? purchaseInProgress,
    String? purchaseError,
  }) {
    return SubscriptionLoaded(
      status: status ?? this.status,
      plans: plans ?? this.plans,
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
/// - Loads subscription status and plans
/// - Handles purchase flow
/// - Updates state after purchases
///
/// Usage:
/// ```dart
/// // Watch subscription state
/// final state = ref.watch(subscriptionNotifierProvider);
///
/// // Load subscription data
/// await ref.read(subscriptionNotifierProvider.notifier).load();
///
/// // Purchase a plan
/// await ref.read(subscriptionNotifierProvider.notifier).purchase('premium_monthly');
/// ```
@Riverpod(keepAlive: true)
class SubscriptionNotifier extends _$SubscriptionNotifier {
  late SubscriptionRepository _repository;
  late InAppPurchaseService _iapService;
  StreamSubscription<PurchaseResult>? _purchaseSubscription;

  @override
  SubscriptionState build() {
    _repository = ref.watch(subscriptionRepositoryProvider);
    _iapService = ref.watch(inAppPurchaseServiceProvider);

    // Listen to purchase results
    _purchaseSubscription = _iapService.purchaseResults.listen(
      _handlePurchaseResult,
    );

    ref.onDispose(() {
      _purchaseSubscription?.cancel();
    });

    // Auto-load on first access
    Future.microtask(() => load());

    return const SubscriptionInitial();
  }

  /// Load subscription status and available plans
  Future<void> load() async {
    state = const SubscriptionLoading();

    AppLogger.debug('Loading subscription data', tag: 'SubProvider');

    // Fetch status and plans in parallel
    final results = await Future.wait([
      _repository.getSubscriptionStatus(),
      _repository.getPlans(),
    ]);

    final statusResult = results[0] as dynamic;
    final plansResult = results[1] as dynamic;

    // Check for errors
    if (statusResult.isFailure) {
      state = SubscriptionError(error: statusResult.error as AppError);
      return;
    }

    if (plansResult.isFailure) {
      state = SubscriptionError(error: plansResult.error as AppError);
      return;
    }

    final status = statusResult.value as SubscriptionStatusModel;
    final plans = plansResult.value as List<PlanModel>;

    // Initialize IAP service with product IDs
    if (!_iapService.isInitialized) {
      final productIds = plans.map((p) => p.productId).toList();
      await _iapService.initialize(productIds);
    }

    state = SubscriptionLoaded(status: status, plans: plans);

    AppLogger.info(
      'Subscription loaded: isSubscribed=${status.isSubscribed}, tier=${status.tierLevel}',
      tag: 'SubProvider',
    );
  }

  /// Refresh subscription status only (faster than full load)
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
          'Subscription refreshed: isSubscribed=${status.isSubscribed}',
          tag: 'SubProvider',
        );
      },
      failure: (error) {
        AppLogger.error(
          'Failed to refresh subscription',
          tag: 'SubProvider',
          error: error,
        );
        // Keep current state, don't fail completely
      },
    );
  }

  /// Purchase a subscription plan
  ///
  /// [productId] - The product ID from the plan to purchase
  Future<bool> purchase(String productId) async {
    final currentState = state;
    if (currentState is! SubscriptionLoaded) {
      AppLogger.warning(
        'Cannot purchase - subscription not loaded',
        tag: 'SubProvider',
      );
      return false;
    }

    state = currentState.copyWith(
      purchaseInProgress: true,
      purchaseError: null,
    );

    AppLogger.debug('Starting purchase for: $productId', tag: 'SubProvider');

    final result = await _iapService.purchaseProduct(productId);

    if (result.isError) {
      state = currentState.copyWith(
        purchaseInProgress: false,
        purchaseError: result.errorMessage,
      );
      return false;
    }

    // Purchase initiated - wait for result via stream
    // The _handlePurchaseResult will update state
    return true;
  }

  /// Handle purchase result from IAP service
  void _handlePurchaseResult(PurchaseResult result) async {
    final currentState = state;
    if (currentState is! SubscriptionLoaded) return;

    switch (result.status) {
      case PurchaseState.completed:
        AppLogger.info('Purchase completed, verifying...', tag: 'SubProvider');

        // Verify with backend
        final purchase = result.purchaseDetails!;
        final token = _iapService.getPurchaseToken(purchase);

        if (token != null) {
          final verifyResult = await _repository.verifyPurchase(
            productId: purchase.productID,
            purchaseToken: token,
            provider: _iapService.currentProvider,
          );

          await verifyResult.when(
            success: (response) async {
              if (response.success) {
                AppLogger.info(
                  'Purchase verified successfully',
                  tag: 'SubProvider',
                );
                // Refresh to get updated status
                await refresh();
                state = (state as SubscriptionLoaded).copyWith(
                  purchaseInProgress: false,
                );
              } else {
                state = currentState.copyWith(
                  purchaseInProgress: false,
                  purchaseError: 'Purchase verification failed',
                );
              }
            },
            failure: (error) {
              state = currentState.copyWith(
                purchaseInProgress: false,
                purchaseError: error.message,
              );
            },
          );
        } else {
          state = currentState.copyWith(
            purchaseInProgress: false,
            purchaseError: 'Could not get purchase token',
          );
        }
        break;

      case PurchaseState.canceled:
        AppLogger.info('Purchase canceled by user', tag: 'SubProvider');
        state = currentState.copyWith(purchaseInProgress: false);
        break;

      case PurchaseState.error:
        AppLogger.error(
          'Purchase error: ${result.errorMessage}',
          tag: 'SubProvider',
        );
        state = currentState.copyWith(
          purchaseInProgress: false,
          purchaseError: result.errorMessage,
        );
        break;

      case PurchaseState.pending:
        AppLogger.info('Purchase pending', tag: 'SubProvider');
        // Keep purchase in progress
        break;

      case PurchaseState.idle:
      case PurchaseState.purchasing:
        // No action needed
        break;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    final currentState = state;
    if (currentState is! SubscriptionLoaded) return;

    state = currentState.copyWith(purchaseInProgress: true);

    await _iapService.restorePurchases();

    // The results will come through the purchase stream
    // Give it a moment then refresh
    await Future.delayed(const Duration(seconds: 2));
    await refresh();

    state = (state as SubscriptionLoaded).copyWith(purchaseInProgress: false);
  }
}

// ============== Convenience Providers ==============

/// Whether the user has an active subscription
@riverpod
bool isSubscribed(Ref ref) {
  final state = ref.watch(subscriptionProvider);
  if (state is SubscriptionLoaded) {
    return state.status.isSubscribed;
  }
  return false;
}

/// Current subscription tier level (0 if none)
@riverpod
int subscriptionTier(Ref ref) {
  final state = ref.watch(subscriptionProvider);
  if (state is SubscriptionLoaded) {
    return state.status.tierLevel;
  }
  return 0;
}

/// Current subscription (null if none)
@riverpod
SubscriptionModel? currentSubscription(Ref ref) {
  final state = ref.watch(subscriptionProvider);
  if (state is SubscriptionLoaded) {
    return state.status.subscription;
  }
  return null;
}

/// Available plans for purchase
@riverpod
List<PlanModel> availablePlans(Ref ref) {
  final state = ref.watch(subscriptionProvider);
  if (state is SubscriptionLoaded) {
    return state.plans;
  }
  return [];
}

/// Get plan name for a specific tier level
///
/// Returns the plan name from available plans, or 'Subscription' if not found.
/// Useful for displaying tier names in UI without hardcoding.
@riverpod
String planNameForTier(Ref ref, int tierLevel) {
  final plans = ref.watch(availablePlansProvider);

  // Find a plan with matching tier level
  final matchingPlan = plans.where((p) => p.tierLevel == tierLevel).firstOrNull;
  if (matchingPlan != null) {
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
          r'[_-](monthly|yearly|annual|weekly|daily)$',
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
