import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cosmetic_model.dart';
import '../providers/shop_provider.dart';
import 'shop_item_card.dart';

/// Tier Section Widget
///
/// Displays a tier header and a grid of cosmetic items within that tier.
/// Used inside the ShopScreen to group items by tier visually.
class TierSection extends StatelessWidget {
  const TierSection({
    super.key,
    required this.tier,
    required this.items,
    required this.ownedCosmeticIds,
    required this.userBalance,
    required this.onItemTap,
  });

  final int tier;
  final List<CosmeticModel> items;
  final List<String> ownedCosmeticIds;
  final int userBalance;
  final void Function(CosmeticModel cosmetic) onItemTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (tierColor, tierLabel, tierIcon) = switch (tier) {
      1 => (const Color(0xFFCD7F32), 'Bronze', Icons.shield_outlined),
      2 => (const Color(0xFFC0C0C0), 'Silver', Icons.shield_rounded),
      3 => (const Color(0xFFFFD700), 'Gold', Icons.auto_awesome_rounded),
      _ => (Colors.grey, 'Tier $tier', Icons.category_outlined),
    };

    final tierRange = switch (tier) {
      1 => '80–130 coins',
      2 => '200–300 coins',
      3 => '450–650 coins',
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tier Header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.15),
                  borderRadius: AppTheme.borderRadiusSm,
                ),
                child: Icon(tierIcon, color: tierColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ShopLoaded.tierLabel(tier)} Tier',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight,
                      ),
                    ),
                    if (tierRange.isNotEmpty)
                      Text(
                        tierRange,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Item count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.12),
                  borderRadius: AppTheme.borderRadiusFull,
                ),
                child: Text(
                  '${items.length}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: tierColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Item Grid ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isOwned = ownedCosmeticIds.contains(item.id);
              final canAfford = userBalance >= item.coinCost;

              final status = isOwned
                  ? ShopItemStatus.owned
                  : canAfford
                  ? ShopItemStatus.affordable
                  : ShopItemStatus.locked;

              final deficit = item.coinCost - userBalance;

              return ShopItemCard(
                cosmetic: item,
                status: status,
                coinsNeeded: deficit > 0 ? deficit : 0,
                onTap: () => onItemTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
