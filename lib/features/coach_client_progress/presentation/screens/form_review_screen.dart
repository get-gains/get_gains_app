// lib/features/coach_client_progress/presentation/screens/form_review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';

/// Form Review Screen
///
/// Displays the full detail of a single form comparison result:
/// - Overall score badge
/// - Exercise info & coach info
/// - Segment-level scores bar chart
/// - Corrections list with segment labels
/// - Technical metadata (camera angle, duration, frames)
///
/// Receives the `ClientFormResult` via `GoRoute.extra` to avoid
/// an extra network call. Falls back to a placeholder if data missing.
class FormReviewScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (result == null) {
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

    final data = result!;
    final scorePercent = (data.overallScore * 100).toInt();
    final exerciseName =
        data.exerciseForm?.exercise?.name ?? 'Unknown Exercise';
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
    // Convert camelCase or snake_case to Title Case
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
          // Score ring
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
