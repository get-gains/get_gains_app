// lib/features/subscription/data/models/subscription_status_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import 'subscription_model.dart';

part 'subscription_status_model.freezed.dart';
part 'subscription_status_model.g.dart';

/// Full subscription status response from server
///
/// Contains:
/// - Whether user has active subscription
/// - Current subscription details (if any)
/// - Optional subscription history
@freezed
abstract class SubscriptionStatusModel with _$SubscriptionStatusModel {
  const factory SubscriptionStatusModel({
    required bool isSubscribed,
    SubscriptionModel? subscription,
    List<SubscriptionHistoryItem>? history,
  }) = _SubscriptionStatusModel;

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatusModelFromJson(json);
}

/// Verify purchase request
@freezed
abstract class VerifyPurchaseRequest with _$VerifyPurchaseRequest {
  const factory VerifyPurchaseRequest({
    required String productId,
    required String purchaseToken,
    required PaymentProvider provider,
  }) = _VerifyPurchaseRequest;

  factory VerifyPurchaseRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyPurchaseRequestFromJson(json);
}

/// Verify purchase response
@freezed
abstract class VerifyPurchaseResponse with _$VerifyPurchaseResponse {
  const factory VerifyPurchaseResponse({
    required bool success,
    SubscriptionModel? subscription,
  }) = _VerifyPurchaseResponse;

  factory VerifyPurchaseResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyPurchaseResponseFromJson(json);
}

/// Extension for subscription status utilities
extension SubscriptionStatusModelX on SubscriptionStatusModel {
  /// Get the current tier level (0 if no subscription)
  int get tierLevel => subscription?.tierLevel ?? 0;

  /// Check if user has at least the required tier
  bool hasTier(int requiredTier) => tierLevel >= requiredTier;
}
