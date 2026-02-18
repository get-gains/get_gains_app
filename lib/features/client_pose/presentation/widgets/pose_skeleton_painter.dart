import 'package:flutter/material.dart';

import '../../../coach_pose/data/models/landmark_models.dart';

/// Defines the body connection lines (bones) for the skeleton.
///
/// These correspond to MediaPipe / MLKit Pose landmark names.
const List<(String, String)> _skeletonBones = [
  // Head
  ('LEFT_EAR', 'LEFT_EYE'),
  ('RIGHT_EAR', 'RIGHT_EYE'),
  ('LEFT_EYE', 'NOSE'),
  ('RIGHT_EYE', 'NOSE'),

  // Torso
  ('LEFT_SHOULDER', 'RIGHT_SHOULDER'),
  ('LEFT_SHOULDER', 'LEFT_HIP'),
  ('RIGHT_SHOULDER', 'RIGHT_HIP'),
  ('LEFT_HIP', 'RIGHT_HIP'),

  // Left arm
  ('LEFT_SHOULDER', 'LEFT_ELBOW'),
  ('LEFT_ELBOW', 'LEFT_WRIST'),

  // Right arm
  ('RIGHT_SHOULDER', 'RIGHT_ELBOW'),
  ('RIGHT_ELBOW', 'RIGHT_WRIST'),

  // Left leg
  ('LEFT_HIP', 'LEFT_KNEE'),
  ('LEFT_KNEE', 'LEFT_ANKLE'),

  // Right leg
  ('RIGHT_HIP', 'RIGHT_KNEE'),
  ('RIGHT_KNEE', 'RIGHT_ANKLE'),

  // Feet
  ('LEFT_ANKLE', 'LEFT_HEEL'),
  ('LEFT_HEEL', 'LEFT_FOOT_INDEX'),
  ('RIGHT_ANKLE', 'RIGHT_HEEL'),
  ('RIGHT_HEEL', 'RIGHT_FOOT_INDEX'),
];

/// CustomPainter that draws a 2D stick-figure skeleton from a [LandmarkFrame].
///
/// Landmarks use normalized coordinates (0-1), which are mapped to the
/// canvas size. Bones below [minConfidence] are drawn with reduced opacity.
class PoseSkeletonPainter extends CustomPainter {
  PoseSkeletonPainter({
    required this.frame,
    this.color = Colors.cyan,
    this.jointRadius = 4.0,
    this.boneStrokeWidth = 2.5,
    this.minConfidence = 0.3,
    this.mirrorX = false,
  });

  final LandmarkFrame frame;
  final Color color;
  final double jointRadius;
  final double boneStrokeWidth;
  final double minConfidence;
  final bool mirrorX;

  @override
  void paint(Canvas canvas, Size size) {
    final landmarks = frame.landmarks;

    // Draw bones
    for (final (from, to) in _skeletonBones) {
      final a = landmarks[from];
      final b = landmarks[to];
      if (a == null || b == null) continue;

      final minConf = a.confidence < b.confidence ? a.confidence : b.confidence;
      if (minConf < minConfidence * 0.5) continue;

      final opacity = minConf >= minConfidence ? 1.0 : 0.35;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = boneStrokeWidth
        ..strokeCap = StrokeCap.round;

      final ax = mirrorX ? (1.0 - a.x) * size.width : a.x * size.width;
      final ay = a.y * size.height;
      final bx = mirrorX ? (1.0 - b.x) * size.width : b.x * size.width;
      final by = b.y * size.height;

      canvas.drawLine(Offset(ax, ay), Offset(bx, by), paint);
    }

    // Draw joints
    for (final entry in landmarks.entries) {
      final point = entry.value;
      if (point.confidence < minConfidence * 0.5) continue;

      final opacity = point.confidence >= minConfidence ? 1.0 : 0.35;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final px = mirrorX ? (1.0 - point.x) * size.width : point.x * size.width;
      final py = point.y * size.height;

      canvas.drawCircle(Offset(px, py), jointRadius, paint);
    }
  }

  @override
  bool shouldRepaint(PoseSkeletonPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.color != color;
}

/// Widget that plays back a sequence of [LandmarkFrame]s as an animated
/// skeleton. Shows the coach's reference form as a looping animation.
class PosePlaybackWidget extends StatefulWidget {
  const PosePlaybackWidget({
    super.key,
    required this.landmarkFrames,
    this.color = Colors.cyan,
    this.backgroundColor,
    this.showControls = true,
    this.autoPlay = true,
    this.mirrorX = false,
    this.borderRadius,
  });

  final List<LandmarkFrame> landmarkFrames;
  final Color color;
  final Color? backgroundColor;
  final bool showControls;
  final bool autoPlay;
  final bool mirrorX;
  final BorderRadius? borderRadius;

  @override
  State<PosePlaybackWidget> createState() => _PosePlaybackWidgetState();
}

class _PosePlaybackWidgetState extends State<PosePlaybackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentFrameIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    final frames = widget.landmarkFrames;
    if (frames.isEmpty) return;

    // Calculate total duration from timestamp range
    final totalMs = frames.last.timestampMs - frames.first.timestampMs;
    final duration = totalMs > 0
        ? Duration(milliseconds: totalMs)
        : const Duration(seconds: 3);

    _controller = AnimationController(vsync: this, duration: duration);

    _controller.addListener(_onTick);

    if (widget.autoPlay) {
      _controller.repeat();
      _isPlaying = true;
    }
  }

  void _onTick() {
    final frames = widget.landmarkFrames;
    if (frames.isEmpty) return;

    final progress = _controller.value;
    final newIndex = (progress * (frames.length - 1)).round().clamp(
      0,
      frames.length - 1,
    );

    if (newIndex != _currentFrameIndex) {
      setState(() => _currentFrameIndex = newIndex);
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.landmarkFrames;
    if (frames.isEmpty) {
      return const Center(child: Text('No frames to display'));
    }

    final currentFrame = frames[_currentFrameIndex];

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      child: Container(
        color: widget.backgroundColor ?? Colors.black87,
        child: Stack(
          children: [
            // Skeleton canvas
            Positioned.fill(
              child: CustomPaint(
                painter: PoseSkeletonPainter(
                  frame: currentFrame,
                  color: widget.color,
                  mirrorX: widget.mirrorX,
                ),
              ),
            ),

            // Controls overlay
            if (widget.showControls)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    // Play/pause
                    GestureDetector(
                      onTap: _togglePlayback,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Progress
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: frames.length > 1
                              ? _currentFrameIndex / (frames.length - 1)
                              : 0.0,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.color,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Frame counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentFrameIndex + 1}/${frames.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
