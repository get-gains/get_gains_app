import 'dart:convert';

import 'package:flutter_embed_unity/flutter_embed_unity.dart';

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
  ///
  /// Example:
  /// ```dart
  /// void _onMessageFromUnity(String message) {
  ///   if (message == UnityMessageContract.unityEventSceneLoaded) {
  ///     UnityCosmeticsLoader.loadEquippedCosmetics(database);
  ///   }
  /// }
  /// ```
  static Future<void> loadEquippedCosmetics(AppDatabase db) async {
    try {
      // Read equipped cosmetics from Drift cache
      final equippedRows = await db.select(db.equippedCosmeticsTable).get();

      final cosmetics = <Map<String, String>>[];
      for (final row in equippedRows) {
        // Look up the unityAssetRef from the cosmetics table
        final cosmeticRows = await (db.select(
          db.cosmeticsTable,
        )..where((t) => t.id.equals(row.cosmeticId))).get();

        final assetRef = cosmeticRows.isNotEmpty
            ? cosmeticRows.first.unityAssetRef
            : row.cosmeticId; // Fallback

        cosmetics.add({'category': row.category, 'assetRef': assetRef});
      }

      final payload = jsonEncode({'cosmetics': cosmetics});

      sendToUnity(
        UnityMessageContract.gameObjectName,
        UnityMessageContract.methodLoadEquippedCosmetics,
        payload,
      );
    } catch (_) {
      // Silently fail — cosmetics are non-critical for Unity functionality.
      // Character renders in default appearance if loading fails.
    }
  }
}
