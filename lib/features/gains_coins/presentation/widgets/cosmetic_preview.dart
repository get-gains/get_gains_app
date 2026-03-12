import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../unity/data/unity_message_contract.dart';
import '../../data/models/equipped_cosmetic_model.dart';

/// CosmeticPreview Widget
///
/// Renders cosmetics on the Unity character via the Flutter-Unity bridge.
/// Handles preview, clear, and load equipped cosmetics messages.
///
/// Usage:
/// ```dart
/// CosmeticPreview(
///   equippedCosmetics: equippedList,
///   onCosmeticsLoaded: () => print('loaded'),
///   onPreviewReady: () => print('preview applied'),
/// )
/// ```
class CosmeticPreview extends ConsumerStatefulWidget {
  const CosmeticPreview({
    super.key,
    this.equippedCosmetics = const [],
    this.onCosmeticsLoaded,
    this.onPreviewReady,
    this.height = 300,
    this.showControls = false,
  });

  /// Currently equipped cosmetics to load on init
  final List<EquippedCosmeticModel> equippedCosmetics;

  /// Called when Unity confirms cosmetics have been loaded
  final VoidCallback? onCosmeticsLoaded;

  /// Called when Unity confirms a preview has been applied
  final VoidCallback? onPreviewReady;

  /// Height of the Unity widget
  final double height;

  /// Whether to show rotation/camera controls
  final bool showControls;

  @override
  ConsumerState<CosmeticPreview> createState() => _CosmeticPreviewState();
}

class _CosmeticPreviewState extends ConsumerState<CosmeticPreview> {
  bool _isUnityLoaded = false;
  bool _areCosmeticsLoaded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Unity embed widget
              Positioned.fill(
                child: _isUnityLoaded
                    ? EmbedUnity(onMessageFromUnity: _onMessageFromUnity)
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading character...',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // Loading indicator for cosmetics (after Unity is ready)
              if (_isUnityLoaded && !_areCosmeticsLoaded)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Applying cosmetics...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMessageFromUnity(String message) {
    if (!mounted) return;

    if (message == UnityMessageContract.unityEventSceneLoaded) {
      setState(() => _isUnityLoaded = true);
      // Scene loaded — now send equipped cosmetics
      _loadEquippedCosmetics();
    } else if (message == UnityMessageContract.unityEventCosmeticsLoaded) {
      setState(() => _areCosmeticsLoaded = true);
      widget.onCosmeticsLoaded?.call();
    } else if (message == UnityMessageContract.unityEventCosmeticPreviewReady) {
      widget.onPreviewReady?.call();
    }
  }

  /// Send equipped cosmetics to Unity
  void _loadEquippedCosmetics() {
    final cosmetics = widget.equippedCosmetics
        .map((ec) => {'category': ec.category, 'assetRef': ec.unityAssetRef})
        .toList();

    final payload = jsonEncode({'cosmetics': cosmetics});

    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodLoadEquippedCosmetics,
      payload,
    );
  }

  /// Preview a cosmetic item (non-persistent, for shop/inventory browsing)
  void previewCosmetic({
    required String category,
    required String assetRef,
    bool showOnly = false,
  }) {
    if (!_isUnityLoaded) return;

    final payload = jsonEncode({
      'category': category,
      'assetRef': assetRef,
      'showOnly': showOnly,
    });

    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodPreviewCosmetic,
      payload,
    );
  }

  /// Clear preview and revert to equipped state
  void clearPreview() {
    if (!_isUnityLoaded) return;

    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodClearPreview,
      '',
    );
  }

  /// Reload equipped cosmetics (e.g., after equip/unequip)
  void reloadEquipped(List<EquippedCosmeticModel> cosmetics) {
    if (!_isUnityLoaded) return;

    setState(() => _areCosmeticsLoaded = false);

    final cosmeticsPayload = cosmetics
        .map((ec) => {'category': ec.category, 'assetRef': ec.unityAssetRef})
        .toList();

    final payload = jsonEncode({'cosmetics': cosmeticsPayload});

    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodLoadEquippedCosmetics,
      payload,
    );
  }
}
