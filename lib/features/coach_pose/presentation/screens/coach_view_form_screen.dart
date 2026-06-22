import 'dart:convert';
import 'dart:math' show pi;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/router_provider.dart';
import '../../../../services/database/app_database.dart';
import '../../../../services/pose/frames_blob.dart';
import '../../../../widgets/widgets.dart';
import '../../../client_pose/presentation/widgets/pose_view_widget.dart';
import '../../../unity/data/unity_cosmetics_loader.dart';
import '../../../unity/data/unity_message_contract.dart';
import '../../data/coach_pose_repository.dart';
import '../../data/models/landmark_models.dart';

/// Coach View Form Screen
///
/// Displays the coach's own recorded reference form for an exercise with
/// an animated skeleton playback of the recorded landmarks. Fetches the
/// frames blob from S3 via a presigned download URL.
class CoachViewFormScreen extends ConsumerStatefulWidget {
  const CoachViewFormScreen({
    super.key,
    required this.exerciseId,
    required this.formId,
  });

  final String exerciseId;
  final String formId;

  @override
  ConsumerState<CoachViewFormScreen> createState() =>
      _CoachViewFormScreenState();
}

class _CoachViewFormScreenState extends ConsumerState<CoachViewFormScreen> {
  late Future<CoachFramesBlob?> _blobFuture;

  @override
  void initState() {
    super.initState();
    _loadBlob();
  }

  void _loadBlob() {
    _blobFuture = _fetchBlob();
  }

  Future<CoachFramesBlob?> _fetchBlob() async {
    final repo = ref.read(coachPoseRepositoryProvider);
    final urlResult = await repo.getFormDownloadUrl(widget.formId);

    return urlResult.when(
      success: (url) async {
        try {
          final response = await Dio().get<Map<String, dynamic>>(url);
          if (response.data == null) return null;
          final blob = FramesBlob.fromJson(response.data!);
          return blob is CoachFramesBlob ? blob : null;
        } catch (e) {
          AppLogger.error(
            'Failed to fetch frames blob from S3',
            tag: 'CoachViewForm',
            error: e,
          );
          return null;
        }
      },
      failure: (error) {
        AppLogger.warning(
          'Failed to get form download URL: ${error.message}',
          tag: 'CoachViewForm',
        );
        return null;
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
      appBar: AppBar(title: const Text('View Form'), centerTitle: true),
      body: FutureBuilder<CoachFramesBlob?>(
        future: _blobFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final blob = snapshot.data;
          if (blob == null) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'Form Not Found',
              description:
                  'Could not load this form. It may have been deleted.',
              actionLabel: 'Go Back',
              onAction: () => context.pop(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormPlaybackCard(
                  exerciseId: widget.exerciseId,
                  formId: widget.formId,
                  blob: blob,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _PreviewMode { twoD, threeD }

/// Card showing form metadata + animated skeleton or inline 3D Unity preview.
class _FormPlaybackCard extends StatefulWidget {
  const _FormPlaybackCard({
    required this.exerciseId,
    required this.formId,
    required this.blob,
    required this.isDark,
  });

  final String exerciseId;
  final String formId;
  final CoachFramesBlob blob;
  final bool isDark;

  @override
  State<_FormPlaybackCard> createState() => _FormPlaybackCardState();
}

/// Debug: 3D rotation range limited so the figure stays readable (no stretched lines).
const double _rotationMinRadians = -pi / 3; // -60°
const double _rotationMaxRadians = pi / 3; // 60°

class _FormPlaybackCardState extends State<_FormPlaybackCard> {
  _PreviewMode _mode = _PreviewMode.twoD;
  bool _unityReady = false;
  bool _poseSent = false;
  double _rotationRadians = 0;
  bool _rotatorSliderEnabled = true;
  double _rotationRadiansBackup = 0;

  List<LandmarkFrame> get _frames => widget.blob.landmarkFrames;

  String get _cameraAngle => widget.blob.cameraAngle;

  void _toggleRotatorSlider() {
    setState(() {
      _rotatorSliderEnabled = !_rotatorSliderEnabled;
      if (!_rotatorSliderEnabled) {
        _rotationRadiansBackup = _rotationRadians;
        _rotationRadians = 0;
      } else {
        _rotationRadians = _rotationRadiansBackup;
      }
    });
  }

  void _toggle3D() {
    setState(() {
      if (_mode == _PreviewMode.twoD) {
        _mode = _PreviewMode.threeD;
        _unityReady = false;
        _poseSent = false;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _mode == _PreviewMode.threeD && !_unityReady) {
            setState(() => _unityReady = true);
            _sendPoseToUnity();
          }
        });
      } else {
        _mode = _PreviewMode.twoD;
      }
    });
  }

  void _onMessageFromUnity(String message) {
    if (!mounted || _mode != _PreviewMode.threeD) return;
    if (message == UnityMessageContract.unityEventSceneLoaded) {
      setState(() => _unityReady = true);
      final container = ProviderScope.containerOf(context);
      UnityCosmeticsLoader.loadEquippedCosmetics(
        container.read(appDatabaseProvider),
      );
      _sendPoseToUnity();
    }
  }

  void _sendPoseToUnity() {
    if (_poseSent || _frames.isEmpty) return;
    _poseSent = true;

    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetCameraViewMode,
      'WORKOUT',
    );

    final payload = jsonEncode({
      'frames': _frames.map((f) => f.toJson()).toList(),
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
      _cameraAngle,
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
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetPoseDebugOptions,
      UnityMessageContract.defaultPoseDebugOptionsPayload(),
    );
  }

  void _openFullscreen() {
    context.push(
      AppRoutes.coachForm3DPreview
          .replaceFirst(':id', widget.exerciseId)
          .replaceFirst(':formId', widget.formId),
      extra: {'landmarkFrames': _frames, 'cameraAngle': _cameraAngle},
    );
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = widget.blob.durationMs;
    final frameRate = widget.blob.frameRate;
    final totalFrames = widget.blob.totalFrames;
    final durationSec = (durationMs / 1000).toStringAsFixed(1);
    final hasFrames = _frames.isNotEmpty;

    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview area
          if (hasFrames)
            SizedBox(
              height: 280,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_mode == _PreviewMode.twoD)
                      PoseViewWidget(
                        landmarkFrames: _frames,
                        mode: PoseViewMode.raw2D,
                        color: widget.isDark ? Colors.cyanAccent : Colors.cyan,
                        backgroundColor: widget.isDark
                            ? const Color(0xFF1A1A2E)
                            : const Color(0xFF0F0F1A),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        rotationY: _rotationRadians,
                      )
                    else
                      EmbedUnity(onMessageFromUnity: _onMessageFromUnity),

                    // Mode toggle pill (top-right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_mode == _PreviewMode.twoD)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _RotatorTogglePill(
                                enabled: _rotatorSliderEnabled,
                                onToggle: _toggleRotatorSlider,
                              ),
                            ),
                          _ViewModeToggle(mode: _mode, onToggle: _toggle3D),
                        ],
                      ),
                    ),

