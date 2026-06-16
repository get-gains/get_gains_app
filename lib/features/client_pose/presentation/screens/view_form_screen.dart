import 'dart:convert';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../services/database/app_database.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_pose/data/models/landmark_models.dart';
import '../../../form_library/presentation/widgets/ad_gate_dialog.dart';
import '../../../form_library/presentation/widgets/rating_bottom_sheet.dart';
import '../../../form_library/data/models/library_exercise_model.dart';
import '../../../guidance/guidance.dart';
import '../../../unity/data/unity_cosmetics_loader.dart';
import '../../../unity/data/unity_message_contract.dart';
import '../../data/client_pose_repository.dart';
import '../widgets/pose_view_widget.dart';

/// View Form Screen
///
/// Displays the coach's reference form for an exercise with an animated
/// skeleton playback of the recorded landmarks. Users can watch the
/// coach's form and then navigate to compare their own.
class ViewFormScreen extends ConsumerStatefulWidget {
  const ViewFormScreen({super.key, required this.exerciseId, this.isFromLibrary = false});

  final String exerciseId;
  final bool isFromLibrary;

  @override
  ConsumerState<ViewFormScreen> createState() => _ViewFormScreenState();
}

class _ViewFormScreenState extends ConsumerState<ViewFormScreen> {
  late Future<Map<String, dynamic>?> _formFuture;
  bool _overlayDismissed = false;
  bool _hasForms = false;
  String _exerciseName = 'Exercise';
  String _coachName = '';

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  void _loadForm() {
    final repo = ref.read(clientPoseRepositoryProvider);
    _formFuture = repo
        .downloadExerciseForm(widget.exerciseId)
        .then((result) => result.valueOrNull);
  }

