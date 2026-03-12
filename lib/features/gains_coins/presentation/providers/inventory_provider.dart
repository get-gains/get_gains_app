import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../data/cosmetics_repository.dart';
import '../../data/models/equipped_cosmetic_model.dart';
import '../../data/models/user_cosmetic_model.dart';
import 'coin_balance_provider.dart';

part 'inventory_provider.g.dart';

/// Inventory UI State
sealed class InventoryState {
  const InventoryState();
}

/// Initial state — not yet loaded
class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

/// Loading inventory data
class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

/// Inventory loaded
class InventoryLoaded extends InventoryState {
  const InventoryLoaded({
    required this.ownedItems,
    required this.equippedMap,
    this.filterCategory,
    this.isProcessing = false,
    this.actionError,
  });

  final List<UserCosmeticModel> ownedItems;

  /// Map of category → cosmeticId (null = empty slot)
  final Map<String, String?> equippedMap;

  final String? filterCategory;
  final bool isProcessing;
  final String? actionError;

  /// Items after applying category filter
  List<UserCosmeticModel> get filteredItems {
    if (filterCategory == null) return ownedItems;
    return ownedItems.where((i) => i.category == filterCategory).toList();
  }

  /// Items grouped by category
  Map<String, List<UserCosmeticModel>> get itemsByCategory {
    final map = <String, List<UserCosmeticModel>>{};
    for (final item in ownedItems) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  /// All categories present in the inventory
  List<String> get availableCategories {
    return ownedItems.map((i) => i.category).toSet().toList()..sort();
  }

  /// Check if a cosmetic is currently equipped
  bool isEquipped(String cosmeticId) {
    return equippedMap.values.contains(cosmeticId);
  }

  /// Get equipped cosmetic ID for a category slot
  String? equippedInSlot(String category) => equippedMap[category];

  /// Get equipped items as a list of EquippedCosmeticModel
  List<EquippedCosmeticModel> get equippedCosmetics {
    final items = <EquippedCosmeticModel>[];
    for (final entry in equippedMap.entries) {
      final cosmeticId = entry.value;
      if (cosmeticId == null) continue;
      final owned = ownedItems
          .where((i) => i.cosmeticId == cosmeticId)
          .firstOrNull;
      if (owned != null) {
        items.add(
          EquippedCosmeticModel(
            cosmeticId: cosmeticId,
            category: entry.key,
            unityAssetRef: owned.unityAssetRef,
            equippedAt: DateTime.now(),
          ),
        );
      }
    }
    return items;
  }

  /// Category display labels
  static String categoryLabel(String category) {
    return switch (category) {
      'HEADWEAR' => 'Headwear',
      'TOP' => 'Top',
      'BOTTOM' => 'Bottom',
      'ACCESSORY' => 'Accessory',
      _ => category,
    };
  }

  InventoryLoaded copyWith({
    List<UserCosmeticModel>? ownedItems,
    Map<String, String?>? equippedMap,
    String? Function()? filterCategory,
    bool? isProcessing,
    String? Function()? actionError,
  }) {
    return InventoryLoaded(
      ownedItems: ownedItems ?? this.ownedItems,
      equippedMap: equippedMap ?? this.equippedMap,
      filterCategory: filterCategory != null
          ? filterCategory()
          : this.filterCategory,
      isProcessing: isProcessing ?? this.isProcessing,
      actionError: actionError != null ? actionError() : this.actionError,
    );
  }
}

/// Error loading inventory
class InventoryError extends InventoryState {
  const InventoryError({required this.error});
  final AppError error;
}

/// Inventory State Notifier
///
/// Manages cosmetic inventory state. Loads from local cache first
/// for instant display, then syncs from server. Supports
/// equip/unequip actions and category filtering.
@Riverpod(keepAlive: true)
class InventoryNotifier extends _$InventoryNotifier {
  late CosmeticsRepository _repository;

  @override
  InventoryState build() {
    _repository = ref.watch(cosmeticsRepositoryProvider);
    Future.microtask(() => load());
    return const InventoryInitial();
  }

  /// Load inventory — first from cache, then sync from server
  Future<void> load() async {
    state = const InventoryLoading();

    // Try local cache first for instant display
    final cachedResult = await _repository.getCachedInventory();
    final cachedEquipped = await _repository.getCachedEquipped();

    cachedResult.when(
      success: (items) {
        if (items.isNotEmpty) {
          final equippedMap = _buildEquippedMap(cachedEquipped);
          state = InventoryLoaded(ownedItems: items, equippedMap: equippedMap);
        }
      },
      failure: (_) {
        // No cache — stay in loading
      },
    );

    // Then sync from server for authoritative data
    await refresh();
  }

  /// Refresh inventory from server
  Future<void> refresh() async {
    final result = await _repository.syncInventory();
    result.when(
      success: (inventory) {
        final currentState = state;
        state = InventoryLoaded(
          ownedItems: inventory.owned,
          equippedMap: inventory.equipped,
          filterCategory: currentState is InventoryLoaded
              ? currentState.filterCategory
              : null,
        );
        AppLogger.debug(
          'Inventory refreshed: ${inventory.owned.length} items',
          tag: 'InventoryProvider',
        );
      },
      failure: (error) {
        // If we already have cached data, keep showing it
        if (state is InventoryLoaded) {
          AppLogger.warning(
            'Failed to refresh inventory, keeping cached: ${error.message}',
            tag: 'InventoryProvider',
          );
          return;
        }
        state = InventoryError(error: error);
      },
    );
  }

