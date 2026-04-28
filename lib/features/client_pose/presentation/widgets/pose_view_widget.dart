import 'package:flutter/material.dart';

import '../../../coach_pose/data/models/landmark_models.dart';
import 'pose_skeleton_painter.dart';

/// How to render recorded pose playback: 2D skeleton or 3D (Unity when available).
enum PoseViewMode {
  /// Draw pose as 2D bones + joints (PosePlaybackWidget).
  raw2D,

  /// Prefer 3D rig via Unity when the parent provides an embed; otherwise fall back to 2D.
  unity3D,
}

/// Unified pose viewing widget. Renders [landmarkFrames] as either 2D skeleton
/// or delegates to Unity when [mode] is [PoseViewMode.unity3D] and a Unity
/// embed context is available (e.g. on [ClientUnityRecordingScreen]).
///
/// For now, when [mode] is [PoseViewMode.unity3D], the 3D view is handled by
/// the parent (e.g. full-screen EmbedUnity); this widget shows 2D fallback for
/// inline playback (e.g. comparison panels). All "recorded pose" usage goes
/// through this widget so a single contract can later support 3D in-place.
class PoseViewWidget extends StatelessWidget {
  const PoseViewWidget({
    super.key,
    required this.landmarkFrames,
    this.mode = PoseViewMode.raw2D,
    this.color = Colors.cyan,
    this.backgroundColor,
    this.showControls = true,
    this.autoPlay = true,
    this.mirrorX = false,
    this.borderRadius,
    this.rotationY = 0,
  });

  final List<LandmarkFrame> landmarkFrames;
  final PoseViewMode mode;
  final Color color;
  final Color? backgroundColor;
  final bool showControls;
  final bool autoPlay;
  final bool mirrorX;
  final BorderRadius? borderRadius;
  final double rotationY;

  @override
  Widget build(BuildContext context) {
    // When mode is unity3D, the parent (e.g. ClientUnityRecordingScreen) typically
    // shows the main 3D view via EmbedUnity and sends frames separately. Inline
    // playback (e.g. side-by-side comparison) uses 2D fallback until we have
    // a second Unity embed or split 3D view.
    return PosePlaybackWidget(
      landmarkFrames: landmarkFrames,
      color: color,
      backgroundColor: backgroundColor,
      showControls: showControls,
      autoPlay: autoPlay,
      mirrorX: mirrorX,
      borderRadius: borderRadius,
      rotationY: rotationY,
    );
  }
}