                    // Debug: 3D rotate (limited range so figure stays readable)
                    if (_mode == _PreviewMode.twoD && _rotatorSliderEnabled)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.rotate_right,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '3D Rotate:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _rotationRadians,
                                    min: _rotationMinRadians,
                                    max: _rotationMaxRadians,
                                    activeColor: Colors.cyanAccent,
                                    onChanged: (v) =>
                                        setState(() => _rotationRadians = v),
                                  ),
                                ),
                                Text(
                                  '${(_rotationRadians * 180 / pi).round()}°',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Fullscreen button (only in 3D mode)
                    if (_mode == _PreviewMode.threeD)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _openFullscreen,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 3D loading indicator
                    if (_mode == _PreviewMode.threeD && !_unityReady)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 8,
                        child: Center(
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Loading 3D...',
                                    style: TextStyle(
                                      color: Colors.white,
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
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, size: 32, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No landmark data for playback',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          // Metadata
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.videocam,
                      color: widget.isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AppBadge(
                          label: _cameraAngle,
                          variant: AppBadgeVariant.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Duration',
                  value: '${durationSec}s',
                  isDark: widget.isDark,
                ),
                _InfoRow(
                  label: 'Frame Rate',
                  value: '$frameRate fps',
                  isDark: widget.isDark,
                ),
                _InfoRow(
                  label: 'Total Frames',
                  value: '$totalFrames',
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle pill for enabling/disabling the (2D) rotator slider overlay.
class _RotatorTogglePill extends StatelessWidget {
  const _RotatorTogglePill({required this.enabled, required this.onToggle});

  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rotate_right,
                size: 16,
                color: enabled ? Colors.cyanAccent : Colors.white70,
              ),
              const SizedBox(width: 4),
              Text(
                'Rotator',
                style: TextStyle(
                  color: enabled ? Colors.cyanAccent : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact toggle pill for switching between 2D and 3D preview.
class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.mode, required this.onToggle});

  final _PreviewMode mode;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final is3D = mode == _PreviewMode.threeD;
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                is3D ? Icons.view_in_ar : Icons.grid_on,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                is3D ? '3D' : '2D',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