  List<LandmarkFrame> _parseLandmarkFrames(List<dynamic>? rawFrames) {
    if (rawFrames == null || rawFrames.isEmpty) return [];
    try {
      return rawFrames.map((f) {
        final frameMap = f as Map<String, dynamic>;
        return LandmarkFrame.fromJson(frameMap);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Reference Form'),
        centerTitle: true,
        actions: [InfoIconButton(content: kViewFormHelp)],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _formFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'No Form Available',
              description:
                  'No active reference form found for this exercise.\n'
                  'Ask your coach to record and activate a form.',
              actionLabel: 'Go Back',
              onAction: () => context.pop(),
            );
          }

          final exerciseName = data['exerciseName'] as String? ?? 'Exercise';
          final forms = data['forms'] as List? ?? [];
          final coachName = data['coachName'] as String? ?? '';

          if (!mounted) return const SizedBox.shrink();
          _hasForms = forms.isNotEmpty;
          _exerciseName = exerciseName;
          _coachName = coachName;

          if (forms.isEmpty) {
            return AppEmptyState(
              icon: Icons.videocam_off,
              title: 'No Reference Form',
              description:
                  'No active form has been recorded for "$exerciseName".\n'
                  'Ask your coach to record and activate a form first.',
              actionLabel: 'Go Back',
              onAction: () => context.pop(),
            );
          }

          final showOverlay =
              !_overlayDismissed &&
              !ref
                  .read(guidanceRepositoryProvider)
                  .isCompleted(GuidanceRepository.kViewForm);

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...forms.map((formData) {
                      final form = formData as Map<String, dynamic>;
                      final formId = form['id'] as String?;
                      final formsBlobs =
                          data['formsBlobs'] as Map<String, dynamic>? ?? {};

                      // Try blob first, fall back to inline landmarkFrames
                      List<LandmarkFrame> landmarkFrames = [];
                      if (formId != null && formsBlobs.containsKey(formId)) {
                        final blobJson =
                            formsBlobs[formId] as Map<String, dynamic>;
                        final blob = ref
                            .read(clientPoseRepositoryProvider)
                            .parseCoachBlob(blobJson);
                        landmarkFrames = blob?.landmarkFrames ?? [];
                      } else {
                        landmarkFrames = _parseLandmarkFrames(
                          form['landmarkFrames'] as List?,
                        );
                      }
                      return _FormPlaybackCard(
                        exerciseId: widget.exerciseId,
                        form: form,
                        landmarkFrames: landmarkFrames,
                        isDark: isDark,
                      );
                    }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              if (showOverlay)
                _ViewFormGuidanceOverlay(
                  isDark: isDark,
                  onDismiss: () {
                    setState(() => _overlayDismissed = true);
                    ref
                        .read(guidanceRepositoryProvider)
                        .markCompleted(GuidanceRepository.kViewForm);
                  },
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: widget.isFromLibrary && _hasForms
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _onComparePressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text(
                    'Record & Compare',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _onComparePressed() async {
    if (!mounted) return;

    final adDismissed = await showAdGateDialog(context);
    if (adDismissed != true) return;

    if (!mounted) return;

    final result = await context.push<bool>(
      AppRoutes.clientCompareForm.replaceAll(':id', widget.exerciseId),
    );

    if (!mounted) return;

    if (result == true) {
      await showRatingBottomSheet(
        context: context,
        ref: ref,
        exercise: LibraryExerciseModel(
          id: widget.exerciseId,
          name: _exerciseName,
          description: '',
          coachName: _coachName,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}

/// First-time instructional overlay for the view form screen.
class _ViewFormGuidanceOverlay extends StatelessWidget {
  const _ViewFormGuidanceOverlay({
    required this.isDark,
    required this.onDismiss,
  });

  final bool isDark;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard.elevated(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 48,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Understanding the Reference Form',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _BulletPoint(
                      isDark: isDark,
                      text:
                          "This is your coach's ideal form for the exercise. "
                          'Study the movement pattern before recording.',
                    ),
                    const SizedBox(height: 8),
                    _BulletPoint(
                      isDark: isDark,
                      text:
                          'Toggle between 2D skeleton and 3D avatar views '
                          'for different perspectives.',
                    ),
                    const SizedBox(height: 8),
                    _BulletPoint(
                      isDark: isDark,
                      text:
                          "When recording, follow the same direction — don't "
                          'mirror the movement.',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onDismiss,
                        child: const Text('Got it'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.isDark, required this.text});

  final bool isDark;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Icon(
            Icons.circle,
            size: 6,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

enum _PreviewMode { twoD, threeD }

/// Card showing form metadata + animated skeleton or inline 3D Unity preview.
class _FormPlaybackCard extends StatefulWidget {
  const _FormPlaybackCard({
    required this.exerciseId,
    required this.form,
    required this.landmarkFrames,
    required this.isDark,
  });

  final String exerciseId;
  final Map<String, dynamic> form;
  final List<LandmarkFrame> landmarkFrames;
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

  String get _cameraAngle => widget.form['cameraAngle'] as String? ?? 'FRONT';

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
      // Load equipped cosmetics onto the character
      final container = ProviderScope.containerOf(context);
      UnityCosmeticsLoader.loadEquippedCosmetics(
        container.read(appDatabaseProvider),
      );
      _sendPoseToUnity();
    }
  }

  void _sendPoseToUnity() {
    if (_poseSent || widget.landmarkFrames.isEmpty) return;
    _poseSent = true;

    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetCameraViewMode,
      'WORKOUT',
    );

    final payload = jsonEncode({
      'frames': widget.landmarkFrames.map((f) => f.toJson()).toList(),
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

  void _openFullscreen() {
    context.push(
      '/client/exercise/${widget.exerciseId}/form-3d-preview',
      extra: {
        'landmarkFrames': widget.landmarkFrames,
        'cameraAngle': _cameraAngle,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraAngle = _cameraAngle;
    final coachName = widget.form['coachName'] as String? ?? 'Coach';
    final durationMs = widget.form['durationMs'] as int? ?? 0;
    final frameRate = widget.form['frameRate'] as int? ?? 0;
    final totalFrames = widget.form['totalFrames'] as int? ?? 0;
    final version = widget.form['version'] as int? ?? 1;
    final durationSec = (durationMs / 1000).toStringAsFixed(1);
    final hasFrames = widget.landmarkFrames.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard.elevated(
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
                          landmarkFrames: widget.landmarkFrames,
                          mode: PoseViewMode.raw2D,
                          mirrorX: true,
                          color: widget.isDark
                              ? Colors.cyanAccent
                              : Colors.cyan,
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
                                  Text(
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
                        child: Text(
                          'Version $version',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AppBadge(
                            label: _formatAngle(cameraAngle),
                            variant: AppBadgeVariant.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Coach',
                    value: coachName,
                    isDark: widget.isDark,
                  ),
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
      ),
    );
  }

  String _formatAngle(String angle) {
    return angle
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
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
