import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/database/app_database.dart';
import 'models/equipped_cosmetic_model.dart';
import 'models/user_cosmetic_model.dart';

part 'cosmetics_repository.g.dart';

/// Inventory response from the server.
class InventoryResponse {
  InventoryResponse({required this.owned, required this.equipped});

  final List<UserCosmeticModel> owned;
  final Map<String, String?> equipped;
}

/// Equip/Unequip response from the server.
class EquipResponse {
  EquipResponse({required this.equipped, required this.equippedCosmetics});

  final Map<String, String?> equipped;
  final List<EquippedCosmeticModel> equippedCosmetics;
}

/// Cosmetics Repository
///
/// Handles cosmetic inventory and equip/unequip operations.
/// Implements offline-first patterns:
/// - Local database (Drift) for offline equipped state cache
/// - API client for server inventory, equip/unequip calls
class CosmeticsRepository {
  CosmeticsRepository({
    required AppDatabase database,
    required ApiClient apiClient,
  }) : _db = database,
       _apiClient = apiClient;

  final AppDatabase _db;
  final ApiClient _apiClient;

  // ============== Inventory Operations ==============

  /// Get owned cosmetics from local cache (UserCosmetics joined with Cosmetics)
  Future<Result<List<UserCosmeticModel>, AppError>> getCachedInventory() async {
    try {
      AppLogger.debug('Fetching inventory from local DB', tag: 'CosmeticsRepo');

      final userCosmeticRows = await _db.select(_db.userCosmeticsTable).get();

      final items = <UserCosmeticModel>[];
      for (final uc in userCosmeticRows) {
        // Join with cosmetics table for full details
        final cosmeticRows = await (_db.select(
          _db.cosmeticsTable,
        )..where((t) => t.id.equals(uc.cosmeticId))).get();

        if (cosmeticRows.isNotEmpty) {
          final c = cosmeticRows.first;
          // Check if equipped
          final equippedRows = await (_db.select(
            _db.equippedCosmeticsTable,
          )..where((t) => t.cosmeticId.equals(c.id))).get();

          items.add(
            UserCosmeticModel(
              id: uc.id,
              cosmeticId: c.id,
              name: c.name,
              description: c.description,
              tier: c.tier,
              category: c.category,
              previewImageUrl: c.previewImageUrl,
              unityAssetRef: c.unityAssetRef,
              purchasedAt: uc.purchasedAt,
              isEquipped: equippedRows.isNotEmpty,
            ),
          );
        }
      }

      return Success(items);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch cached inventory',
        tag: 'CosmeticsRepo',
        error: e,
      );
      return Failure(
        DatabaseError(message: 'Failed to load cached inventory: $e'),
      );
    }
  }

  /// Fetch inventory from server and update local cache
  Future<Result<InventoryResponse, AppError>> syncInventory() async {
    AppLogger.debug('Syncing inventory from server', tag: 'CosmeticsRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.cosmeticsInventory,
    );

    return result.when(
      success: (data) async {
        try {
          final ownedList = (data['owned'] as List)
              .map(
                (item) =>
                    UserCosmeticModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();

          final equippedMap = <String, String?>{};
          final equippedRaw = data['equipped'] as Map<String, dynamic>? ?? {};
          for (final category in ['HEADWEAR', 'TOP', 'BOTTOM', 'ACCESSORY']) {
            equippedMap[category] = equippedRaw[category] as String?;
          }

          // Cache owned cosmetics locally
          for (final item in ownedList) {
            await _db
                .into(_db.userCosmeticsTable)
                .insertOnConflictUpdate(
                  UserCosmeticsTableCompanion.insert(
                    id: item.id,
                    cosmeticId: item.cosmeticId,
                    purchasedAt: item.purchasedAt,
                  ),
                );

            // Also cache cosmetic details
            await _db
                .into(_db.cosmeticsTable)
                .insertOnConflictUpdate(
                  CosmeticsTableCompanion.insert(
                    id: item.cosmeticId,
                    name: item.name,
                    description: Value(item.description),
                    tier: item.tier,
                    coinCost: 0, // Not in inventory response
                    category: item.category,
                    previewImageUrl: item.previewImageUrl,
                    unityAssetRef: item.unityAssetRef,
                    status: 'ACTIVE',
                  ),
                );
          }

          // Cache equipped state
          await _cacheEquippedState(equippedMap, ownedList);

          AppLogger.info(
            'Synced ${ownedList.length} owned cosmetics',
            tag: 'CosmeticsRepo',
          );
          return Success(
            InventoryResponse(owned: ownedList, equipped: equippedMap),
          );
        } catch (e) {
          AppLogger.error(
            'Failed to parse/cache inventory',
            tag: 'CosmeticsRepo',
            error: e,
          );
          return Failure(
            DatabaseError(message: 'Failed to parse inventory: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  // ============== Equip/Unequip Operations ==============

  /// Equip a cosmetic in its category slot
  Future<Result<EquipResponse, AppError>> equipCosmetic(
    String cosmeticId,
  ) async {
    AppLogger.debug('Equipping cosmetic: $cosmeticId', tag: 'CosmeticsRepo');

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.cosmeticsEquip,
      data: {'cosmeticId': cosmeticId},
    );

    return result.when(
      success: (data) async {
        try {
          final response = _parseEquipResponse(data);

          // Update local equipped cache
          await _cacheEquippedFromResponse(response);

          AppLogger.info(
            'Equipped cosmetic: $cosmeticId',
            tag: 'CosmeticsRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse equip response',
            tag: 'CosmeticsRepo',
            error: e,
          );
          return Failure(
            DatabaseError(message: 'Failed to parse equip response: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Unequip a cosmetic by its ID
  Future<Result<EquipResponse, AppError>> unequipCosmetic(
    String cosmeticId,
  ) async {
    AppLogger.debug('Unequipping cosmetic: $cosmeticId', tag: 'CosmeticsRepo');

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.cosmeticsUnequip,
      data: {'cosmeticId': cosmeticId},
    );

    return result.when(
      success: (data) async {
        try {
          final response = _parseEquipResponse(data);

          // Update local equipped cache
          await _cacheEquippedFromResponse(response);

          AppLogger.info(
            'Unequipped cosmetic: $cosmeticId',
            tag: 'CosmeticsRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse unequip response',
            tag: 'CosmeticsRepo',
            error: e,
          );
          return Failure(
            DatabaseError(message: 'Failed to parse unequip response: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  // ============== Equipped State Operations ==============

  /// Get equipped cosmetics from local cache (for Unity widget loading)
  Future<Result<List<EquippedCosmeticModel>, AppError>>
  getCachedEquipped() async {
    try {
      AppLogger.debug(
        'Fetching equipped cosmetics from local DB',
        tag: 'CosmeticsRepo',
      );

      final rows = await _db.select(_db.equippedCosmeticsTable).get();

      final items = <EquippedCosmeticModel>[];
      for (final row in rows) {
        // Get the unity asset ref from cosmetics table
        final cosmeticRows = await (_db.select(
          _db.cosmeticsTable,
        )..where((t) => t.id.equals(row.cosmeticId))).get();

        final unityAssetRef = cosmeticRows.isNotEmpty
            ? cosmeticRows.first.unityAssetRef
            : row.cosmeticId; // Fallback to ID

        items.add(
          EquippedCosmeticModel(
            cosmeticId: row.cosmeticId,
            category: row.category,
            unityAssetRef: unityAssetRef,
            equippedAt: row.equippedAt,
          ),
        );
      }

      return Success(items);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch cached equipped cosmetics',
        tag: 'CosmeticsRepo',
        error: e,
      );
      return Failure(
        DatabaseError(message: 'Failed to load cached equipped cosmetics: $e'),
      );
    }
  }

  /// Fetch equipped cosmetics from server (lightweight endpoint)
  Future<Result<List<EquippedCosmeticModel>, AppError>> syncEquipped() async {
    AppLogger.debug(
      'Syncing equipped cosmetics from server',
      tag: 'CosmeticsRepo',
    );

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.cosmeticsEquipped,
    );

    return result.when(
      success: (data) async {
        try {
          final equippedList = (data['equippedCosmetics'] as List)
              .map(
                (item) => EquippedCosmeticModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();

          // Replace local equipped cache entirely
          await _db.delete(_db.equippedCosmeticsTable).go();
          for (final ec in equippedList) {
            await _db
                .into(_db.equippedCosmeticsTable)
                .insertOnConflictUpdate(
                  EquippedCosmeticsTableCompanion.insert(
                    id: '${ec.category}_slot',
                    cosmeticId: ec.cosmeticId,
                    category: ec.category,
                    equippedAt: ec.equippedAt,
                  ),
                );
          }

          AppLogger.info(
            'Synced ${equippedList.length} equipped cosmetics',
            tag: 'CosmeticsRepo',
          );
          return Success(equippedList);
        } catch (e) {
          AppLogger.error(
            'Failed to parse/cache equipped cosmetics',
            tag: 'CosmeticsRepo',
            error: e,
          );
          return Failure(
            DatabaseError(message: 'Failed to parse equipped cosmetics: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Build the JSON payload for Unity's LoadEquippedCosmetics message
  Future<String> buildEquippedCosmeticsPayload() async {
    final result = await getCachedEquipped();
    return result.when(
      success: (equipped) {
        final cosmetics = equipped
            .map(
              (ec) => {'category': ec.category, 'assetRef': ec.unityAssetRef},
            )
            .toList();
        return jsonEncode({'cosmetics': cosmetics});
      },
      failure: (_) => jsonEncode({'cosmetics': <Map<String, dynamic>>[]}),
    );
  }

  // ============== Private Helpers ==============

  EquipResponse _parseEquipResponse(Map<String, dynamic> data) {
    final equippedMap = <String, String?>{};
    final equippedRaw = data['equipped'] as Map<String, dynamic>? ?? {};
    for (final category in ['HEADWEAR', 'TOP', 'BOTTOM', 'ACCESSORY']) {
      equippedMap[category] = equippedRaw[category] as String?;
    }

    final equippedCosmetics =
        (data['equippedCosmetics'] as List?)
            ?.map(
              (item) =>
                  EquippedCosmeticModel.fromJson(item as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return EquipResponse(
      equipped: equippedMap,
      equippedCosmetics: equippedCosmetics,
    );
  }

  Future<void> _cacheEquippedFromResponse(EquipResponse response) async {
    // Clear all equipped and re-insert
    await _db.delete(_db.equippedCosmeticsTable).go();
    for (final ec in response.equippedCosmetics) {
      await _db
          .into(_db.equippedCosmeticsTable)
          .insertOnConflictUpdate(
            EquippedCosmeticsTableCompanion.insert(
              id: '${ec.category}_slot',
              cosmeticId: ec.cosmeticId,
              category: ec.category,
              equippedAt: ec.equippedAt,
            ),
          );
    }
  }

  Future<void> _cacheEquippedState(
    Map<String, String?> equippedMap,
    List<UserCosmeticModel> ownedList,
  ) async {
    // Clear current equipped cache
    await _db.delete(_db.equippedCosmeticsTable).go();

    for (final entry in equippedMap.entries) {
      final cosmeticId = entry.value;
      if (cosmeticId == null) continue;

      // Find the owned item to get unity asset ref
      final ownedItem = ownedList
          .where((item) => item.cosmeticId == cosmeticId)
          .firstOrNull;

      if (ownedItem != null) {
        await _db
            .into(_db.equippedCosmeticsTable)
            .insertOnConflictUpdate(
              EquippedCosmeticsTableCompanion.insert(
                id: '${entry.key}_slot',
                cosmeticId: cosmeticId,
                category: entry.key,
                equippedAt: DateTime.now(),
              ),
            );
      }
    }
  }
}

/// Provider for CosmeticsRepository
@Riverpod(keepAlive: true)
CosmeticsRepository cosmeticsRepository(Ref ref) {
  return CosmeticsRepository(
    database: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
  );
}
