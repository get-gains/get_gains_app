import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/database/app_database.dart';
import '../../../coach_pose/data/models/landmark_models.dart';
import '../../../unity/data/unity_cosmetics_loader.dart';
import '../../../unity/data/unity_message_contract.dart';

/// Full-screen 3D preview of a single form's pose playback via Unity.
///
/// Receives [landmarkFrames] and [cameraAngle] from route extra. When Unity
/// sends [scene_loaded], sends LoadPoseFrames, SetCameraAngle, SetSkeletonColor,
/// and PlayPose so the stick figure (or future humanoid) plays in 3D.
class Form3DPreviewScreen extends ConsumerStatefulWidget {
  const Form3DPreviewScreen({
    super.key,
    required this.landmarkFrames,
    required this.cameraAngle,
  });

  final List<LandmarkFrame> landmarkFrames;
  final String cameraAngle;

  @override
  ConsumerState<Form3DPreviewScreen> createState() =>
      _Form3DPreviewScreenState();
}

class _Form3DPreviewScreenState extends ConsumerState<Form3DPreviewScreen> {
  bool _unityLoaded = false;
  bool _poseSent = false;

  /// Swap LEFT_* / RIGHT_* arm landmarks in Unity (mirrored rig vs recording).
  bool _debugSwapArmLandmarks = UnityMessageContract.defaultPoseDebugSwapArmLandmarks;

  /// Swap LEFT_* / RIGHT_* leg landmarks in Unity (hip through foot; rig vs recording).
  bool _debugSwapLegLandmarks = UnityMessageContract.defaultPoseDebugSwapLegLandmarks;

  /// Show cyan stick figure on top of the humanoid for comparison.
  bool _debugForceStickOverlay =
      UnityMessageContract.defaultPoseDebugForceStickFigure;

  /// Negate mapped world Z on arm landmarks in Unity (debug).
  bool _debugInvertArmDepthZ = UnityMessageContract.defaultPoseDebugInvertArmDepthZ;

  /// Negate mapped world Z on nose/eyes/ears after head straightening (debug).
  bool _debugInvertHeadDepthZ = UnityMessageContract.defaultPoseDebugInvertHeadDepthZ;

  /// Negate world Z on knee/ankle/foot (not hip) in Unity (debug).
  bool _debugInvertLegDepthZ = UnityMessageContract.defaultPoseDebugInvertLegDepthZ;

  void _resetPoseDebugToDefaults(StateSetter setModalState) {
    setState(() {
      _debugSwapArmLandmarks = UnityMessageContract.defaultPoseDebugSwapArmLandmarks;
      _debugSwapLegLandmarks = UnityMessageContract.defaultPoseDebugSwapLegLandmarks;
      _debugForceStickOverlay =
          UnityMessageContract.defaultPoseDebugForceStickFigure;
      _debugInvertArmDepthZ = UnityMessageContract.defaultPoseDebugInvertArmDepthZ;
      _debugInvertHeadDepthZ = UnityMessageContract.defaultPoseDebugInvertHeadDepthZ;
      _debugInvertLegDepthZ = UnityMessageContract.defaultPoseDebugInvertLegDepthZ;
    });
    setModalState(() {});
    _sendPoseDebugToUnity();
  }

