import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/cosmetic_model.dart';
import '../providers/coin_balance_provider.dart';
import '../providers/shop_provider.dart';

/// Cosmetic Detail Screen
///
/// Displays detailed information about a cosmetic item:
/// - Large pannable/zoomable preview image
/// - Item name, description, tier, category
/// - Buy / Owned button
/// - "Need X more coins" indicator when insufficient balance
class CosmeticDetailScreen extends ConsumerStatefulWidget {
  const CosmeticDetailScreen({super.key, required this.cosmetic});

  final CosmeticModel cosmetic;

  @override
  ConsumerState<CosmeticDetailScreen> createState() =>
      _CosmeticDetailScreenState();
}

class _CosmeticDetailScreenState extends ConsumerState<CosmeticDetailScreen> {
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coinColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final cosmetic = widget.cosmetic;

    // Watch shop state for ownership / balance
    final shopState = ref.watch(shopProvider);
    final isOwned = switch (shopState) {
      ShopLoaded(:final ownedCosmeticIds) => ownedCosmeticIds.contains(
        cosmetic.id,
      ),
      _ => false,
    };
    final userBalance = switch (shopState) {
      ShopLoaded(:final userBalance) => userBalance,
      _ => ref.watch(currentCoinBalanceProvider),
    };
    final canAfford = userBalance >= cosmetic.coinCost;
    final coinsNeeded = cosmetic.coinCost - userBalance;

    final (tierColor, tierLabel) = switch (cosmetic.tier) {
      1 => (const Color(0xFFCD7F32), 'Bronze'),
      2 => (const Color(0xFFC0C0C0), 'Silver'),
      3 => (const Color(0xFFFFD700), 'Gold'),
      _ => (Colors.grey, 'Tier ${cosmetic.tier}'),
    };

    final categoryLabel = switch (cosmetic.category) {
      'HEADWEAR' => 'Headwear',
      'TOP' => 'Top',
      'BOTTOM' => 'Bottom',
      'ACCESSORY' => 'Accessory',
      _ => cosmetic.category,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          cosmetic.name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Preview Image (pannable / zoomable) ──
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: AppTheme.borderRadiusLg,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.03,
                      ),
                      borderRadius: AppTheme.borderRadiusLg,
                    ),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: CachedNetworkImage(
                        imageUrl: cosmetic.previewImageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_rounded,
                                size: 64,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Preview unavailable',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.mutedForegroundLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Details Section ──
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Badges row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cosmetic.name,
                              style: AppTextStyles.headlineMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.foregroundDark
                                    : AppColors.foregroundLight,
                              ),
                            ),
                          ),
                          // Tier badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.15),
                              borderRadius: AppTheme.borderRadiusSm,
                              border: Border.all(
                                color: tierColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              tierLabel,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: tierColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Category & slot info
                      Row(
                        children: [
                          Icon(
                            _categoryIcon(cosmetic.category),
                            size: 16,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$categoryLabel Slot',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                        ],
                      ),

                      // Description
                      if (cosmetic.description != null &&
                          cosmetic.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          cosmetic.description!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Price row
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            color: coinColor,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${cosmetic.coinCost}',
                            style: AppTextStyles.numericDisplaySmall.copyWith(
                              color: coinColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'coins',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                        ],
                      ),

                      // "Need X more coins" indicator
                      if (!isOwned && !canAfford && coinsNeeded > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: AppTheme.borderRadiusSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.warning,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'You need $coinsNeeded more coins',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── Action Button ──
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(
                          context,
                          isDark: isDark,
                          isOwned: isOwned,
                          canAfford: canAfford,
                          coinColor: coinColor,
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required bool isDark,
    required bool isOwned,
    required bool canAfford,
    required Color coinColor,
  }) {
    if (isOwned) {
      return AppButton.secondary(
        label: 'Owned',
        icon: Icons.check_circle_rounded,
        onPressed: null,
        isFullWidth: true,
      );
    }

    if (!canAfford) {
      return AppButton.secondary(
        label: 'Insufficient Coins',
        icon: Icons.lock_rounded,
        onPressed: null,
        isFullWidth: true,
      );
    }

    return AppButton.primary(
      label: _isPurchasing
          ? 'Purchasing...'
          : 'Buy for ${widget.cosmetic.coinCost} coins',
      icon: Icons.shopping_cart_rounded,
      onPressed: _isPurchasing ? null : () => _confirmPurchase(context),
      isFullWidth: true,
    );
  }

  Future<void> _confirmPurchase(BuildContext context) async {
    final cosmetic = widget.cosmetic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLg),
        title: Text(
          'Confirm Purchase',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: AppTheme.borderRadiusMd,
              child: CachedNetworkImage(
                imageUrl: cosmetic.previewImageUrl,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.checkroom_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              cosmetic.name,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${cosmetic.coinCost} coins',
                  style: AppTextStyles.numericBody.copyWith(
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Buy'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPurchasing = true);

    final success = await ref.read(shopProvider.notifier).purchase(cosmetic.id);

    if (!mounted) return;

    setState(() => _isPurchasing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased ${cosmetic.name}!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMd),
        ),
      );
    }
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'HEADWEAR' => Icons.face_rounded,
      'TOP' => Icons.checkroom_rounded,
      'BOTTOM' => Icons.airline_seat_legroom_normal_rounded,
      'ACCESSORY' => Icons.watch_rounded,
      _ => Icons.category_rounded,
    };
  }
}
