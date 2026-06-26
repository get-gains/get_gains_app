// lib/features/subscription/data/subscription_repository.dart

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/cache/cache_service.dart';
import 'models/models.dart';

part 'subscription_repository.g.dart';

/// Subscription Repository
///
/// Handles subscription status queries against the backend.
/// Purchases are handled directly by RevenueCat SDK — not routed through here.
class SubscriptionRepository {
  SubscriptionRepository({
    required ApiClient apiClient,
    required CacheService cache,
  }) : _apiClient = apiClient,
       _cache = cache;

  final ApiClient _apiClient;
  final CacheService _cache;

  static const _ckSubscriptionStatus = 'subscription_status';

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

    if (result is Success<Map<String, dynamic>, AppError>) {
      final data = result.value;
      try {
        final status = SubscriptionStatusModel.fromJson(data);
        AppLogger.info(
          'Subscription status: isSubscribed=${status.isSubscribed}, tier=${status.tier}',
          tag: 'SubRepo',
        );
        _cache.put(
          _ckSubscriptionStatus,
          jsonEncode(data),
          version: DateTime.now().toIso8601String(),
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
    }

    AppLogger.warning(
      'Server subscription status unavailable — trying cache',
      tag: 'SubRepo',
    );
    try {
      final cached = await _cache.getRaw(_ckSubscriptionStatus);
      if (cached != null) {
        final status = SubscriptionStatusModel.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
        AppLogger.info('Loaded subscription status from cache', tag: 'SubRepo');
        return Success(status);
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load cached subscription status',
        tag: 'SubRepo',
        error: e,
      );
    }

    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }
}

/// Subscription Repository Provider
@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository(
    apiClient: ref.watch(apiClientProvider),
    cache: ref.watch(cacheServiceProvider),
  );
}
