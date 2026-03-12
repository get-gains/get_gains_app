import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../providers/coin_balance_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/tier_section.dart';

/// Shop Screen
///
/// Displays the cosmetic shop with:
/// - Current balance header
/// - Filter by tier/category chips
/// - Tiered layout of cosmetic items
/// - Purchase confirmation dialog
/// - "Need X more coins" indicator for locked items
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shopState = ref.watch(shopProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cosmetic Shop',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Balance in app bar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AppBarBalance(isDark: isDark),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(coinBalanceProvider);
            await ref.read(shopProvider.notifier).refresh();
          },
          child: switch (shopState) {
            ShopInitial() ||
            ShopLoading() => const Center(child: CircularProgressIndicator()),
            ShopLoaded() => _ShopContent(state: shopState, isDark: isDark),
            ShopError(:final error) => Center(
              child: AppEmptyState.compact(
                icon: Icons.storefront_outlined,
                title: 'Failed to Load Shop',
                description: error.message,
              ),
            ),
          },
        ),
      ),
    );
  }
}

// ── App Bar Balance ──

class _AppBarBalance extends ConsumerWidget {
  const _AppBarBalance({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shopProvider);
    final balance = switch (shopState) {
      ShopLoaded(:final userBalance) => userBalance,
      _ => ref.watch(currentCoinBalanceProvider),
    };

    final coinColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: coinColor.withValues(alpha: 0.1),
        borderRadius: AppTheme.borderRadiusFull,
        border: Border.all(color: coinColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, color: coinColor, size: 18),
          const SizedBox(width: 4),
          Text(
            _formatNumber(balance),
            style: AppTextStyles.numericBody.copyWith(
              color: coinColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shop Content ──

class _ShopContent extends ConsumerWidget {
  const _ShopContent({required this.state, required this.isDark});

  final ShopLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsByTier = state.itemsByTier;

    if (state.filteredItems.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _FilterBar(state: state, isDark: isDark),
            ),
          ),
          SliverFillRemaining(
            child: AppEmptyState.compact(
              icon: Icons.shopping_bag_outlined,
              title: 'No Items Found',
              description: 'Try adjusting your filters.',
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        // ── Filter chips ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _FilterBar(state: state, isDark: isDark),
          ),
        ),

        // ── Purchase error banner ──
        if (state.purchaseError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.error : AppColors.destructiveLight)
                      .withValues(alpha: 0.1),
                  borderRadius: AppTheme.borderRadiusMd,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: isDark
                          ? AppColors.error
                          : AppColors.destructiveLight,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.purchaseError!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.error
                              : AppColors.destructiveLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Purchasing overlay indicator ──
        if (state.isPurchasing)
          const SliverToBoxAdapter(child: LinearProgressIndicator()),

        // ── Tier sections ──
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final entry = itemsByTier.entries.elementAt(index);
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 8 : 24,
                bottom: index == itemsByTier.length - 1 ? 32 : 0,
              ),
              child: TierSection(
                tier: entry.key,
                items: entry.value,
                ownedCosmeticIds: state.ownedCosmeticIds,
                userBalance: state.userBalance,
                onItemTap: (cosmetic) {
                  context.push(AppRoutes.cosmeticDetail, extra: cosmetic);
                },
              ),
            );
          }, childCount: itemsByTier.length),
        ),
      ],
    );
  }
}

// ── Filter Bar ──

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.state, required this.isDark});

  final ShopLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(availableTiersProvider);
    final categories = ref.watch(availableCategoriesProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" chip
          _Chip(
            label: 'All',
            selected: state.filterTier == null && state.filterCategory == null,
            isDark: isDark,
            onTap: () => ref.read(shopProvider.notifier).clearFilters(),
          ),
          const SizedBox(width: 8),
          // Tier chips
          for (final tier in tiers) ...[
            _Chip(
              label: ShopLoaded.tierLabel(tier),
              selected: state.filterTier == tier,
              isDark: isDark,
              onTap: () => ref
                  .read(shopProvider.notifier)
                  .setTierFilter(state.filterTier == tier ? null : tier),
            ),
            const SizedBox(width: 8),
          ],
          // Divider
          if (categories.isNotEmpty) ...[
            Container(
              width: 1,
              height: 24,
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.1,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Category chips
          for (final cat in categories) ...[
            _Chip(
              label: _categoryLabel(cat),
              selected: state.filterCategory == cat,
              isDark: isDark,
              onTap: () => ref
                  .read(shopProvider.notifier)
                  .setCategoryFilter(state.filterCategory == cat ? null : cat),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'HEADWEAR' => 'Headwear',
      'TOP' => 'Top',
      'BOTTOM' => 'Bottom',
      'ACCESSORY' => 'Accessory',
      _ => category,
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.15)
              : (isDark ? AppColors.surface1Dark : AppColors.surface1Light),
          borderRadius: AppTheme.borderRadiusSm,
          border: Border.all(
            color: selected
                ? primaryColor
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: selected
                ? primaryColor
                : isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──

String _formatNumber(int value) {
  if (value < 1000) return value.toString();
  final str = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
  }
  return buffer.toString();
}
