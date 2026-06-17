// lib/features/coach_client_progress/presentation/screens/form_review_screen.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/api/api_client.dart';
import '../../../../services/database/app_database.dart';
import '../../../../services/pose/frames_blob.dart';
import '../../../../widgets/widgets.dart';
import '../../../client_pose/presentation/widgets/pose_view_widget.dart';
import '../../../coach_pose/data/models/landmark_models.dart';
import '../../../unity/data/unity_cosmetics_loader.dart';
import '../../../unity/data/unity_message_contract.dart';
import '../../data/models/models.dart';

/// Form Review Screen
///
/// Displays the full detail of a single form comparison result:
/// - Overall score badge
/// - Exercise info & coach info
/// - Animated 2D/3D skeleton playback of the recorded form
/// - Segment-level scores bar chart
/// - Corrections list with segment labels
/// - Technical metadata (camera angle, duration, frames)
///
/// Receives the `ClientFormResult` via `GoRoute.extra` to avoid
/// an extra network call. Falls back to a placeholder if data missing.
class FormReviewScreen extends ConsumerStatefulWidget {
  const FormReviewScreen({
    super.key,
    required this.userId,
    required this.resultId,
    this.result,
  });

  final String userId;
  final String resultId;
  final ClientFormResult? result;

  @override
  ConsumerState<FormReviewScreen> createState() => _FormReviewScreenState();
}

class _FormReviewScreenState extends ConsumerState<FormReviewScreen> {
  Future<FramesBlob?>? _blobFuture;

  @override
  void initState() {
    super.initState();
    final result = widget.result;
    if (result != null && result.recordedFramesKey != null) {
      _blobFuture = _fetchBlob(result.recordedFramesKey!);
    }
  }

