// lib/features/subscription/data/subscription_repository.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import 'models/models.dart';

part 'subscription_repository.g.dart';

/// Subscription Repository
///
/// Handles all subscription-related data operations.
/// Coordinates between:
/// - API client (server communication for verification)
/// - In-app purchase service (platform purchases)
///
/// Usage:
/// ```dart
/// final subRepo = ref.read(subscriptionRepositoryProvider);
///
/// // Get available plans
/// final plans = await subRepo.getPlans();
///
/// // Get subscription status
/// final status = await subRepo.getSubscriptionStatus();
///
/// // Verify a purchase
/// final result = await subRepo.verifyPurchase(
///   productId: 'premium_monthly',
///   purchaseToken: 'token...',
///   provider: PaymentProvider.googlePay,
/// );
/// ```
class SubscriptionRepository {
  SubscriptionRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============== Plans ==============

  /// Get all available subscription plans
  ///
  /// Returns active plans sorted by sort order.
  /// These plans correspond to in-app purchase products.
  Future<Result<List<PlanModel>, AppError>> getPlans() async {
    AppLogger.debug('Fetching subscription plans', tag: 'SubRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.subscriptionPlans,
    );

    return result.when(
      success: (data) {
        try {
          final plansList = data['plans'] as List<dynamic>;
          final plans = plansList
              .map((p) => PlanModel.fromJson(p as Map<String, dynamic>))
              .toList();

          AppLogger.info(
            'Fetched ${plans.length} subscription plans',
            tag: 'SubRepo',
          );
          return Success(plans);
        } catch (e) {
          AppLogger.error('Failed to parse plans', tag: 'SubRepo', error: e);
          return Failure(
            UnknownError(message: 'Failed to parse plans', originalError: e),
          );
        }
      },
      failure: (error) {
        AppLogger.error('Failed to fetch plans', tag: 'SubRepo', error: error);
        return Failure(error);
      },
    );
  }

  // ============== Subscription Status ==============

  /// Get current user's subscription status
  ///
  /// Returns:
  /// - Whether user is subscribed
  /// - Current subscription details (if any)
  /// - Optional history if requested
  Future<Result<SubscriptionStatusModel, AppError>> getSubscriptionStatus({
    bool includeHistory = false,
  }) async {
    AppLogger.debug('Fetching subscription status', tag: 'SubRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.subscriptionStatus,
      queryParameters: {'includeHistory': includeHistory},
    );

    return result.when(
      success: (data) {
        try {
          final status = SubscriptionStatusModel.fromJson(data);
          AppLogger.info(
            'Subscription status: isSubscribed=${status.isSubscribed}',
            tag: 'SubRepo',
          );
          return Success(status);
        } catch (e) {
          AppLogger.error(
            'Failed to parse subscription status',
            tag: 'SubRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse subscription status',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch subscription status',
          tag: 'SubRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  // ============== Purchase Verification ==============

  /// Verify a purchase with the backend
  ///
  /// After a successful in-app purchase, call this to:
  /// 1. Verify the purchase with the provider (Google Play)
  /// 2. Create/update subscription in database
  /// 3. Return the activated subscription
  ///
  /// [productId] - The product ID purchased
  /// [purchaseToken] - The purchase token from the store
  /// [provider] - The payment provider (currently only Google Pay)
  Future<Result<VerifyPurchaseResponse, AppError>> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required PaymentProvider provider,
  }) async {
    AppLogger.debug(
      'Verifying purchase: productId=$productId, provider=$provider',
      tag: 'SubRepo',
    );

    final request = VerifyPurchaseRequest(
      productId: productId,
      purchaseToken: purchaseToken,
      provider: provider,
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.subscriptionVerify,
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        try {
          final response = VerifyPurchaseResponse.fromJson(data);
          AppLogger.info(
            'Purchase verified: success=${response.success}',
            tag: 'SubRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse verify response',
            tag: 'SubRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse verification response',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Purchase verification failed',
          tag: 'SubRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  // ============== Subscription History ==============

  /// Get subscription history
  ///
  /// Returns past subscriptions for the user.
  Future<Result<List<SubscriptionHistoryItem>, AppError>>
  getSubscriptionHistory({int limit = 10, int offset = 0}) async {
    AppLogger.debug('Fetching subscription history', tag: 'SubRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.subscriptionHistory,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.when(
      success: (data) {
        try {
          final historyList = data['subscriptions'] as List<dynamic>;
          final history = historyList
              .map(
                (h) =>
                    SubscriptionHistoryItem.fromJson(h as Map<String, dynamic>),
              )
              .toList();

          AppLogger.info(
            'Fetched ${history.length} history items',
            tag: 'SubRepo',
          );
          return Success(history);
        } catch (e) {
          AppLogger.error(
            'Failed to parse subscription history',
            tag: 'SubRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse subscription history',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch subscription history',
          tag: 'SubRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }
}

/// Subscription Repository Provider
@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository(apiClient: ref.watch(apiClientProvider));
}
