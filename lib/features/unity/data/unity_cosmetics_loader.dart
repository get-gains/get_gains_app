import 'dart:convert';

import 'package:flutter_embed_unity/flutter_embed_unity.dart';

import '../../../core/utils/logger.dart';
import '../../../services/database/app_database.dart';
import 'unity_message_contract.dart';

/// Unity Cosmetics Loader
///
/// Utility to load equipped cosmetics from Drift cache and send them
/// to Unity via the Flutter-Unity bridge. Call [loadEquippedCosmetics]
/// after receiving `scene_loaded` from Unity to dress the character.
class UnityCosmeticsLoader {
  UnityCosmeticsLoader._();

  /// Load equipped cosmetics from the local database and send to Unity.
  ///
  /// Should be called in any Unity widget's `onMessageFromUnity` handler
  /// when the `scene_loaded` event is received.
  static Future<void> loadEquippedCosmetics(AppDatabase db) async {
    try {
      final equippedRows = await db.select(db.equippedCosmeticsTable).get();

      if (equippedRows.isEmpty) {
        AppLogger.debug(
          'No equipped cosmetics in local DB — sending empty payload',
          tag: 'UnityCosmeticsLoader',
        );
        sendToUnity(
          UnityMessageContract.gameObjectName,
          UnityMessageContract.methodLoadEquippedCosmetics,
          jsonEncode({'cosmetics': <Map<String, String>>[]}),
        );
        return;
      }

      final cosmetics = <Map<String, String>>[];
      for (final row in equippedRows) {
        final cosmeticRows = await (db.select(
          db.cosmeticsTable,
        )..where((t) => t.id.equals(row.cosmeticId))).get();

        if (cosmeticRows.isEmpty) {
          // cosmeticsTable not yet synced for this id — skip rather than
          // sending a UUID as assetRef which Unity can never resolve.
          AppLogger.warning(
            'Equipped cosmetic ${row.cosmeticId} not found in local cosmeticsTable — '
            'skipping (sync inventory to refresh cache)',
            tag: 'UnityCosmeticsLoader',
          );
          continue;
        }

        final assetRef = cosmeticRows.first.unityAssetRef;
        AppLogger.debug(
          'Workout cosmetics: category=${row.category} assetRef=$assetRef',
          tag: 'UnityCosmeticsLoader',
        );
        cosmetics.add({'category': row.category, 'assetRef': assetRef});
      }

      final payload = jsonEncode({'cosmetics': cosmetics});
      AppLogger.debug(
        'Sending LoadEquippedCosmetics payload: $payload',
        tag: 'UnityCosmeticsLoader',
      );

      sendToUnity(
        UnityMessageContract.gameObjectName,
        UnityMessageContract.methodLoadEquippedCosmetics,
        payload,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to load equipped cosmetics for Unity',
        tag: 'UnityCosmeticsLoader',
        error: e,
      );
      // Send empty payload so Unity renders default appearance rather than
      // leaving cosmetics in an indeterminate state.
      sendToUnity(
        UnityMessageContract.gameObjectName,
        UnityMessageContract.methodLoadEquippedCosmetics,
        jsonEncode({'cosmetics': <Map<String, String>>[]}),
      );
    }
  }
}
