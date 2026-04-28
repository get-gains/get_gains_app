// lib/features/subscription/data/models/subscription_status_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import 'subscription_model.dart';
import 'subscription_tier.dart';

part 'subscription_status_model.freezed.dart';
part 'subscription_status_model.g.dart';

/// Full subscription status response from GET /subscriptions/status.
///
/// Contains:
/// - Whether user has active subscription
/// - Current tier (FREE/PREMIUM)
/// - Current subscription details (if any)
@freezed
abstract class SubscriptionStatusModel with _$SubscriptionStatusModel {
  const factory SubscriptionStatusModel({
    required bool isSubscribed,
    @Default('FREE') String tier,
    SubscriptionDetail? subscription,
  }) = _SubscriptionStatusModel;

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatusModelFromJson(json);
}

/// Extension for subscription status utilities.
extension SubscriptionStatusModelX on SubscriptionStatusModel {
  /// Get the parsed [SubscriptionTier].
  SubscriptionTier get subscriptionTier => SubscriptionTier.fromString(tier);
}
