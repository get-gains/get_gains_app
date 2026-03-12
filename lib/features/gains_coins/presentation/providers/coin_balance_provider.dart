import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coins_repository.dart';
import '../../data/models/coin_balance_model.dart';

part 'coin_balance_provider.g.dart';

/// Coin Balance UI State
sealed class CoinBalanceState {
  const CoinBalanceState();
}

/// Initial state - not yet loaded
class CoinBalanceInitial extends CoinBalanceState {
  const CoinBalanceInitial();
}

/// Loading balance data
class CoinBalanceLoading extends CoinBalanceState {
  const CoinBalanceLoading();
}

/// Balance data loaded
class CoinBalanceLoaded extends CoinBalanceState {
  const CoinBalanceLoaded({required this.balance});

  final CoinBalanceModel balance;

  CoinBalanceLoaded copyWith({CoinBalanceModel? balance}) {
    return CoinBalanceLoaded(balance: balance ?? this.balance);
  }
}

/// Error loading balance
class CoinBalanceError extends CoinBalanceState {
  const CoinBalanceError({required this.error});
  final AppError error;
}

/// Coin Balance State Notifier
///
/// Manages the user's coin balance state. Loads from local cache first
/// for instant display, then syncs from server for authoritative value.
@Riverpod(keepAlive: true)
class CoinBalanceNotifier extends _$CoinBalanceNotifier {
  late CoinsRepository _repository;

  @override
  CoinBalanceState build() {
    _repository = ref.watch(coinsRepositoryProvider);
    Future.microtask(() => load());
    return const CoinBalanceInitial();
  }

  /// Load balance — first from cache, then sync from server
  Future<void> load() async {
    state = const CoinBalanceLoading();

    // Try local cache first for instant display
    final cachedResult = await _repository.getCachedBalance();
    cachedResult.when(
      success: (balance) {
        state = CoinBalanceLoaded(balance: balance);
      },
      failure: (_) {
        // No cache — stay in loading
      },
    );

    // Then sync from server for authoritative value
    await refresh();
  }

  /// Refresh balance from server
  Future<void> refresh() async {
    final result = await _repository.syncBalance();
    result.when(
      success: (balance) {
        state = CoinBalanceLoaded(balance: balance);
        AppLogger.debug(
          'Coin balance refreshed: ${balance.currentBalance}',
          tag: 'CoinBalanceProvider',
        );
      },
      failure: (error) {
        // If we already have cached data, keep showing it
        if (state is CoinBalanceLoaded) {
          AppLogger.warning(
            'Failed to refresh balance, keeping cached: ${error.message}',
            tag: 'CoinBalanceProvider',
          );
          return;
        }
        state = CoinBalanceError(error: error);
      },
    );
  }

  /// Update balance optimistically (e.g., after a local coin award)
  void updateBalance(CoinBalanceModel balance) {
    state = CoinBalanceLoaded(balance: balance);
  }
}

// ── Convenience providers ──

/// Current balance amount (0 if not loaded)
@riverpod
int currentCoinBalance(Ref ref) {
  final state = ref.watch(coinBalanceProvider);
  return switch (state) {
    CoinBalanceLoaded(:final balance) => balance.currentBalance,
    _ => 0,
  };
}

/// Whether the balance is currently loading
@riverpod
bool isCoinBalanceLoading(Ref ref) {
  final state = ref.watch(coinBalanceProvider);
  return state is CoinBalanceLoading || state is CoinBalanceInitial;
}