  /// Equip a cosmetic
  Future<bool> equip(String cosmeticId) async {
    final currentState = state;
    if (currentState is! InventoryLoaded) return false;

    state = currentState.copyWith(isProcessing: true, actionError: () => null);

    final result = await _repository.equipCosmetic(cosmeticId);

    return result.when(
      success: (response) {
        // Update owned items' isEquipped flags
        final updatedOwned = currentState.ownedItems.map((item) {
          final isNowEquipped = response.equipped.values.contains(
            item.cosmeticId,
          );
          return UserCosmeticModel(
            id: item.id,
            cosmeticId: item.cosmeticId,
            name: item.name,
            description: item.description,
            tier: item.tier,
            category: item.category,
            previewImageUrl: item.previewImageUrl,
            unityAssetRef: item.unityAssetRef,
            purchasedAt: item.purchasedAt,
            isEquipped: isNowEquipped,
          );
        }).toList();

        state = currentState.copyWith(
          ownedItems: updatedOwned,
          equippedMap: response.equipped,
          isProcessing: false,
          actionError: () => null,
        );

        AppLogger.info(
          'Equipped cosmetic: $cosmeticId',
          tag: 'InventoryProvider',
        );
        return true;
      },
      failure: (error) {
        state = (state as InventoryLoaded).copyWith(
          isProcessing: false,
          actionError: () => error.message,
        );
        AppLogger.error(
          'Equip failed: ${error.message}',
          tag: 'InventoryProvider',
        );
        return false;
      },
    );
  }

  /// Unequip a cosmetic from a category slot
  Future<bool> unequip(String category) async {
    final currentState = state;
    if (currentState is! InventoryLoaded) return false;

    state = currentState.copyWith(isProcessing: true, actionError: () => null);

    final result = await _repository.unequipCosmetic(category);

    return result.when(
      success: (response) {
        // Update owned items' isEquipped flags
        final updatedOwned = currentState.ownedItems.map((item) {
          final isNowEquipped = response.equipped.values.contains(
            item.cosmeticId,
          );
          return UserCosmeticModel(
            id: item.id,
            cosmeticId: item.cosmeticId,
            name: item.name,
            description: item.description,
            tier: item.tier,
            category: item.category,
            previewImageUrl: item.previewImageUrl,
            unityAssetRef: item.unityAssetRef,
            purchasedAt: item.purchasedAt,
            isEquipped: isNowEquipped,
          );
        }).toList();

        state = currentState.copyWith(
          ownedItems: updatedOwned,
          equippedMap: response.equipped,
          isProcessing: false,
          actionError: () => null,
        );

        // Refresh coin balance in case it changed
        ref.read(coinBalanceProvider.notifier).refresh();

        AppLogger.info(
          'Unequipped category: $category',
          tag: 'InventoryProvider',
        );
        return true;
      },
      failure: (error) {
        state = (state as InventoryLoaded).copyWith(
          isProcessing: false,
          actionError: () => error.message,
        );
        AppLogger.error(
          'Unequip failed: ${error.message}',
          tag: 'InventoryProvider',
        );
        return false;
      },
    );
  }

  /// Set category filter (null to clear)
  void setCategoryFilter(String? category) {
    final currentState = state;
    if (currentState is! InventoryLoaded) return;
    state = currentState.copyWith(filterCategory: () => category);
  }

  /// Clear all filters
  void clearFilters() {
    final currentState = state;
    if (currentState is! InventoryLoaded) return;
    state = currentState.copyWith(filterCategory: () => null);
  }

  // ── Private Helpers ──

  Map<String, String?> _buildEquippedMap(
    Result<List<EquippedCosmeticModel>, AppError> cachedEquipped,
  ) {
    final map = <String, String?>{
      'HEADWEAR': null,
      'TOP': null,
      'BOTTOM': null,
      'ACCESSORY': null,
    };
    cachedEquipped.when(
      success: (items) {
        for (final ec in items) {
          map[ec.category] = ec.cosmeticId;
        }
      },
      failure: (_) {},
    );
    return map;
  }
}

// ── Convenience providers ──

/// Whether the inventory is currently loading
@riverpod
bool isInventoryLoading(Ref ref) {
  final state = ref.watch(inventoryProvider);
  return state is InventoryLoading || state is InventoryInitial;
}

/// Number of owned cosmetics
@riverpod
int ownedCosmeticCount(Ref ref) {
  final state = ref.watch(inventoryProvider);
  return switch (state) {
    InventoryLoaded(:final ownedItems) => ownedItems.length,
    _ => 0,
  };
}

/// Number of equipped cosmetics
@riverpod
int equippedCosmeticCount(Ref ref) {
  final state = ref.watch(inventoryProvider);
  return switch (state) {
    InventoryLoaded(:final equippedMap) =>
      equippedMap.values.where((v) => v != null).length,
    _ => 0,
  };
}

/// Whether a specific cosmetic is equipped
@riverpod
bool isCosmeticEquipped(Ref ref, String cosmeticId) {
  final state = ref.watch(inventoryProvider);
  return switch (state) {
    InventoryLoaded(:final equippedMap) => equippedMap.values.contains(
      cosmeticId,
    ),
    _ => false,
  };
}
