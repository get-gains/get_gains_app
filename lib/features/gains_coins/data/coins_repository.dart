import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/database/app_database.dart';
import 'models/coin_balance_model.dart';
import 'models/coin_transaction_model.dart';

part 'coins_repository.g.dart';

/// Coins Repository
///
/// Handles coin balance and transaction history data operations.
/// Implements offline-first patterns:
/// - Local database (Drift) for offline balance/history cache
/// - API client for server sync
class CoinsRepository {
  CoinsRepository({required AppDatabase database, required ApiClient apiClient})
    : _db = database,
      _apiClient = apiClient;

  final AppDatabase _db;
  final ApiClient _apiClient;

  // ============== Balance Operations ==============

  /// Get coin balance from local cache
  Future<Result<CoinBalanceModel, AppError>> getCachedBalance() async {
    try {
      AppLogger.debug('Fetching coin balance from local DB', tag: 'CoinsRepo');
      final rows = await _db.select(_db.coinBalances).get();

      if (rows.isEmpty) {
        return const Success(
          CoinBalanceModel(
            currentBalance: 0,
            lifetimeEarned: 0,
            lifetimeSpent: 0,
          ),
        );
      }

      final row = rows.first;
      return Success(
        CoinBalanceModel(
          currentBalance: row.currentBalance,
          lifetimeEarned: row.lifetimeEarned,
          lifetimeSpent: row.lifetimeSpent,
          updatedAt: row.updatedAt,
        ),
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch cached balance',
        tag: 'CoinsRepo',
        error: e,
      );
      return Failure(
        DatabaseError(message: 'Failed to load cached balance: $e'),
      );
    }
  }

  /// Fetch coin balance from server and update local cache
  Future<Result<CoinBalanceModel, AppError>> syncBalance() async {
    AppLogger.debug('Syncing coin balance from server', tag: 'CoinsRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.coinBalance,
    );

    return result.when(
      success: (data) async {
        try {
          final balance = CoinBalanceModel(
            currentBalance: data['currentBalance'] as int? ?? 0,
            lifetimeEarned: data['lifetimeEarned'] as int? ?? 0,
            lifetimeSpent: data['lifetimeSpent'] as int? ?? 0,
            updatedAt: data['updatedAt'] != null
                ? DateTime.parse(data['updatedAt'] as String)
                : null,
          );

          // Upsert to local cache
          await _db
              .into(_db.coinBalances)
              .insertOnConflictUpdate(
                CoinBalancesCompanion.insert(
                  id: 'current_user_balance',
                  currentBalance: Value(balance.currentBalance),
                  lifetimeEarned: Value(balance.lifetimeEarned),
                  lifetimeSpent: Value(balance.lifetimeSpent),
                  updatedAt: balance.updatedAt ?? DateTime.now(),
                  isSynced: const Value(true),
                ),
              );

          AppLogger.info(
            'Synced coin balance: ${balance.currentBalance}',
            tag: 'CoinsRepo',
          );
          return Success(balance);
        } catch (e) {
          AppLogger.error(
            'Failed to parse/cache balance',
            tag: 'CoinsRepo',
            error: e,
          );
          return Failure(DatabaseError(message: 'Failed to parse balance: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  // ============== Transaction History Operations ==============

  /// Get coin transaction history from local cache
  Future<Result<List<CoinTransactionModel>, AppError>>
  getCachedHistory() async {
    try {
      AppLogger.debug('Fetching coin history from local DB', tag: 'CoinsRepo');
      final rows = await (_db.select(
        _db.coinTransactions,
      )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

      final transactions = rows
          .map(
            (row) => CoinTransactionModel(
              id: row.id,
              type: row.type,
              amount: row.amount,
              balanceAfter: row.balanceAfter,
              setCoins: row.setCoins,
              accuracyMultiplier: row.accuracyMultiplier,
              completionBonus: row.completionBonus,
              durationBonus: row.durationBonus,
              streakBonus: row.streakBonus,
              streakValue: row.streakValue,
              setsCompleted: row.setsCompleted,
              avgAccuracy: row.avgAccuracy,
              sessionDurationMin: row.sessionDurationMin,
              workoutSessionId: row.workoutSessionId,
              userCosmeticId: row.cosmeticId,
              createdAt: row.createdAt,
            ),
          )
          .toList();

      return Success(transactions);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch cached history',
        tag: 'CoinsRepo',
        error: e,
      );
      return Failure(
        DatabaseError(message: 'Failed to load cached history: $e'),
      );
    }
  }

  /// Fetch coin transaction history from server with pagination and cache
  Future<
    Result<
      ({List<CoinTransactionModel> transactions, int total, int totalPages}),
      AppError
    >
  >
  syncHistory({int page = 1, int limit = 20, String? type}) async {
    AppLogger.debug(
      'Syncing coin history from server (page: $page)',
      tag: 'CoinsRepo',
    );

    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null) queryParams['type'] = type;

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.coinHistory,
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) async {
        try {
          final transactionsList = (data['transactions'] as List)
              .map(
                (t) => CoinTransactionModel.fromJson(t as Map<String, dynamic>),
              )
              .toList();

          final pagination = data['pagination'] as Map<String, dynamic>;
          final total = pagination['total'] as int? ?? 0;
          final totalPages = pagination['totalPages'] as int? ?? 1;

          // Cache transactions to local DB
          for (final txn in transactionsList) {
            await _db
                .into(_db.coinTransactions)
                .insertOnConflictUpdate(
                  CoinTransactionsCompanion.insert(
                    id: txn.id,
                    remoteId: Value(txn.id),
                    type: txn.type,
                    amount: txn.amount,
                    balanceAfter: txn.balanceAfter,
                    setCoins: Value(txn.setCoins),
                    accuracyMultiplier: Value(txn.accuracyMultiplier),
                    completionBonus: Value(txn.completionBonus),
                    durationBonus: Value(txn.durationBonus),
                    streakBonus: Value(txn.streakBonus),
                    streakValue: Value(txn.streakValue),
                    setsCompleted: Value(txn.setsCompleted),
                    avgAccuracy: Value(txn.avgAccuracy),
                    sessionDurationMin: Value(txn.sessionDurationMin),
                    workoutSessionId: Value(txn.workoutSessionId),
                    cosmeticId: Value(txn.userCosmeticId),
                    createdAt: txn.createdAt,
                    isSynced: const Value(true),
                  ),
                );
          }

          AppLogger.info(
            'Synced ${transactionsList.length} transactions (page $page/$totalPages)',
            tag: 'CoinsRepo',
          );
          return Success((
            transactions: transactionsList,
            total: total,
            totalPages: totalPages,
          ));
        } catch (e) {
          AppLogger.error(
            'Failed to parse/cache history',
            tag: 'CoinsRepo',
            error: e,
          );
          return Failure(DatabaseError(message: 'Failed to parse history: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }
}

/// Provider for CoinsRepository
@Riverpod(keepAlive: true)
CoinsRepository coinsRepository(Ref ref) {
  return CoinsRepository(
    database: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
  );
}
