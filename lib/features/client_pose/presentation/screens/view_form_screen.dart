import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_pose/data/models/landmark_models.dart';
import '../../data/client_pose_repository.dart';
import '../widgets/pose_view_widget.dart';

/// View Form Screen
///
/// Displays the coach's reference form for an exercise with an animated
/// skeleton playback of the recorded landmarks. Users can watch the
/// coach's form and then navigate to compare their own.
class ViewFormScreen extends ConsumerStatefulWidget {
  const ViewFormScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  ConsumerState<ViewFormScreen> createState() => _ViewFormScreenState();
}

class _ViewFormScreenState extends ConsumerState<ViewFormScreen> {
  late Future<Map<String, dynamic>?> _formFuture;

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

  /// Parse raw JSON landmark frames into typed [LandmarkFrame] list.
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
      appBar: AppBar(title: const Text('Reference Form'), centerTitle: true),
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
          final poseConfig = data['poseConfig'] as Map<String, dynamic>?;

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise name header
                Text(
                  exerciseName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Form cards with skeleton playback
                ...forms.map((formData) {
                  final form = formData as Map<String, dynamic>;
                  final landmarkFrames = _parseLandmarkFrames(
                    form['landmarkFrames'] as List?,
                  );
                  return _FormPlaybackCard(
                    exerciseId: widget.exerciseId,
                    form: form,
                    landmarkFrames: landmarkFrames,
                    isDark: isDark,
                  );
                }),

                // Pose config info
                if (poseConfig != null) ...[
                  const SizedBox(height: 16),
                  _PoseConfigInfo(config: poseConfig, isDark: isDark),
                ],

                const SizedBox(height: 24),

                // Compare button — Unity 3D recording
                AppButton.primary(
                  label: 'Compare My Form',
                  icon: Icons.view_in_ar,
                  isFullWidth: true,
                  onPressed: () {
                    context.push(
                      AppRoutes.clientUnityRecord.replaceFirst(
                        ':id',
                        widget.exerciseId,
                      ),
                    );
                  },
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

/// Card showing form metadata + animated skeleton playback.
class _FormPlaybackCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cameraAngle = form['cameraAngle'] as String? ?? 'Unknown';
    final coachName = form['coachName'] as String? ?? 'Coach';
    final durationMs = form['durationMs'] as int? ?? 0;
    final frameRate = form['frameRate'] as int? ?? 0;
    final totalFrames = form['totalFrames'] as int? ?? 0;
    final version = form['version'] as int? ?? 1;
    final durationSec = (durationMs / 1000).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard.elevated(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton playback area
            if (landmarkFrames.isNotEmpty)
              SizedBox(
                height: 280,
                width: double.infinity,
                child: PoseViewWidget(
                  landmarkFrames: landmarkFrames,
                  mode: PoseViewMode.raw2D,
                  color: isDark ? Colors.cyanAccent : Colors.cyan,
                  backgroundColor: isDark
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFF0F0F1A),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isDark
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
                        color: isDark
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
                      if (landmarkFrames.isNotEmpty)
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                context.push(
                                  '/client/exercise/$exerciseId/form-3d-preview',
                                  extra: {
                                    'landmarkFrames': landmarkFrames,
                                    'cameraAngle': cameraAngle,
                                  },
                                );
                              },
                              icon: const Icon(Icons.view_in_ar, size: 18),
                              label: const Text('View in 3D'),
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ),
                      if (landmarkFrames.isNotEmpty) const SizedBox(width: 4),
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
                  _InfoRow(label: 'Coach', value: coachName, isDark: isDark),
                  _InfoRow(
                    label: 'Duration',
                    value: '${durationSec}s',
                    isDark: isDark,
                  ),
                  _InfoRow(
                    label: 'Frame Rate',
                    value: '$frameRate fps',
                    isDark: isDark,
                  ),
                  _InfoRow(
                    label: 'Total Frames',
                    value: '$totalFrames',
                    isDark: isDark,
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

class _PoseConfigInfo extends StatelessWidget {
  const _PoseConfigInfo({required this.config, required this.isDark});

  final Map<String, dynamic> config;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final setupInstructions = config['setupInstructions'] as String?;
    final recommendedAngles =
        (config['recommendedAngles'] as List?)?.cast<String>() ?? [];

    return AppCard.elevated(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Setup Tips',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (setupInstructions != null && setupInstructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                setupInstructions,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
            if (recommendedAngles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Recommended camera angles:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: recommendedAngles
                    .map(
                      (a) => AppBadge(
                        label: a.replaceAll('_', ' '),
                        variant: AppBadgeVariant.outline,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
