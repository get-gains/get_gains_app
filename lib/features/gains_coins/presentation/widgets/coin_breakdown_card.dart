import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/coin_estimate_model.dart';

/// Coin Breakdown Card
///
/// Displays a detailed breakdown of a coin reward:
/// - Set coins (with accuracy multiplier label)
/// - Completion bonus
/// - Duration bonus
/// - Streak bonus
/// - Total
///
/// Works with both [CoinEstimateModel] (local estimate) and server-confirmed
/// data by accepting structured parameters.
class CoinBreakdownCard extends StatelessWidget {
  const CoinBreakdownCard({
    super.key,
    required this.totalCoins,
    required this.setCoins,
    required this.accuracyMultiplier,
    required this.accuracyLabel,
    required this.completionBonus,
    required this.durationBonus,
    required this.streakBonus,
    required this.streakValue,
    required this.setsCompleted,
    required this.sessionDurationMin,
    this.isEstimate = false,
  });

  /// Create from a [CoinEstimateModel].
  factory CoinBreakdownCard.fromEstimate(CoinEstimateModel estimate) {
    return CoinBreakdownCard(
      totalCoins: estimate.estimatedTotal,
      setCoins: estimate.setCoins,
      accuracyMultiplier: estimate.accuracyMultiplier,
      accuracyLabel: estimate.accuracyLabel,
      completionBonus: estimate.completionBonus,
      durationBonus: estimate.durationBonus,
      streakBonus: estimate.streakBonus,
      streakValue: estimate.streakValue,
      setsCompleted: estimate.setsCompleted,
      sessionDurationMin: estimate.sessionDurationMin,
      isEstimate: estimate.isEstimate,
    );
  }

  final int totalCoins;
  final int setCoins;
  final double accuracyMultiplier;
  final String accuracyLabel;
  final int completionBonus;
  final int durationBonus;
  final int streakBonus;
  final int streakValue;
  final int setsCompleted;
  final int sessionDurationMin;
  final bool isEstimate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coinColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppTheme.borderRadiusLg,
        border: Border.all(color: coinColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: coinColor, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coins Earned',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                ),
              ),
              if (isEstimate)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: AppTheme.borderRadiusSm,
                  ),
                  child: Text(
                    'Estimate',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing4),

          // ── Total ──
          Center(
            child: Text(
              '+$totalCoins',
              style: AppTextStyles.numericDisplayLarge.copyWith(
                color: coinColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing4),
          Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: AppTheme.spacing3),

          // ── Breakdown rows ──
          _BreakdownRow(
            icon: Icons.fitness_center_rounded,
            label: 'Set Coins ($setsCompleted sets × 3)',
            value: setCoins,
            isDark: isDark,
          ),
          const SizedBox(height: AppTheme.spacing2),
          _BreakdownRow(
            icon: Icons.speed_rounded,
            label: 'Accuracy ($accuracyLabel × ${accuracyMultiplier}x)',
            value: null, // multiplier already factored into setCoins
            suffix: '${accuracyMultiplier}x',
            isDark: isDark,
            isMultiplier: true,
          ),
          const SizedBox(height: AppTheme.spacing2),
          _BreakdownRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Completion Bonus',
            value: completionBonus,
            isDark: isDark,
          ),
          if (durationBonus > 0) ...[
            const SizedBox(height: AppTheme.spacing2),
            _BreakdownRow(
              icon: Icons.timer_rounded,
              label: 'Duration Bonus (${sessionDurationMin}min)',
              value: durationBonus,
              isDark: isDark,
            ),
          ],
          if (streakBonus > 0) ...[
            const SizedBox(height: AppTheme.spacing2),
            _BreakdownRow(
              icon: Icons.local_fire_department_rounded,
              label: 'Streak Bonus (${streakValue}-day streak)',
              value: streakBonus,
              isDark: isDark,
              valueColor: AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.icon,
    required this.label,
    required this.isDark,
    this.value,
    this.suffix,
    this.isMultiplier = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final int? value;
  final String? suffix;
  final bool isDark;
  final bool isMultiplier;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final foregroundColor = isDark
        ? AppColors.foregroundDark
        : AppColors.foregroundLight;

    return Row(
      children: [
        Icon(icon, color: mutedColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
          ),
        ),
        if (isMultiplier && suffix != null)
          Text(
            suffix!,
            style: AppTextStyles.numericBody.copyWith(
              color: valueColor ?? foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          )
        else if (value != null)
          Text(
            '+$value',
            style: AppTextStyles.numericBody.copyWith(
              color: valueColor ?? foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
