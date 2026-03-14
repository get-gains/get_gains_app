import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/coin_balance_provider.dart';

/// Reusable Coin Balance Widget
///
/// Displays the user's current coin balance with a coin icon.
/// Shows a zero-state prompt when balance is 0 (encouraging first workout).
/// Tappable — navigates to coin history on tap.
class CoinBalanceWidget extends ConsumerWidget {
  const CoinBalanceWidget({super.key, this.onTap, this.compact = false});

  /// Callback when the widget is tapped (e.g. navigate to history).
  final VoidCallback? onTap;

  /// When true, renders a smaller inline variant (e.g. for app bar).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balanceState = ref.watch(coinBalanceProvider);

    return switch (balanceState) {
      CoinBalanceLoading() => _buildLoading(isDark),
      CoinBalanceLoaded(:final balance) => _buildBalance(
        context,
        balance.currentBalance,
        isDark,
      ),
      CoinBalanceError() => _buildBalance(context, 0, isDark),
      _ => _buildBalance(context, 0, isDark),
    };
  }

  Widget _buildLoading(bool isDark) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
        borderRadius: AppTheme.borderRadiusMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '...',
            style: AppTextStyles.numericBody.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalance(BuildContext context, int balance, bool isDark) {
    final coinColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded, color: coinColor, size: 20),
            const SizedBox(width: 4),
            Text(
              _formatBalance(balance),
              style: AppTextStyles.numericBody.copyWith(
                color: coinColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
          borderRadius: AppTheme.borderRadiusMd,
          border: Border.all(color: coinColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded, color: coinColor, size: 24),
            const SizedBox(width: 8),
            balance == 0
                ? Text(
                    'Complete a workout to earn coins!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  )
                : Text(
                    _formatBalance(balance),
                    style: AppTextStyles.numericDisplaySmall.copyWith(
                      color: coinColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Format balance with thousands separator for readability.
  String _formatBalance(int balance) {
    if (balance < 1000) return balance.toString();
    final str = balance.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
