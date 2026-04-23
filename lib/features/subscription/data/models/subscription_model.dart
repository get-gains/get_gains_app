// lib/features/subscription/data/models/subscription_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

/// RC subscription status enum matching server's RcSubscriptionStatus.
enum SubscriptionStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('TRIALING')
  trialing,
  @JsonValue('GRACE_PERIOD')
  gracePeriod,
  @JsonValue('PAUSED')
  paused,
  @JsonValue('EXPIRED')
  expired,
  @JsonValue('CANCELLED')
  cancelled,
}

/// Active subscription detail from GET /subscriptions/status.
@freezed
abstract class SubscriptionDetail with _$SubscriptionDetail {
  const factory SubscriptionDetail({
    required SubscriptionStatus status,
    required String store,
    required String productId,
    required String entitlementId,
    required DateTime currentPeriodStart,
    required DateTime currentPeriodEnd,
    @Default(false) bool cancelAtPeriodEnd,
    @Default(true) bool willRenew,
  }) = _SubscriptionDetail;

  factory SubscriptionDetail.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionDetailFromJson(json);
}

/// Extension for subscription detail utilities.
extension SubscriptionDetailX on SubscriptionDetail {
  /// Whether the subscription is currently active (active or trialing).
  bool get isActive =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.trialing;

  /// Whether the subscription will expire (not renewing).
  bool get willExpire => cancelAtPeriodEnd || !willRenew;

  /// Days remaining in current period.
  int get daysRemaining {
    final now = DateTime.now();
    if (currentPeriodEnd.isBefore(now)) return 0;
    return currentPeriodEnd.difference(now).inDays;
  }
}
