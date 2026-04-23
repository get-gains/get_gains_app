import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/equipped_cosmetic_model.dart';
import '../providers/inventory_provider.dart';
import '../widgets/cosmetic_preview.dart';

/// Full-screen character inspection view for the Wardrobe.
///
/// Reuses [CosmeticPreview] so Unity messaging (SetCameraViewMode, cosmetics
/// load, orbit/pinch) behaves identically to the inline preview.
///
/// Navigation: pushed as a fullscreen dialog route from [InventoryScreen].
/// The inline [CosmeticPreview] is hidden while this screen is on top so
/// only one [EmbedUnity] instance is active at a time.
class CosmeticFullscreenScreen extends ConsumerWidget {
  const CosmeticFullscreenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(inventoryProvider);
    final equippedCosmetics = inventoryState is InventoryLoaded
        ? inventoryState.equippedCosmetics
        : const <EquippedCosmeticModel>[];

    final availableHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Inspect',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: CosmeticPreview(
          equippedCosmetics: equippedCosmetics,
          height: availableHeight,
        ),
      ),
    );
  }
}
