// lib/features/home/presentation/widgets/recent_activity_card.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../../workout/data/models/models.dart';

/// Card displaying a single recent workout session on the home screen.
class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key, required this.session});

  final WorkoutSessionSummary session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = _formatRelativeDate(session.startedAt);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    (session.isCompleted
                            ? (isDark
                                  ? AppColors.accentDark
                                  : const Color(0xFF22C55E))
                            : (isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight))
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                session.isCompleted
                    ? Icons.check_circle_outline
                    : Icons.timer_outlined,
                color: session.isCompleted
                    ? (isDark ? AppColors.accentDark : const Color(0xFF22C55E))
                    : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr · ${session.totalSets} sets',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              session.durationDisplay,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
