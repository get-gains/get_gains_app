import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/leaderboard_entry_model.dart';

/// Leaderboard Row Widget
///
/// Displays a single leaderboard entry with:
/// - Rank badge (gold/silver/bronze for top 3, plain for others)
/// - Display name
/// - Stats columns (sessions, streak, accuracy)
/// - Current-user highlight styling
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({super.key, required this.entry, this.onTap});

  final LeaderboardEntryModel entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: entry.isCurrentUser
              ? (isDark
                    ? AppColors.primaryDark.withValues(alpha: 0.15)
                    : AppColors.primaryLight.withValues(alpha: 0.1))
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: AppTheme.borderRadiusMd,
          border: entry.isCurrentUser
              ? Border.all(
                  color: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.5)
                      : AppColors.primaryLight.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            // ── Rank Badge ──
            _RankBadge(rank: entry.rank, isDark: isDark),
            const SizedBox(width: 12),

            // ── Display Name + Score ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.displayName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: entry.isCurrentUser
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.isCurrentUser)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryDark.withValues(alpha: 0.2)
                                : AppColors.primaryLight.withValues(
                                    alpha: 0.15,
                                  ),
                            borderRadius: AppTheme.borderRadiusSm,
                          ),
                          child: Text(
                            'You',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.fitness_center_rounded,
                        value: '${entry.sessionsCompleted}',
                        tooltip: 'Sessions',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.local_fire_department_rounded,
                        value: '${entry.streakDays}d',
                        tooltip: 'Streak',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.track_changes_rounded,
                        value: '${(entry.avgAccuracy * 100).round()}%',
                        tooltip: 'Accuracy',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Composite Score ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.compositeScore.toStringAsFixed(1),
                  style: AppTextStyles.numericBody.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                ),
                Text(
                  'pts',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Rank number badge with special styling for top 3
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.isDark});

  final int rank;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, icon) = _rankStyle();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: icon != null
          ? Icon(icon, color: textColor, size: 20)
          : Center(
              child: Text(
                '$rank',
                style: AppTextStyles.numericBody.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
    );
  }

  (Color, Color, IconData?) _rankStyle() {
    return switch (rank) {
      1 => (
        const Color(0xFFFFD700).withValues(alpha: 0.2),
        const Color(0xFFFFD700),
        Icons.emoji_events_rounded,
      ),
      2 => (
        const Color(0xFFC0C0C0).withValues(alpha: 0.2),
        const Color(0xFFA0A0A0),
        Icons.emoji_events_rounded,
      ),
      3 => (
        const Color(0xFFCD7F32).withValues(alpha: 0.2),
        const Color(0xFFCD7F32),
        Icons.emoji_events_rounded,
      ),
      _ => (
        isDark ? AppColors.surface1Dark : AppColors.surface1Light,
        isDark ? AppColors.mutedDark : AppColors.mutedLight,
        null,
      ),
    };
  }
}

/// Small stat chip showing an icon + value
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.tooltip,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String tooltip;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