  @override
  void initState() {
    super.initState();
    // If Unity never sends scene_loaded (e.g. channel delay), assume ready and send pose after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_unityLoaded) {
        setState(() => _unityLoaded = true);
        _sendPoseToUnity();
      }
    });
  }

  void _onMessageFromUnity(String message) {
    if (!mounted) return;
    if (message == UnityMessageContract.unityEventSceneLoaded) {
      setState(() => _unityLoaded = true);
      // Load equipped cosmetics onto the character
      UnityCosmeticsLoader.loadEquippedCosmetics(ref.read(appDatabaseProvider));
      _sendPoseToUnity();
    }
  }

  void _sendPoseToUnity() {
    if (_poseSent) return;
    _poseSent = true;
    final frames = widget.landmarkFrames;
    if (frames.isEmpty) return;

    // Ensure full-figure framing (restores wide orbit if previously in Cosmetic mode).
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetCameraViewMode,
      'WORKOUT',
    );

    final payload = jsonEncode({
      'frames': frames.map((f) => f.toJson()).toList(),
      'fps': 15,
      'loop': true,
    });

    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodLoadPoseFrames,
      payload,
    );
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetCameraAngle,
      UnityMessageContract.cameraAngleDiagonal,
    );
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetRecordingAngleHint,
      widget.cameraAngle,
    );
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetSkeletonColor,
      '#FFA500',
    );
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodPlayPose,
      '',
    );
    _sendPoseDebugToUnity();
  }

  void _sendPoseDebugToUnity() {
    if (!_poseSent) return;
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetPoseDebugOptions,
      jsonEncode({
        'swapArmLandmarks': _debugSwapArmLandmarks,
        'swapLegLandmarks': _debugSwapLegLandmarks,
        'forceShowStickFigure': _debugForceStickOverlay,
        'invertArmDepthZ': _debugInvertArmDepthZ,
        'invertHeadDepthZ': _debugInvertHeadDepthZ,
        'invertLegDepthZ': _debugInvertLegDepthZ,
      }),
    );
  }

  void _openPoseDebugSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pose debug',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use these if shoulders look swapped vs the recording, or to '
                      'compare the cyan skeleton to the mesh.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Swap arm landmarks (L/R)'),
                      subtitle: const Text(
                        'Feeds right landmarks into the left arm bones and vice versa.',
                      ),
                      value: _debugSwapArmLandmarks,
                      onChanged: _poseSent
                          ? (v) {
                              setModalState(() => _debugSwapArmLandmarks = v);
                              setState(() => _debugSwapArmLandmarks = v);
                              _sendPoseDebugToUnity();
                            }
                          : null,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Swap leg landmarks (L/R)'),
                      subtitle: const Text(
                        'Swaps left/right leg tracking (hip through foot). On by default.',
                      ),
                      value: _debugSwapLegLandmarks,
                      onChanged: _poseSent
                          ? (v) {
                              setModalState(() => _debugSwapLegLandmarks = v);
                              setState(() => _debugSwapLegLandmarks = v);
                              _sendPoseDebugToUnity();
                            }
                          : null,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show skeleton overlay'),
                      subtitle: const Text(
                        'Keeps the cyan stick figure visible with the humanoid.',
                      ),
                      value: _debugForceStickOverlay,
                      onChanged: _poseSent
                          ? (v) {
                              setModalState(() => _debugForceStickOverlay = v);
                              setState(() => _debugForceStickOverlay = v);
                              _sendPoseDebugToUnity();
                            }
                          : null,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Invert arm depth (Z)'),
                      subtitle: const Text(
                        'Flips world Z on shoulder/elbow/wrist/hand landmarks for depth tuning.',
                      ),
                      value: _debugInvertArmDepthZ,
                      onChanged: _poseSent
                          ? (v) {
                              setModalState(() => _debugInvertArmDepthZ = v);
                              setState(() => _debugInvertArmDepthZ = v);
                              _sendPoseDebugToUnity();
                            }
                          : null,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Invert head depth (Z)'),
                      subtitle: const Text(
                        'Flips world Z on nose/eyes/ears after head straightening; '
                        'use if the head looks up or wrong in depth.',
                      ),
                      value: _debugInvertHeadDepthZ,
                      onChanged: _poseSent
                          ? (v) {
                              setModalState(() => _debugInvertHeadDepthZ = v);
                              setState(() => _debugInvertHeadDepthZ = v);
                              _sendPoseDebugToUnity();
                            }
                          : null,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Invert leg depth (Z)'),
                      subtitle: const Text(
                        'Flips world Z on knee, ankle, and foot landmarks (not hips) '
                        'so legs match depth like arms. On by default.',
                      ),
                      value: _debugInvertLegDepthZ,
                      onChanged: _poseSent
                          ? (v) {
                              setModalState(() => _debugInvertLegDepthZ = v);
                              setState(() => _debugInvertLegDepthZ = v);
                              _sendPoseDebugToUnity();
                            }
                          : null,
                    ),
                    if (_poseSent) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              _resetPoseDebugToDefaults(setModalState),
                          child: const Text('Reset to defaults'),
                        ),
                      ),
                    ],
                    if (!_poseSent)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Wait for the pose to load before toggling.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('3D Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Pose debug',
            onPressed: _openPoseDebugSheet,
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_exit),
            tooltip: 'Minimize',
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Show Unity view immediately so the native view can start loading right away
          EmbedUnity(onMessageFromUnity: _onMessageFromUnity),
          // Small non-blocking indicator until scene is ready (avoids full-screen block)
          if (!_unityLoaded)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Loading 3D view...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
