import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/api_error_codes.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/cosmetic_model.dart';
import '../../data/shop_repository.dart';
import 'coin_balance_provider.dart';

part 'shop_provider.g.dart';

/// Shop UI State
sealed class ShopState {
  const ShopState();
}

/// Initial state — not yet loaded
class ShopInitial extends ShopState {
  const ShopInitial();
}

/// Loading catalog data
class ShopLoading extends ShopState {
  const ShopLoading();
}

/// Catalog loaded
class ShopLoaded extends ShopState {
  const ShopLoaded({
    required this.items,
    required this.userBalance,
    required this.ownedCosmeticIds,
    this.filterTier,
    this.filterCategory,
    this.isPurchasing = false,
    this.purchaseError,
  });

  final List<CosmeticModel> items;
  final int userBalance;
  final List<String> ownedCosmeticIds;
  final int? filterTier;
  final String? filterCategory;
  final bool isPurchasing;
  final AppError? purchaseError;

  /// Items grouped by tier for tiered display
  Map<int, List<CosmeticModel>> get itemsByTier {
    final map = <int, List<CosmeticModel>>{};
    for (final item in filteredItems) {
      map.putIfAbsent(item.tier, () => []).add(item);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Items after applying active filters
  List<CosmeticModel> get filteredItems {
    var filtered = items;
    if (filterTier != null) {
      filtered = filtered.where((i) => i.tier == filterTier).toList();
    }
    if (filterCategory != null) {
      filtered = filtered.where((i) => i.category == filterCategory).toList();
    }
    return filtered;
  }

  /// Tier labels for display
  static String tierLabel(int tier) {
    return switch (tier) {
      1 => 'Bronze',
      2 => 'Silver',
      3 => 'Gold',
      _ => 'Tier $tier',
    };
  }

  /// Check if a cosmetic is owned
  bool isOwned(String cosmeticId) => ownedCosmeticIds.contains(cosmeticId);

  /// Check if user can afford a cosmetic
  bool canAfford(CosmeticModel cosmetic) => userBalance >= cosmetic.coinCost;

  /// How many more coins needed for a purchase (0 if affordable)
  int coinsNeeded(CosmeticModel cosmetic) {
    final deficit = cosmetic.coinCost - userBalance;
    return deficit > 0 ? deficit : 0;
  }

  ShopLoaded copyWith({
    List<CosmeticModel>? items,
    int? userBalance,
    List<String>? ownedCosmeticIds,
    int? Function()? filterTier,
    String? Function()? filterCategory,
    bool? isPurchasing,
    AppError? Function()? purchaseError,
  }) {
    return ShopLoaded(
      items: items ?? this.items,
      userBalance: userBalance ?? this.userBalance,
      ownedCosmeticIds: ownedCosmeticIds ?? this.ownedCosmeticIds,
      filterTier: filterTier != null ? filterTier() : this.filterTier,
      filterCategory: filterCategory != null
          ? filterCategory()
          : this.filterCategory,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchaseError: purchaseError != null
          ? purchaseError()
          : this.purchaseError,
    );
  }
}

/// Error loading catalog
class ShopError extends ShopState {
  const ShopError({required this.error});
  final AppError error;
}

/// Shop State Notifier
///
/// Manages shop catalog state. Loads from local cache first
/// for instant display, then syncs from server. Supports
/// tier/category filtering and purchase actions.
@Riverpod(keepAlive: true)
class ShopNotifier extends _$ShopNotifier {
  late ShopRepository _repository;

  @override
  ShopState build() {
    _repository = ref.watch(shopRepositoryProvider);
    Future.microtask(() => load());
    return const ShopInitial();
  }

  /// Load catalog — first from cache, then sync from server
  Future<void> load() async {
    state = const ShopLoading();

    // Try local cache first for instant display
    final cachedResult = await _repository.getCachedCatalog();
    final cachedOwnedResult = await _repository.getCachedOwnedIds();

    cachedResult.when(
      success: (items) {
        if (items.isNotEmpty) {
          final ownedIds = cachedOwnedResult.when(
            success: (ids) => ids,
            failure: (_) => <String>[],
          );
          state = ShopLoaded(
            items: items,
            userBalance: 0,
            ownedCosmeticIds: ownedIds,
          );
        }
      },
      failure: (_) {
        // No cache — stay in loading
      },
    );

    // Then sync from server for authoritative data
    await refresh();
  }

  /// Refresh catalog from server
  Future<void> refresh() async {
    final result = await _repository.syncCatalog();
    result.when(
      success: (catalog) {
        final currentState = state;
        state = ShopLoaded(
          items: catalog.items,
          userBalance: catalog.userBalance,
          ownedCosmeticIds: catalog.ownedCosmeticIds,
          filterTier: currentState is ShopLoaded
              ? currentState.filterTier
              : null,
          filterCategory: currentState is ShopLoaded
              ? currentState.filterCategory
              : null,
        );
        AppLogger.debug(
          'Shop catalog refreshed: ${catalog.items.length} items, balance: ${catalog.userBalance}',
          tag: 'ShopProvider',
        );
      },
      failure: (error) {
        // If we already have cached data, keep showing it
        if (state is ShopLoaded) {
          AppLogger.warning(
            'Failed to refresh catalog, keeping cached: ${error.message}',
            tag: 'ShopProvider',
          );
          return;
        }
        state = ShopError(error: error);
      },
    );
  }

  /// Set tier filter (null to clear)
  void setTierFilter(int? tier) {
    final currentState = state;
    if (currentState is! ShopLoaded) return;
    state = currentState.copyWith(filterTier: () => tier);
  }

  /// Set category filter (null to clear)
  void setCategoryFilter(String? category) {
    final currentState = state;
    if (currentState is! ShopLoaded) return;
    state = currentState.copyWith(filterCategory: () => category);
  }

  /// Clear all filters
  void clearFilters() {
    final currentState = state;
    if (currentState is! ShopLoaded) return;
    state = currentState.copyWith(
      filterTier: () => null,
      filterCategory: () => null,
    );
  }

  /// Purchase a cosmetic item
  Future<bool> purchase(String cosmeticId) async {
    final currentState = state;
    if (currentState is! ShopLoaded) return false;

    // Set purchasing state
    state = currentState.copyWith(
      isPurchasing: true,
      purchaseError: () => null,
    );

    final result = await _repository.purchaseCosmetic(cosmeticId);

    return result.when(
      success: (purchase) {
        // Update local state: add to owned, update balance
        final updatedOwned = [...currentState.ownedCosmeticIds, cosmeticId];
        state = currentState.copyWith(
          userBalance: purchase.newBalance,
          ownedCosmeticIds: updatedOwned,
          isPurchasing: false,
          purchaseError: () => null,
        );

        // Refresh coin balance provider for other screens
        ref.read(coinBalanceProvider.notifier).refresh();

        AppLogger.info(
          'Purchased ${purchase.cosmeticName} for ${purchase.coinCost}. New balance: ${purchase.newBalance}',
          tag: 'ShopProvider',
        );
        return true;
      },
      failure: (error) {
        // Item already owned — not really an error. Refresh inventory so
        // the UI reflects ownership, then show a soft info message.
        if (error.code == ApiErrorCode.shopItemAlreadyOwned) {
          final updatedOwned = [...currentState.ownedCosmeticIds, cosmeticId];
          state = currentState.copyWith(
            ownedCosmeticIds: updatedOwned,
            isPurchasing: false,
            purchaseError: () => null,
          );
          // Refresh from server to ensure consistency
          refresh();
          return true;
        }

        state = (state as ShopLoaded).copyWith(
          isPurchasing: false,
          purchaseError: () => error,
        );
        AppLogger.error(
          'Purchase failed: ${error.message}',
          tag: 'ShopProvider',
        );
        return false;
      },
    );
  }
}

// ── Convenience providers ──

/// Whether the shop is currently loading
@riverpod
bool isShopLoading(Ref ref) {
  final state = ref.watch(shopProvider);
  return state is ShopLoading || state is ShopInitial;
}

/// Current user balance from shop context
@riverpod
int shopUserBalance(Ref ref) {
  final state = ref.watch(shopProvider);
  return switch (state) {
    ShopLoaded(:final userBalance) => userBalance,
    _ => 0,
  };
}

/// Whether a specific cosmetic is owned
@riverpod
bool isCosmeticOwned(Ref ref, String cosmeticId) {
  final state = ref.watch(shopProvider);
  return switch (state) {
    ShopLoaded(:final ownedCosmeticIds) => ownedCosmeticIds.contains(
      cosmeticId,
    ),
    _ => false,
  };
}

/// Available tier values from the catalog
@riverpod
List<int> availableTiers(Ref ref) {
  final state = ref.watch(shopProvider);
  return switch (state) {
    ShopLoaded(:final items) =>
      (items.map((i) => i.tier).toSet().toList()..sort()),
    _ => [],
  };
}

/// Available categories from the catalog
@riverpod
List<String> availableCategories(Ref ref) {
  final state = ref.watch(shopProvider);
  return switch (state) {
    ShopLoaded(:final items) =>
      items.map((i) => i.category).toSet().toList()..sort(),
    _ => [],
  };
}
