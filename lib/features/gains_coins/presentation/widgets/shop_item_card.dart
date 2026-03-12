import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cosmetic_model.dart';

/// Item status for display styling
enum ShopItemStatus {
  /// User can afford and doesn't own
  affordable,

  /// User cannot afford
  locked,

  /// User already owns this item
  owned,
}

/// Shop Item Card
///
/// Displays a single cosmetic in the shop catalog grid:
/// - Preview image
/// - Name
/// - Cost with coin icon
/// - Tier badge
/// - State-dependent styling (affordable / locked / owned)
class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    super.key,
    required this.cosmetic,
    required this.status,
    this.coinsNeeded = 0,
    this.onTap,
  });

  final CosmeticModel cosmetic;
  final ShopItemStatus status;
  final int coinsNeeded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coinColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: AppTheme.borderRadiusLg,
          border: Border.all(
            color: _borderColor(isDark),
            width: status == ShopItemStatus.owned ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Preview Image ──
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLg),
                    ),
                    child: SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: cosmetic.previewImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.05),
                          child: const Center(
                            child: Icon(
                              Icons.checkroom_rounded,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.05),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Locked overlay
                  if (status == ShopItemStatus.locked)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusLg),
                      ),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                color: Colors.white70,
                                size: 24,
                              ),
                              if (coinsNeeded > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Need $coinsNeeded more',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Tier badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _TierBadge(tier: cosmetic.tier, isDark: isDark),
                  ),

                  // Owned badge
                  if (status == ShopItemStatus.owned)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.9),
                          borderRadius: AppTheme.borderRadiusSm,
                        ),
                        child: Text(
                          'Owned',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info Section ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cosmetic.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        color: status == ShopItemStatus.owned
                            ? (isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight)
                            : coinColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status == ShopItemStatus.owned
                            ? 'Owned'
                            : '${cosmetic.coinCost}',
                        style: AppTextStyles.numericBody.copyWith(
                          color: status == ShopItemStatus.owned
                              ? (isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight)
                              : status == ShopItemStatus.locked
                              ? (isDark
                                    ? AppColors.error
                                    : AppColors.destructiveLight)
                              : coinColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _borderColor(bool isDark) {
    return switch (status) {
      ShopItemStatus.owned => AppColors.success.withValues(alpha: 0.5),
      ShopItemStatus.affordable =>
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
      ShopItemStatus.locked =>
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
    };
  }
}

/// Tier badge shown on the card
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier, required this.isDark});

  final int tier;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (tier) {
      1 => (const Color(0xFFCD7F32), 'Bronze'),
      2 => (const Color(0xFFC0C0C0), 'Silver'),
      3 => (const Color(0xFFFFD700), 'Gold'),
      _ => (Colors.grey, 'T$tier'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: AppTheme.borderRadiusSm,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: tier == 2 ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
