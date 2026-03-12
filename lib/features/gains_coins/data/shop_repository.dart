import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/database/app_database.dart';
import 'models/cosmetic_model.dart';

part 'shop_repository.g.dart';

/// Shop catalog response containing items, user balance, and owned IDs.
class ShopCatalogResponse {
  ShopCatalogResponse({
    required this.items,
    required this.userBalance,
    required this.ownedCosmeticIds,
  });

  final List<CosmeticModel> items;
  final int userBalance;
  final List<String> ownedCosmeticIds;
}

/// Purchase response from the server.
class PurchaseResponse {
  PurchaseResponse({
    required this.cosmeticId,
    required this.cosmeticName,
    required this.coinCost,
    required this.newBalance,
    required this.purchasedAt,
  });

  final String cosmeticId;
  final String cosmeticName;
  final int coinCost;
  final int newBalance;
  final DateTime purchasedAt;
}

/// Shop Repository
///
/// Handles cosmetic shop data operations.
/// Implements offline-first patterns:
/// - Local database (Drift) for offline catalog cache
/// - API client for server catalog fetch and purchase
class ShopRepository {
  ShopRepository({required AppDatabase database, required ApiClient apiClient})
    : _db = database,
      _apiClient = apiClient;

  final AppDatabase _db;
  final ApiClient _apiClient;

  // ============== Catalog Operations ==============

  /// Get cosmetic catalog from local cache
  Future<Result<List<CosmeticModel>, AppError>> getCachedCatalog() async {
    try {
      AppLogger.debug('Fetching shop catalog from local DB', tag: 'ShopRepo');
      final rows =
          await (_db.select(_db.cosmeticsTable)
                ..where((t) => t.status.equals('ACTIVE'))
                ..orderBy([
                  (t) => OrderingTerm.asc(t.tier),
                  (t) => OrderingTerm.asc(t.sortOrder),
                  (t) => OrderingTerm.asc(t.name),
                ]))
              .get();

      final items = rows
          .map(
            (row) => CosmeticModel(
              id: row.id,
              name: row.name,
              description: row.description,
              tier: row.tier,
              coinCost: row.coinCost,
              category: row.category,
              previewImageUrl: row.previewImageUrl,
              unityAssetRef: row.unityAssetRef,
              status: row.status,
              sortOrder: row.sortOrder,
            ),
          )
          .toList();

      return Success(items);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch cached catalog',
        tag: 'ShopRepo',
        error: e,
      );
      return Failure(
        DatabaseError(message: 'Failed to load cached catalog: $e'),
      );
    }
  }

  /// Fetch shop catalog from server with optional filters and update local cache
  Future<Result<ShopCatalogResponse, AppError>> syncCatalog({
    int? tier,
    String? category,
  }) async {
    AppLogger.debug(
      'Syncing shop catalog from server (tier: $tier, category: $category)',
      tag: 'ShopRepo',
    );

    final queryParams = <String, dynamic>{};
    if (tier != null) queryParams['tier'] = tier;
    if (category != null) queryParams['category'] = category;

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.shopCatalog,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return result.when(
      success: (data) async {
        try {
          final itemsList = (data['items'] as List)
              .map(
                (item) => CosmeticModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();

          final userBalance = data['userBalance'] as int? ?? 0;
          final ownedIds =
              (data['ownedCosmeticIds'] as List?)
                  ?.map((id) => id as String)
                  .toList() ??
              [];

          // Cache cosmetics to local DB
          for (final cosmetic in itemsList) {
            await _db
                .into(_db.cosmeticsTable)
                .insertOnConflictUpdate(
                  CosmeticsTableCompanion.insert(
                    id: cosmetic.id,
                    name: cosmetic.name,
                    description: Value(cosmetic.description),
                    tier: cosmetic.tier,
                    coinCost: cosmetic.coinCost,
                    category: cosmetic.category,
                    previewImageUrl: cosmetic.previewImageUrl,
                    unityAssetRef: cosmetic.unityAssetRef,
                    status: cosmetic.status,
                    sortOrder: Value(cosmetic.sortOrder),
                  ),
                );
          }

          AppLogger.info(
            'Synced ${itemsList.length} cosmetics (balance: $userBalance)',
            tag: 'ShopRepo',
          );
          return Success(
            ShopCatalogResponse(
              items: itemsList,
              userBalance: userBalance,
              ownedCosmeticIds: ownedIds,
            ),
          );
        } catch (e) {
          AppLogger.error(
            'Failed to parse/cache catalog',
            tag: 'ShopRepo',
            error: e,
          );
          return Failure(DatabaseError(message: 'Failed to parse catalog: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  // ============== Purchase Operations ==============

  /// Purchase a cosmetic item. Returns purchase confirmation and new balance.
  Future<Result<PurchaseResponse, AppError>> purchaseCosmetic(
    String cosmeticId,
  ) async {
    AppLogger.debug('Purchasing cosmetic: $cosmeticId', tag: 'ShopRepo');

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.shopPurchase,
      data: {'cosmeticId': cosmeticId},
    );

    return result.when(
      success: (data) async {
        try {
          final purchase = data['purchase'] as Map<String, dynamic>;
          final newBalance = data['newBalance'] as int;

          final response = PurchaseResponse(
            cosmeticId: purchase['cosmeticId'] as String,
            cosmeticName: purchase['cosmeticName'] as String? ?? '',
            coinCost: purchase['coinCost'] as int,
            newBalance: newBalance,
            purchasedAt: DateTime.parse(purchase['purchasedAt'] as String),
          );

          // Cache ownership locally
          await _db
              .into(_db.userCosmeticsTable)
              .insertOnConflictUpdate(
                UserCosmeticsTableCompanion.insert(
                  id: '${response.cosmeticId}_owned',
                  cosmeticId: response.cosmeticId,
                  purchasedAt: response.purchasedAt,
                ),
              );

          // Update local balance cache
          final balanceRows = await _db.select(_db.coinBalances).get();
          if (balanceRows.isNotEmpty) {
            await (_db.update(
              _db.coinBalances,
            )..where((t) => t.id.equals(balanceRows.first.id))).write(
              CoinBalancesCompanion(
                currentBalance: Value(response.newBalance),
                lifetimeSpent: Value(
                  balanceRows.first.lifetimeSpent + response.coinCost,
                ),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }

          AppLogger.info(
            'Purchased ${response.cosmeticName} for ${response.coinCost} coins. New balance: ${response.newBalance}',
            tag: 'ShopRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse purchase response',
            tag: 'ShopRepo',
            error: e,
          );
          return Failure(
            DatabaseError(message: 'Failed to parse purchase: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  // ============== Owned Cosmetics Operations ==============

  /// Get locally cached owned cosmetic IDs
  Future<Result<List<String>, AppError>> getCachedOwnedIds() async {
    try {
      final rows = await _db.select(_db.userCosmeticsTable).get();
      return Success(rows.map((r) => r.cosmeticId).toList());
    } catch (e) {
      AppLogger.error(
        'Failed to fetch cached owned IDs',
        tag: 'ShopRepo',
        error: e,
      );
      return Failure(
        DatabaseError(message: 'Failed to load owned cosmetics: $e'),
      );
    }
  }
}

/// Provider for ShopRepository
@Riverpod(keepAlive: true)
ShopRepository shopRepository(Ref ref) {
  return ShopRepository(
    database: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
  );
}
