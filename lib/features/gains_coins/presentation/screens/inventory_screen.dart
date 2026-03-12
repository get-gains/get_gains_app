import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/user_cosmetic_model.dart';
import '../providers/inventory_provider.dart';
import '../widgets/cosmetic_preview.dart';

/// Inventory Screen
///
/// Displays the user's owned cosmetics with equip/unequip functionality.
/// Features:
/// - Character preview via Unity widget with equipped cosmetics
/// - Category slot visualization (HEADWEAR, TOP, BOTTOM, ACCESSORY)
/// - Owned items grid with equip/unequip toggle
/// - Category filtering
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final GlobalKey<_CosmeticPreviewState> _previewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wardrobe',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(inventoryProvider.notifier).refresh();
          },
          child: switch (inventoryState) {
            InventoryInitial() || InventoryLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            InventoryLoaded() => _InventoryContent(
              state: inventoryState,
              isDark: isDark,
              previewKey: _previewKey,
            ),
            InventoryError(:final error) => Center(
              child: AppEmptyState.compact(
                icon: Icons.checkroom_outlined,
                title: 'Failed to Load Wardrobe',
                description: error.message,
              ),
            ),
          },
        ),
      ),
    );
  }
}

// ── Inventory Content ──

class _InventoryContent extends ConsumerWidget {
  const _InventoryContent({
    required this.state,
    required this.isDark,
    required this.previewKey,
  });

  final InventoryLoaded state;
  final bool isDark;
  final GlobalKey previewKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.ownedItems.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          AppEmptyState.compact(
            icon: Icons.checkroom_outlined,
            title: 'No Cosmetics Yet',
            description:
                'Visit the shop to purchase cosmetics for your character.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Character Preview with Unity widget
        CosmeticPreview(
          key: previewKey,
          equippedCosmetics: state.equippedCosmetics,
          height: 260,
        ),

        const SizedBox(height: 16),

        // Equipped Slots Visualization
        _EquippedSlotsBar(state: state, isDark: isDark),

        const SizedBox(height: 16),

        // Category Filter Chips
        _CategoryFilterChips(state: state, isDark: isDark),

        const SizedBox(height: 12),

        // Error banner
        if (state.actionError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.destructiveDark.withValues(alpha: 0.2)
                    : Colors.red.shade50,
                borderRadius: AppTheme.borderRadiusMd,
                border: Border.all(
                  color: isDark
                      ? AppColors.destructiveDark
                      : Colors.red.shade300,
                ),
              ),
              child: Text(
                state.actionError!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.destructiveForegroundDark
                      : Colors.red.shade700,
                ),
              ),
            ),
          ),

        // Inventory Grid
        _InventoryGrid(state: state, isDark: isDark),
      ],
    );
  }
}

// ── Equipped Slots Bar ──

class _EquippedSlotsBar extends StatelessWidget {
  const _EquippedSlotsBar({required this.state, required this.isDark});