  Future<FramesBlob?> _fetchBlob(String key) async {
    final apiClient = ref.read(apiClientProvider);
    final urlResult = await apiClient.get<Map<String, dynamic>>(
      ApiConstants.poseFramesDownloadUrl,
      queryParameters: {'key': key},
    );

    return urlResult.when(
      success: (data) async {
        try {
          final url = data['url'] as String;
          final response = await Dio().get<Map<String, dynamic>>(url);
          if (response.data == null) return null;
          return FramesBlob.fromJson(response.data!);
        } catch (e) {
          AppLogger.error(
            'Failed to fetch form frames blob from S3',
            tag: 'FormReview',
            error: e,
          );
          return null;
        }
      },
      failure: (error) {
        AppLogger.warning(
          'Failed to get frames download URL: ${error.message}',
          tag: 'FormReview',
        );
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (widget.result == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Form Review'),
        ),
        body: const Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Missing Data',
            description:
                'Form result data was not passed. Please navigate from the client progress screen.',
          ),
        ),
      );
    }

    final data = widget.result!;
    final scorePercent = (data.overallScore * 100).toInt();
    final exerciseName =
        data.exerciseName ?? data.exerciseForm?.exercise?.name ?? 'Unknown Exercise';
    final coachName = data.exerciseForm?.coach?.name;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Form Review',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Score Hero ───────────────────────────────
            Center(
              child: _ScoreHero(
                score: scorePercent,
                exerciseName: exerciseName,
                coachName: coachName,
                date: data.createdAt,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 24),

            // ── Form Playback (2D / 3D) ─────────────────
            if (data.recordedFramesKey != null)
              _FormPlaybackCard(
                blobFuture: _blobFuture!,
                isDark: isDark,
              ),
            if (data.recordedFramesKey != null)
              const SizedBox(height: 24),

            // ── Segment Scores ──────────────────────────
            if (data.segmentScores.isNotEmpty) ...[
              Text(
                'Segment Scores',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...data.segmentScores.entries.map((entry) {
                final segmentName = _formatSegmentName(entry.key);
                final score = (entry.value is num)
                    ? (entry.value as num).toDouble()
                    : 0.0;
                final percent = (score * 100).toInt();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SegmentScoreRow(
                    name: segmentName,
                    score: score,
                    percent: percent,
                    isDark: isDark,
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            // ── Corrections ─────────────────────────────
            if (data.corrections.isNotEmpty) ...[
              Text(
                'Corrections',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...data.corrections.map(
                (correction) =>
                    _CorrectionCard(correction: correction, isDark: isDark),
              ),
              const SizedBox(height: 12),
            ],

            // ── Technical Details ────────────────────────
            if (data.cameraAngle != null ||
                data.durationMs != null ||
                data.totalFrames != null) ...[
              Text(
                'Technical Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    if (data.cameraAngle != null)
                      _DetailRow(
                        label: 'Camera Angle',
                        value: data.cameraAngle!,
                        isDark: isDark,
                      ),
                    if (data.durationMs != null)
                      _DetailRow(
                        label: 'Duration',
                        value:
                            '${(data.durationMs! / 1000).toStringAsFixed(1)}s',
                        isDark: isDark,
                      ),
                    if (data.totalFrames != null)
                      _DetailRow(
                        label: 'Total Frames',
                        value: '${data.totalFrames}',
                        isDark: isDark,
                      ),
                    if (data.exerciseForm?.cameraAngle != null)
                      _DetailRow(
                        label: 'Reference Angle',
                        value: data.exerciseForm!.cameraAngle!,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatSegmentName(String key) {
    return key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty
              ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}

// ──────────────────────────────────────────────────────────
// Form Playback Card — 2D skeleton / 3D Unity toggle
// ──────────────────────────────────────────────────────────

enum _PreviewMode { twoD, threeD }

class _FormPlaybackCard extends StatefulWidget {
  const _FormPlaybackCard({required this.blobFuture, required this.isDark});

  final Future<FramesBlob?> blobFuture;
  final bool isDark;

  @override
  State<_FormPlaybackCard> createState() => _FormPlaybackCardState();
}

class _FormPlaybackCardState extends State<_FormPlaybackCard> {
  _PreviewMode _mode = _PreviewMode.twoD;
  bool _unityReady = false;
  bool _poseSent = false;

  List<LandmarkFrame> _frames = [];
  String _cameraAngle = 'FRONT';

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
      UnityMessageContract.methodSetSkeletonColor,
      '#00FFFF',
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

  String get _cameraAngleLabel {
    final lower = _cameraAngle.toLowerCase();
    if (lower == 'front') return 'Front';
    if (lower == 'side_left') return 'Side (L)';
    if (lower == 'side_right') return 'Side (R)';
    if (lower == 'rear') return 'Rear';
    return _cameraAngle;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FramesBlob?>(
      future: widget.blobFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final blob = snapshot.data;
        if (blob == null) {
          return const SizedBox.shrink();
        }

        _frames = blob is CoachFramesBlob
            ? blob.landmarkFrames
            : blob is ClientFramesBlob
                ? blob.landmarkFrames
                : [];
        _cameraAngle = blob.cameraAngle;
        final hasFrames = _frames.isNotEmpty;

        if (!hasFrames) {
          return AppCard.elevated(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.videocam_off, size: 24, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'No pose data available for playback',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Form Playback',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            AppCard.elevated(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              color: widget.isDark
                                  ? Colors.cyanAccent
                                  : Colors.cyan,
                              backgroundColor: widget.isDark
                                  ? const Color(0xFF1A1A2E)
                                  : const Color(0xFF0F0F1A),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            )
                          else
                            EmbedUnity(
                              onMessageFromUnity: _onMessageFromUnity,
                            ),

                          Positioned(
                            top: 8,
                            right: 8,
                            child: _ViewModeToggle(
                              mode: _mode,
                              onToggle: _toggle3D,
                            ),
                          ),

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
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam, size: 16, color: AppColors.primaryLight),
                        const SizedBox(width: 6),
                        AppBadge(
                          label: _cameraAngleLabel,
                          variant: AppBadgeVariant.primary,
                        ),
                        const Spacer(),
                        Text(
                          '${_frames.length} frames',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: widget.isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

// ──────────────────────────────────────────────────────────
// Score Hero — large centered score display
// ──────────────────────────────────────────────────────────

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({
    required this.score,
    required this.exerciseName,
    this.coachName,
    required this.date,
    required this.isDark,
  });

  final int score;
  final String exerciseName;
  final String? coachName;
  final DateTime date;
  final bool isDark;

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String get _label {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Needs Work';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withOpacity(0.1),
              border: Border.all(color: _color, width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score%',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: _color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exerciseName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (coachName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Reference by $coachName',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDate(date),
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ──────────────────────────────────────────────────────────
// Segment Score Row — bar with percentage
// ──────────────────────────────────────────────────────────

class _SegmentScoreRow extends StatelessWidget {
  const _SegmentScoreRow({
    required this.name,
    required this.score,
    required this.percent,
    required this.isDark,
  });

  final String name;
  final double score;
  final int percent;
  final bool isDark;

  Color get _color {
    if (percent >= 80) return AppColors.success;
    if (percent >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percent%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: _color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: LinearProgressIndicator(
            value: score.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: isDark
                ? AppColors.surface2Dark
                : AppColors.surface2Light,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Correction Card
// ──────────────────────────────────────────────────────────

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.correction, required this.isDark});

  final FormCorrection correction;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        size: AppCardSize.sm,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatSegmentName(correction.segment),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    correction.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
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

  String _formatSegmentName(String key) {
    return key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty
              ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}

// ──────────────────────────────────────────────────────────
// Detail Row
// ──────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
