import 'dart:math' show cos, sin, max;

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
    /// Debug: 3D rotation around vertical (Y) axis in radians.
    this.rotationY = 0,
  });

  final LandmarkFrame frame;
  final Color color;
  final double jointRadius;
  final double boneStrokeWidth;
  final double minConfidence;
  final bool mirrorX;
  final double rotationY;

  /// Project (x,y,z) with 3D rotation around Y through (cx,cy,cz). Uses depth
  /// scaling so the pose's z-range matches its x-range and rotation stays readable.
  (double, double) _project(
    double x,
    double y,
    double z,
    double cx,
    double cy,
    double cz,
    double zScale,
  ) {
    final x0 = x - cx;
    final z0 = (z - cz) * zScale;
    final xr = x0 * cos(rotationY) - z0 * sin(rotationY) + cx;
    final yr = y;
    if (mirrorX) {
      return (1.0 - xr, yr);
    }
    return (xr, yr);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final landmarks = frame.landmarks;
    if (landmarks.isEmpty) return;

    // --- Pass 1: centroid + z-scale for 3-D projection ---
    double cx = 0, cy = 0, cz = 0;
    double minX = 1, maxX = 0, minZ = 1, maxZ = -1;
    int n = 0;
    for (final p in landmarks.values) {
      cx += p.x;
      cy += p.y;
      cz += p.z;
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.z < minZ) minZ = p.z;
      if (p.z > maxZ) maxZ = p.z;
      n++;
    }
    if (n > 0) {
      cx /= n;
      cy /= n;
      cz /= n;
    }
    final rangeX = (maxX - minX).clamp(0.01, 1.0);
    final rangeZ = max(maxZ - minZ, 0.01);
    final zScale = rangeX / rangeZ;

    // --- Pass 2: project every landmark → bounding box in projected space ---
    // This ensures the skeleton fills the canvas regardless of whether the
    // recording was done on a landscape webcam (laptop) or portrait phone.
    double pMinX = double.infinity, pMaxX = double.negativeInfinity;
    double pMinY = double.infinity, pMaxY = double.negativeInfinity;
    for (final p in landmarks.values) {
      final (px, py) = _project(p.x, p.y, p.z, cx, cy, cz, zScale);
      if (px < pMinX) pMinX = px;
      if (px > pMaxX) pMaxX = px;
      if (py < pMinY) pMinY = py;
      if (py > pMaxY) pMaxY = py;
    }

    // 8 % padding so extremities (feet/hands) don't touch the edge.
    const pad = 0.08;
    final pRangeX = (pMaxX - pMinX).clamp(0.01, 2.0);
    final pRangeY = (pMaxY - pMinY).clamp(0.01, 2.0);
    final bMinX = pMinX - pad * pRangeX;
    final bMaxX = pMaxX + pad * pRangeX;
    final bMinY = pMinY - pad * pRangeY;
    final bMaxY = pMaxY + pad * pRangeY;
    final bRangeX = bMaxX - bMinX;
    final bRangeY = bMaxY - bMinY;

    double toSx(double nx) => ((nx - bMinX) / bRangeX) * size.width;
    double toSy(double ny) => ((ny - bMinY) / bRangeY) * size.height;

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

      final (axn, ayn) = _project(a.x, a.y, a.z, cx, cy, cz, zScale);
      final (bxn, byn) = _project(b.x, b.y, b.z, cx, cy, cz, zScale);

      canvas.drawLine(
        Offset(toSx(axn), toSy(ayn)),
        Offset(toSx(bxn), toSy(byn)),
        paint,
      );
    }

    // Draw joints
    for (final entry in landmarks.entries) {
      final point = entry.value;
      if (point.confidence < minConfidence * 0.5) continue;

      final opacity = point.confidence >= minConfidence ? 1.0 : 0.35;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final (pxn, pyn) = _project(point.x, point.y, point.z, cx, cy, cz, zScale);

      canvas.drawCircle(
        Offset(toSx(pxn), toSy(pyn)),
        jointRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PoseSkeletonPainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.color != color ||
      oldDelegate.rotationY != rotationY;
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
    this.rotationY = 0,
  });

  final List<LandmarkFrame> landmarkFrames;
  final Color color;
  final Color? backgroundColor;
  final bool showControls;
  final bool autoPlay;
  final bool mirrorX;
  final BorderRadius? borderRadius;
  final double rotationY;

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
                  rotationY: widget.rotationY,
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
