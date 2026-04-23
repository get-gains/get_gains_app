import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../unity/data/unity_message_contract.dart';
import '../../data/models/equipped_cosmetic_model.dart';

/// How long to wait for Unity's scene_loaded before assuming it's already ready.
const _kUnityReadyTimeout = Duration(seconds: 10);

class CosmeticPreview extends ConsumerStatefulWidget {
  const CosmeticPreview({
    super.key,
    this.equippedCosmetics = const [],
    this.onCosmeticsLoaded,
    this.onPreviewReady,
    this.height = 300,
    this.showControls = false,
  });

  final List<EquippedCosmeticModel> equippedCosmetics;
  final VoidCallback? onCosmeticsLoaded;
  final VoidCallback? onPreviewReady;
  final double height;
  final bool showControls;

  @override
  ConsumerState<CosmeticPreview> createState() => _CosmeticPreviewState();
}

class _CosmeticPreviewState extends ConsumerState<CosmeticPreview> {
  bool _isUnityLoaded = false;
  bool _areCosmeticsLoaded = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // If Unity already fired scene_loaded before this widget was mounted
    // (common when returning to the wardrobe), fall back after a timeout.
    _timeoutTimer = Timer(_kUnityReadyTimeout, () {
      if (mounted && !_isUnityLoaded) {
        AppLogger.warning(
          'Unity scene_loaded not received within timeout — assuming ready',
          tag: 'CosmeticPreview',
        );
        setState(() => _isUnityLoaded = true);
        _loadEquippedCosmetics();
      }
    });
  }

  @override
  void didUpdateWidget(CosmeticPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isUnityLoaded) return;

    // Reload Unity cosmetics only when the equipped set actually changes.
    // Compare by cosmeticId to avoid false positives from DateTime.now() in
    // InventoryLoaded.equippedCosmetics getter.
    final oldIds =
        oldWidget.equippedCosmetics.map((e) => e.cosmeticId).toSet();
    final newIds = widget.equippedCosmetics.map((e) => e.cosmeticId).toSet();
    if (!setEquals(oldIds, newIds)) {
      AppLogger.debug(
        'Equipped cosmetics changed — reloading Unity preview',
        tag: 'CosmeticPreview',
      );
      reloadEquipped(widget.equippedCosmetics);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

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
              // Unity is always in the tree so it can receive scene_loaded
              // even if the message arrives before the timeout fires.
              // RepaintBoundary isolates the platform view from Flutter repaints.
              Positioned.fill(
                child: RepaintBoundary(
                  child: EmbedUnity(onMessageFromUnity: _onMessageFromUnity),
                ),
              ),

              // Opaque loading overlay — hidden once Unity is ready
              if (!_isUnityLoaded)
                Positioned.fill(
                  child: Container(
                    color:
                        isDark ? AppColors.surface1Dark : AppColors.surface1Light,
                    child: Center(
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
                ),

              // Cosmetics-applying indicator — IgnorePointer so the banner
              // never eats touch events destined for the orbit controller.
              if (_isUnityLoaded && !_areCosmeticsLoaded)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMessageFromUnity(String message) {
    if (!mounted) return;
    AppLogger.debug(
      'Unity → CosmeticPreview: "$message"',
      tag: 'CosmeticPreview',
    );

    if (message == UnityMessageContract.unityEventSceneLoaded) {
      _timeoutTimer?.cancel();
      setState(() => _isUnityLoaded = true);
      _loadEquippedCosmetics();
    } else if (message == UnityMessageContract.unityEventCosmeticsLoaded) {
      setState(() => _areCosmeticsLoaded = true);
      widget.onCosmeticsLoaded?.call();
    } else if (message == UnityMessageContract.unityEventCosmeticPreviewReady) {
      widget.onPreviewReady?.call();
    }
  }

  void _loadEquippedCosmetics() {
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetCameraViewMode,
      'COSMETIC',
    );

    final cosmetics = widget.equippedCosmetics
        .map((ec) => {'category': ec.category, 'assetRef': ec.unityAssetRef})
        .toList();

    final payload = jsonEncode({'cosmetics': cosmetics});
    AppLogger.debug(
      'Wardrobe → Unity LoadEquippedCosmetics: $payload',
      tag: 'CosmeticPreview',
    );

    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodLoadEquippedCosmetics,
      payload,
    );
  }

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

  void clearPreview() {
    if (!_isUnityLoaded) return;

    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodClearPreview,
      '',
    );
  }

  /// Re-applies Cosmetic framing in Unity (restores close-up after user pans away).
  void resetView() {
    if (!_isUnityLoaded) return;
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodResetCosmeticView,
      '',
    );
  }

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
