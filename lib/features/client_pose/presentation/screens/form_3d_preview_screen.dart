import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../coach_pose/data/models/landmark_models.dart';
import '../../../unity/data/unity_message_contract.dart';

/// Full-screen 3D preview of a single form's pose playback via Unity.
///
/// Receives [landmarkFrames] and [cameraAngle] from route extra. When Unity
/// sends [scene_loaded], sends LoadPoseFrames, SetCameraAngle, SetSkeletonColor,
/// and PlayPose so the stick figure (or future humanoid) plays in 3D.
class Form3DPreviewScreen extends StatefulWidget {
  const Form3DPreviewScreen({
    super.key,
    required this.landmarkFrames,
    required this.cameraAngle,
  });

  final List<LandmarkFrame> landmarkFrames;
  final String cameraAngle;

  @override
  State<Form3DPreviewScreen> createState() => _Form3DPreviewScreenState();
}

class _Form3DPreviewScreenState extends State<Form3DPreviewScreen> {
  bool _unityLoaded = false;
  bool _poseSent = false;

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
      _sendPoseToUnity();
    }
  }

  void _sendPoseToUnity() {
    if (_poseSent) return;
    _poseSent = true;
    final frames = widget.landmarkFrames;
    if (frames.isEmpty) return;

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
      widget.cameraAngle,
    );
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetSkeletonColor,
      '#00FFFF',
    );
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodPlayPose,
      '',
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
                        horizontal: 16, vertical: 10),
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
