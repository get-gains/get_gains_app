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
/// Handles subscription status queries against the backend.
/// Purchases are handled directly by RevenueCat SDK — not routed through here.
class SubscriptionRepository {
  SubscriptionRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============== Subscription Status ==============

  /// Get current user's subscription status (backend source of truth).
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
            'Subscription status: isSubscribed=${status.isSubscribed}, tier=${status.tier}',
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
}

/// Subscription Repository Provider
@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository(apiClient: ref.watch(apiClientProvider));
}
