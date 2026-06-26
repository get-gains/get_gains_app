import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/exercise_form_model.dart';

/// Displays a summary card for a recorded exercise form.
class FormCard extends StatelessWidget {
  const FormCard({
    super.key,
    required this.form,
    this.onTap,
    this.onDelete,
    this.onEditAngle,
  });

  final ExerciseFormModel form;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final void Function(CameraAngle selectedAngle)? onEditAngle;

  static void _showEditAngleDialog(
    BuildContext context, {
    required CameraAngle current,
    required void Function(CameraAngle) onSelected,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SimpleDialog(
          title: const Text('Edit Camera Angle'),
          children: CameraAngle.values.map((angle) {
            final isSelected = angle == current;
            return ListTile(
              title: Text(
                angle.displayName,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      size: 20,
                    )
                  : null,
              onTap: () {
                if (!isSelected) {
                  Navigator.pop(context);
                  onSelected(angle);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

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
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Camera angle icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.secondaryDark
                        : AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.videocam_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.cameraAngle.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (form.createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(form.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Edit / Delete actions
                if (onDelete != null || onEditAngle != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') onDelete?.call();
                      if (value == 'editAngle') {
                        _showEditAngleDialog(
                          context,
                          current: form.cameraAngle,
                          onSelected: (angle) => onEditAngle?.call(angle),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEditAngle != null)
                        PopupMenuItem(
                          value: 'editAngle',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                              const SizedBox(width: 8),
                              const Text('Edit Angle'),
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
          ),
        ),
      ),
    );
  }
}
