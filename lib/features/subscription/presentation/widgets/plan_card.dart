// lib/features/subscription/presentation/widgets/plan_card.dart
//
// LEGACY — will be rewritten in Session 2 to use RC Package.
// Temporarily adapted to use Package from purchases_flutter.

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';

/// Displays a subscription plan (RC Package) for purchase.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.package,
    required this.onPurchase,
    this.isLoading = false,
    this.isCurrentPlan = false,
    this.isRecommended = false,
  });

  final Package package;
  final VoidCallback onPurchase;
  final bool isLoading;
  final bool isCurrentPlan;
  final bool isRecommended;

  StoreProduct get _product => package.storeProduct;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name
                Row(
                  children: [
                    Text(
                      _product.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCurrentPlan) ...[
                      const SizedBox(width: 8),
                      AppBadge(
                        label: 'Current',
                        variant: AppBadgeVariant.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  _product.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                const SizedBox(height: 16),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _product.priceString,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/${_periodLabel()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ),
                  ],
                ),

                // Trial badge
                if (_product.introductoryPrice != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppColors.accentDark
                                  : AppColors.accentLight)
                              .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Free trial available',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.accentDark
                            : AppColors.accentLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Purchase button
                SizedBox(
                  width: double.infinity,
                  child: isCurrentPlan
                      ? AppButton.outline(
                          label: 'Current Plan',
                          onPressed: null,
                        )
                      : AppButton.primary(
                          label: _product.introductoryPrice != null
                              ? 'Start Free Trial'
                              : 'Subscribe',
                          onPressed: isLoading ? null : onPurchase,
                          isLoading: isLoading,
                        ),
                ),
              ],
            ),
          ),
        ),

        // Recommended badge
        if (isRecommended)
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                'RECOMMENDED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _periodLabel() {
    final period = _product.subscriptionPeriod;
    if (period == null) return 'purchase';
    // RC period format: PnY, PnM, PnW, PnD
    if (period.contains('Y')) return 'year';
    if (period.contains('M')) return 'month';
    if (period.contains('W')) return 'week';
    if (period.contains('D')) return 'day';
    return 'month';
  }
}
