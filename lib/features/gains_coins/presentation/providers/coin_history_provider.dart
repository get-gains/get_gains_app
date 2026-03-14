import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coins_repository.dart';
import '../../data/models/coin_transaction_model.dart';

part 'coin_history_provider.g.dart';

/// Coin History UI State
sealed class CoinHistoryState {
  const CoinHistoryState();
}

/// Initial state - not yet loaded
class CoinHistoryInitial extends CoinHistoryState {
  const CoinHistoryInitial();
}

/// Loading history data
class CoinHistoryLoading extends CoinHistoryState {
  const CoinHistoryLoading();
}

/// History data loaded
class CoinHistoryLoaded extends CoinHistoryState {
  const CoinHistoryLoaded({
    required this.transactions,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    this.isLoadingMore = false,
    this.filterType,
  });

  final List<CoinTransactionModel> transactions;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool isLoadingMore;
  final String? filterType;

  bool get hasMore => currentPage < totalPages;

  CoinHistoryLoaded copyWith({
    List<CoinTransactionModel>? transactions,
    int? currentPage,
    int? totalPages,
    int? total,
    bool? isLoadingMore,
    String? filterType,
  }) {
    return CoinHistoryLoaded(
      transactions: transactions ?? this.transactions,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filterType: filterType ?? this.filterType,
    );
  }
}

/// Error loading history
class CoinHistoryError extends CoinHistoryState {
  const CoinHistoryError({required this.error});
  final AppError error;
}

/// Coin History State Notifier with Pagination
///
/// Manages paginated coin transaction history. Loads from local cache
/// first, then syncs from server. Supports infinite scroll pagination
/// and type filtering (SESSION_REWARD / SHOP_PURCHASE).
@Riverpod(keepAlive: true)
class CoinHistoryNotifier extends _$CoinHistoryNotifier {
  late CoinsRepository _repository;

  static const int _pageSize = 20;

  @override
  CoinHistoryState build() {
    _repository = ref.watch(coinsRepositoryProvider);
    Future.microtask(() => load());
    return const CoinHistoryInitial();
  }

  /// Load history — first from cache, then sync first page from server
  Future<void> load({String? filterType}) async {
    state = const CoinHistoryLoading();

    // Try local cache first for instant display
    final cachedResult = await _repository.getCachedHistory();
    cachedResult.when(
      success: (transactions) {
        if (transactions.isNotEmpty) {
          final filtered = filterType != null
              ? transactions.where((t) => t.type == filterType).toList()
              : transactions;
          state = CoinHistoryLoaded(
            transactions: filtered,
            currentPage: 1,
            totalPages: 1,
            total: filtered.length,
            filterType: filterType,
          );
        }
      },
      failure: (_) {
        // No cache — stay in loading
      },
    );

    // Then sync from server
    await _syncPage(1, filterType: filterType, replace: true);
  }

  /// Refresh history (reload first page from server)
  Future<void> refresh() async {
    final currentFilter = state is CoinHistoryLoaded
        ? (state as CoinHistoryLoaded).filterType
        : null;
    await _syncPage(1, filterType: currentFilter, replace: true);
  }

  /// Load next page (infinite scroll)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! CoinHistoryLoaded) return;
    if (!currentState.hasMore) return;
    if (currentState.isLoadingMore) return;

    state = currentState.copyWith(isLoadingMore: true);

    await _syncPage(
      currentState.currentPage + 1,
      filterType: currentState.filterType,
      replace: false,
    );
  }

  /// Apply a type filter and reload
  Future<void> setFilter(String? filterType) async {
    await load(filterType: filterType);
  }

  /// Internal: sync a specific page from the server
  Future<void> _syncPage(
    int page, {
    String? filterType,
    required bool replace,
  }) async {
    final result = await _repository.syncHistory(
      page: page,
      limit: _pageSize,
      type: filterType,
    );

    result.when(
      success: (data) {
        final currentState = state;
        List<CoinTransactionModel> allTransactions;

        if (replace || currentState is! CoinHistoryLoaded) {
          allTransactions = data.transactions;
        } else {
          // Append for pagination, dedup by ID
          final existingIds = currentState.transactions
              .map((t) => t.id)
              .toSet();
          final newTransactions = data.transactions
              .where((t) => !existingIds.contains(t.id))
              .toList();
          allTransactions = [...currentState.transactions, ...newTransactions];
        }

        state = CoinHistoryLoaded(
          transactions: allTransactions,
          currentPage: page,
          totalPages: data.totalPages,
          total: data.total,
          filterType: filterType,
        );

        AppLogger.debug(
          'Coin history loaded: ${allTransactions.length}/${data.total} (page $page/${data.totalPages})',
          tag: 'CoinHistoryProvider',
        );
      },
      failure: (error) {
        // If we already have data, keep it and log the error
        if (state is CoinHistoryLoaded) {
          state = (state as CoinHistoryLoaded).copyWith(isLoadingMore: false);
          AppLogger.warning(
            'Failed to sync history page $page, keeping cached: ${error.message}',
            tag: 'CoinHistoryProvider',
          );
          return;
        }
        state = CoinHistoryError(error: error);
      },
    );
  }
}

// ── Convenience providers ──

/// Total transaction count
@riverpod
int coinTransactionCount(Ref ref) {
  final state = ref.watch(coinHistoryProvider);
  return switch (state) {
    CoinHistoryLoaded(:final total) => total,
    _ => 0,
  };
}

/// Whether more pages are available for loading
@riverpod
bool hasMoreCoinHistory(Ref ref) {
  final state = ref.watch(coinHistoryProvider);
  return switch (state) {
    CoinHistoryLoaded(:final hasMore) => hasMore,
    _ => false,
  };
}
