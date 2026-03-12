import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/coin_transaction_model.dart';
import '../providers/coin_balance_provider.dart';
import '../providers/coin_history_provider.dart';

/// Coin History Screen
///
/// Displays a paginated list of coin transaction history with:
/// - Current balance header
/// - Type filter chips (All / Earned / Spent)
/// - Chronological list of transactions
/// - Expandable breakdown for earning entries
/// - Infinite scroll pagination
/// - Running balance context per entry
class CoinHistoryScreen extends ConsumerStatefulWidget {
  const CoinHistoryScreen({super.key});

  @override
  ConsumerState<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends ConsumerState<CoinHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      ref.read(coinHistoryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyState = ref.watch(coinHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Coin History',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(coinBalanceProvider);
            await ref.read(coinHistoryProvider.notifier).refresh();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Balance header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _BalanceHeader(isDark: isDark),
                ),
              ),

              // Filter chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _FilterChips(isDark: isDark),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Transaction list
              switch (historyState) {
                CoinHistoryInitial() ||
                CoinHistoryLoading() => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                CoinHistoryLoaded(:final transactions, :final isLoadingMore) =>
                  transactions.isEmpty
                      ? SliverFillRemaining(
                          child: AppEmptyState.compact(
                            icon: Icons.receipt_long_outlined,
                            title: 'No Transactions',
                            description:
                                'Complete workouts to start earning coins!',
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index == transactions.length) {
                              return isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }
                            return _TransactionTile(
                              transaction: transactions[index],
                              isDark: isDark,
                            );
                          }, childCount: transactions.length + 1),
                        ),
                CoinHistoryError(:final error) => SliverFillRemaining(
                  child: AppEmptyState.compact(
                    icon: Icons.error_outline,
                    title: 'Failed to Load',
                    description: error.message,
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

// ── Balance Header ──────────────────────────────────────────

class _BalanceHeader extends ConsumerWidget {
  const _BalanceHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceState = ref.watch(coinBalanceProvider);
    final coinColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    final (balance, earned, spent) = switch (balanceState) {
      CoinBalanceLoaded(:final balance) => (
        balance.currentBalance,
        balance.lifetimeEarned,
        balance.lifetimeSpent,
      ),
      _ => (0, 0, 0),
    };

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.monetization_on_rounded, color: coinColor, size: 36),
          const SizedBox(height: 8),
          Text(
            _formatNumber(balance),
            style: AppTextStyles.numericDisplayLarge.copyWith(
              color: coinColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current Balance',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Lifetime Earned',
                  value: '+${_formatNumber(earned)}',
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.1,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Lifetime Spent',
                  value: '-${_formatNumber(spent)}',
                  color: isDark ? AppColors.error : AppColors.destructiveLight,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.numericBody.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Filter Chips ────────────────────────────────────────────

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(coinHistoryProvider);
    final currentFilter = switch (historyState) {
      CoinHistoryLoaded(:final filterType) => filterType,
      _ => null,
    };

    return Row(
      children: [
        _FilterChip(
          label: 'All',
          selected: currentFilter == null,
          isDark: isDark,
          onSelected: () =>
              ref.read(coinHistoryProvider.notifier).setFilter(null),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Earned',
          selected: currentFilter == 'SESSION_REWARD',
          isDark: isDark,
          onSelected: () => ref
              .read(coinHistoryProvider.notifier)
              .setFilter('SESSION_REWARD'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Spent',
          selected: currentFilter == 'SHOP_PURCHASE',
          isDark: isDark,
          onSelected: () =>
              ref.read(coinHistoryProvider.notifier).setFilter('SHOP_PURCHASE'),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.15)
              : (isDark ? AppColors.surface1Dark : AppColors.surface1Light),
          borderRadius: AppTheme.borderRadiusSm,
          border: Border.all(
            color: selected
                ? primaryColor
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: selected
                ? primaryColor
                : isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Transaction Tile ────────────────────────────────────────

class _TransactionTile extends StatefulWidget {
  const _TransactionTile({required this.transaction, required this.isDark});

  final CoinTransactionModel transaction;
  final bool isDark;

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final isDark = widget.isDark;
    final isEarning = tx.type == 'SESSION_REWARD';
    final amountColor = isEarning
        ? AppColors.success
        : (isDark ? AppColors.error : AppColors.destructiveLight);
    final amountPrefix = isEarning ? '+' : '';
    final dateFormat = DateFormat('MMM d, y · h:mm a');
    final hasBreakdown = isEarning && tx.setCoins != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: hasBreakdown
              ? () => setState(() => _expanded = !_expanded)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.12),
                        borderRadius: AppTheme.borderRadiusSm,
                      ),
                      child: Icon(
                        isEarning
                            ? Icons.fitness_center_rounded
                            : Icons.shopping_bag_outlined,
                        color: amountColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEarning ? 'Workout Reward' : 'Shop Purchase',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTextStyles.fontFamilySans,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormat.format(tx.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Amount & balance
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$amountPrefix${tx.amount}',
                          style: AppTextStyles.numericBody.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bal: ${_formatNumber(tx.balanceAfter)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),

                    if (hasBreakdown) ...[
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          size: 20,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ],
                ),

                // Expandable breakdown
                if (_expanded && hasBreakdown) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.08,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BreakdownRow(
                    label: 'Set coins (${tx.setsCompleted ?? 0} sets × 3)',
                    value: '${tx.setCoins ?? 0}',
                    isDark: isDark,
                  ),
                  if (tx.accuracyMultiplier != null &&
                      tx.accuracyMultiplier != 1.0)
                    _BreakdownRow(
                      label:
                          'Accuracy multiplier (${(tx.avgAccuracy ?? 0) * 100 ~/ 1}%)',
                      value: '×${tx.accuracyMultiplier!.toStringAsFixed(1)}',
                      isDark: isDark,
                    ),
                  _BreakdownRow(
                    label: 'Completion bonus',
                    value: '+${tx.completionBonus ?? 0}',
                    isDark: isDark,
                  ),
                  if ((tx.durationBonus ?? 0) > 0)
                    _BreakdownRow(
                      label:
                          'Duration bonus (${tx.sessionDurationMin ?? 0} min)',
                      value: '+${tx.durationBonus}',
                      isDark: isDark,
                    ),
                  if ((tx.streakBonus ?? 0) > 0)
                    _BreakdownRow(
                      label: 'Streak bonus (${tx.streakValue ?? 0} days)',
                      value: '+${tx.streakBonus}',
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

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontFamily: AppTextStyles.fontFamilySans,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.numericBody.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────

String _formatNumber(int value) {
  if (value < 1000) return value.toString();
  final str = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
  }
  return buffer.toString();
}
