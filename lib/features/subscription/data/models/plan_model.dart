// lib/features/subscription/data/models/plan_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_model.freezed.dart';
part 'plan_model.g.dart';

/// Billing cycle options
enum BillingCycle {
  @JsonValue('DAILY')
  daily,
  @JsonValue('WEEKLY')
  weekly,
  @JsonValue('MONTHLY')
  monthly,
  @JsonValue('QUARTERLY')
  quarterly,
  @JsonValue('SEMIANNUALLY')
  semiannually,
  @JsonValue('YEARLY')
  yearly,
}

/// Subscription plan from the server
///
/// Represents a purchasable subscription plan with pricing,
/// features, and tier level for access control.
@freezed
abstract class PlanModel with _$PlanModel {
  const factory PlanModel({
    required String id,
    required String name,
    required String description,
    required int priceCents,
    @Default('PHP') String currency,
    required BillingCycle billingCycle,
    @Default([]) List<String> features,
    int? trialPeriodDays,
    required String productId,
    @Default(0) int tierLevel,
  }) = _PlanModel;

  factory PlanModel.fromJson(Map<String, dynamic> json) =>
      _$PlanModelFromJson(json);
}

/// Extension for plan utilities
extension PlanModelX on PlanModel {
  /// Get formatted price (e.g., "₱299.00")
  String get formattedPrice {
    final amount = priceCents / 100;
    final symbol = currency == 'PHP' ? '₱' : '\$';
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Get billing cycle display name
  String get billingCycleDisplay {
    switch (billingCycle) {
      case BillingCycle.daily:
        return 'day';
      case BillingCycle.weekly:
        return 'week';
      case BillingCycle.monthly:
        return 'month';
      case BillingCycle.quarterly:
        return '3 months';
      case BillingCycle.semiannually:
        return '6 months';
      case BillingCycle.yearly:
        return 'year';
    }
  }

  /// Get full price description (e.g., "₱299.00/month")
  String get priceDescription => '$formattedPrice/$billingCycleDisplay';
}
