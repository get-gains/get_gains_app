import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/exercise_form_model.dart';

/// Displays a summary card for a recorded exercise form.
class FormCard extends StatelessWidget {
  const FormCard({
    super.key,
    required this.form,
    this.onTap,
    this.onActivate,
    this.onDelete,
  });

  final ExerciseFormModel form;
  final VoidCallback? onTap;
  final VoidCallback? onActivate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface1Dark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: form.isActive
                  ? (isDark ? AppColors.accentDark : AppColors.accentLight)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: form.isActive ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Camera angle icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: form.isActive
                            ? (isDark
                                      ? AppColors.accentDark
                                      : AppColors.accentLight)
                                  .withValues(alpha: 0.15)
                            : (isDark
                                  ? AppColors.secondaryDark
                                  : AppColors.secondaryLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.videocam_outlined,
                        size: 20,
                        color: form.isActive
                            ? (isDark
                                  ? AppColors.accentDark
                                  : AppColors.accentLight)
                            : (isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Version ${form.version}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (form.isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.accentDark
                                        : AppColors.accentLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            form.cameraAngle.displayName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.mutedForegroundLight,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Actions menu
                    if (onActivate != null || onDelete != null)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                        onSelected: (value) {
                          if (value == 'activate') onActivate?.call();
                          if (value == 'delete') onDelete?.call();
                        },
                        itemBuilder: (context) => [
                          if (!form.isActive && onActivate != null)
                            const PopupMenuItem(
                              value: 'activate',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text('Set as Active'),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: isDark
                                        ? AppColors.error
                                        : AppColors.errorLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.error
                                          : AppColors.errorLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stats row
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.timer_outlined,
                      label: '${(form.durationMs / 1000).toStringAsFixed(1)}s',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.burst_mode_outlined,
                      label: '${form.totalFrames} frames',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.speed_outlined,
                      label: '${form.frameRate} fps',
                      isDark: isDark,
                    ),
                  ],
                ),
                if (form.recordingQuality != null) ...[
                  const SizedBox(height: 6),
                  _QualityIndicator(
                    quality: form.recordingQuality!,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
      ],
    );
  }
}

class _QualityIndicator extends StatelessWidget {
  const _QualityIndicator({required this.quality, required this.isDark});

  final String quality;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (quality) {
      'good' => (
        isDark ? AppColors.success : AppColors.successLight,
        'High Quality',
      ),
      'acceptable' => (
        isDark ? AppColors.warning : AppColors.warningLight,
        'Medium Quality',
      ),
      _ => (isDark ? AppColors.error : AppColors.errorLight, 'Low Quality'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
