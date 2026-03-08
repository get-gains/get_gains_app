// lib/widgets/source_badge.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// A small pill/chip badge indicating the workout source.
///
/// Displays "Coach" with an accent color or "Solo" with a neutral color.
/// Used in session history lists to visually distinguish workout sources.
///
/// Example usage:
/// ```dart
/// SourceBadge(source: 'coach')  // Accent-colored "Coach" pill
/// SourceBadge(source: 'standalone')  // Neutral "Solo" pill
/// ```
class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source});

  /// The workout source: "standalone" or "coach".
  final String source;

  bool get _isCoach => source == 'coach';
  String get _label => _isCoach ? 'Coach' : 'Solo';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = _isCoach
        ? (isDark ? AppColors.primaryDark : AppColors.primaryLight).withValues(
            alpha: 0.15,
          )
        : (isDark ? AppColors.surface2Dark : AppColors.surface2Light);

    final textColor = _isCoach
        ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          height: 1.4,
        ),
      ),
    );
  }
}