  final InventoryLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const categories = ['HEADWEAR', 'TOP', 'BOTTOM', 'ACCESSORY'];
    const icons = {
      'HEADWEAR': Icons.face_retouching_natural,
      'TOP': Icons.dry_cleaning,
      'BOTTOM': Icons.hiking,
      'ACCESSORY': Icons.watch,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
        borderRadius: AppTheme.borderRadiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Equipped Slots',
            style: AppTextStyles.labelLarge.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: categories.map((category) {
              final equippedId = state.equippedInSlot(category);
              final isOccupied = equippedId != null;
              final equippedItem = isOccupied
                  ? state.ownedItems
                        .where((i) => i.cosmeticId == equippedId)
                        .firstOrNull
                  : null;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SlotTile(
                    category: category,
                    icon: icons[category] ?? Icons.help_outline,
                    equippedItem: equippedItem,
                    isDark: isDark,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.category,
    required this.icon,
    required this.equippedItem,
    required this.isDark,
  });

  final String category;
  final IconData icon;
  final UserCosmeticModel? equippedItem;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isOccupied = equippedItem != null;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final muted = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isOccupied
                ? primary.withValues(alpha: 0.15)
                : (isDark ? AppColors.surface2Dark : AppColors.surface1Light)
                      .withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isOccupied ? primary : muted.withValues(alpha: 0.3),
              width: isOccupied ? 2 : 1,
            ),
          ),
          child: equippedItem != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: equippedItem!.previewImageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Icon(icon, color: primary, size: 22),
                    errorWidget: (_, __, ___) =>
                        Icon(icon, color: primary, size: 22),
                  ),
                )
              : Icon(icon, color: muted, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          InventoryLoaded.categoryLabel(category),
          style: TextStyle(
            fontSize: 10,
            color: isOccupied ? primary : muted,
            fontWeight: isOccupied ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Category Filter Chips ──

class _CategoryFilterChips extends ConsumerWidget {
  const _CategoryFilterChips({required this.state, required this.isDark});

  final InventoryLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = state.availableCategories;
    if (categories.length <= 1) return const SizedBox.shrink();

    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: state.filterCategory == null,
            isDark: isDark,
            primary: primary,
            onTap: () =>
                ref.read(inventoryProvider.notifier).setCategoryFilter(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: InventoryLoaded.categoryLabel(category),
                isSelected: state.filterCategory == category,
                isDark: isDark,
                primary: primary,
                onTap: () => ref
                    .read(inventoryProvider.notifier)
                    .setCategoryFilter(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.15)
              : isDark
              ? AppColors.surface2Dark
              : AppColors.surface1Light,
          borderRadius: AppTheme.borderRadiusFull,
          border: Border.all(color: isSelected ? primary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? primary
                : isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
      ),
    );
  }
}

// ── Inventory Grid ──

class _InventoryGrid extends ConsumerWidget {
  const _InventoryGrid({required this.state, required this.isDark});

  final InventoryLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = state.filteredItems;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: Text(
            'No items in this category.',
            style: TextStyle(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _InventoryItemCard(
          item: item,
          isEquipped: state.isEquipped(item.cosmeticId),
          isProcessing: state.isProcessing,
          isDark: isDark,
        );
      },
    );
  }
}

// ── Inventory Item Card ──

class _InventoryItemCard extends ConsumerWidget {
  const _InventoryItemCard({
    required this.item,
    required this.isEquipped,
    required this.isProcessing,
    required this.isDark,
  });

  final UserCosmeticModel item;
  final bool isEquipped;
  final bool isProcessing;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final accent = isDark ? AppColors.accentDark : const Color(0xFF22C55E);

    return GestureDetector(
      onTap: isProcessing ? null : () => _toggleEquip(ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface1Dark : AppColors.cardLight,
          borderRadius: AppTheme.borderRadiusMd,
          border: Border.all(
            color: isEquipped
                ? accent
                : isDark
                ? AppColors.borderDark
                : AppColors.borderLight,
            width: isEquipped ? 2 : 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(7),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: item.previewImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? AppColors.surface2Dark
                            : AppColors.surface1Light,
                        child: Center(
                          child: Icon(
                            Icons.checkroom,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                            size: 32,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark
                            ? AppColors.surface2Dark
                            : AppColors.surface1Light,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Equipped badge
                  if (isEquipped)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: AppTheme.borderRadiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Equipped',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Category badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: AppTheme.borderRadiusFull,
                      ),
                      child: Text(
                        InventoryLoaded.categoryLabel(item.category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Item info + equip button
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    // Equip / Unequip button
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isEquipped
                              ? accent.withValues(alpha: 0.15)
                              : primary.withValues(alpha: 0.1),
                          borderRadius: AppTheme.borderRadiusSm,
                          border: Border.all(
                            color: isEquipped
                                ? accent.withValues(alpha: 0.3)
                                : primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: isProcessing
                            ? const Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Text(
                                isEquipped ? 'Unequip' : 'Equip',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isEquipped ? accent : primary,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleEquip(WidgetRef ref) async {
    if (isEquipped) {
      await ref.read(inventoryProvider.notifier).unequip(item.category);
    } else {
      await ref.read(inventoryProvider.notifier).equip(item.cosmeticId);
    }
  }
}

/// Private typedef for using the preview key with the right type
typedef _CosmeticPreviewState = State<CosmeticPreview>;
