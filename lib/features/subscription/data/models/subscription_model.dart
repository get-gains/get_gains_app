// lib/features/subscription/data/models/subscription_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import 'plan_model.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

/// Subscription status enum matching server
enum SubscriptionStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('PAST_DUE')
  pastDue,
  @JsonValue('CANCELED')
  canceled,
  @JsonValue('EXPIRED')
  expired,
  @JsonValue('REVOKED')
  revoked,
}

/// Payment provider enum matching server
enum PaymentProvider {
  @JsonValue('GOOGLE_PAY')
  googlePay,
}

/// Plan summary for subscription response
@freezed
abstract class PlanSummary with _$PlanSummary {
  const factory PlanSummary({
    required String id,
    required String name,
    required BillingCycle billingCycle,
    @Default(0) int tierLevel,
  }) = _PlanSummary;

  factory PlanSummary.fromJson(Map<String, dynamic> json) =>
      _$PlanSummaryFromJson(json);
}

/// Active subscription details
@freezed
abstract class SubscriptionModel with _$SubscriptionModel {
  const factory SubscriptionModel({
    required String id,
    required SubscriptionStatus status,
    required PlanSummary plan,
    required DateTime currentPeriodStart,
    required DateTime currentPeriodEnd,
    required DateTime nextBillingDate,
    @Default(false) bool cancelAtPeriodEnd,
    @Default(true) bool autoRenew,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);
}

/// Subscription history item
@freezed
abstract class SubscriptionHistoryItem with _$SubscriptionHistoryItem {
  const factory SubscriptionHistoryItem({
    required String id,
    required SubscriptionStatus status,
    required String planName,
    required DateTime startDate,
    DateTime? endedAt,
  }) = _SubscriptionHistoryItem;

  factory SubscriptionHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionHistoryItemFromJson(json);
}

/// Extension for subscription utilities
extension SubscriptionModelX on SubscriptionModel {
  /// Whether the subscription is currently active
  bool get isActive => status == SubscriptionStatus.active;

  /// Whether the subscription will expire (not auto-renewing)
  bool get willExpire => cancelAtPeriodEnd || !autoRenew;

  /// Days remaining in current period
  int get daysRemaining {
    final now = DateTime.now();
    if (currentPeriodEnd.isBefore(now)) return 0;
    return currentPeriodEnd.difference(now).inDays;
  }

  /// Get tier level from plan
  int get tierLevel => plan.tierLevel;
}
