import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/widgets.dart';
import '../../data/leaderboard_repository.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_row.dart';

/// Leaderboard Screen
///
/// Displays a per-coach class leaderboard with:
/// - Coach picker dropdown/tabs
/// - Ranked list of entries with composite scores
/// - Current user rank highlight
/// - "Last updated" timestamp
/// - No-subscription prompt for non-subscribers
/// - Offline cache display with stale data indicator
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaderboardState = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leaderboard',
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
            await ref.read(leaderboardProvider.notifier).refresh();
          },
          child: switch (leaderboardState) {
            LeaderboardInitial() || LeaderboardLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            LeaderboardLoaded() => _LeaderboardContent(
              state: leaderboardState,
              isDark: isDark,
            ),
            LeaderboardError(:final error) => ListView(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: AppEmptyState.compact(
                    icon: Icons.leaderboard_outlined,
                    title: 'Failed to Load Leaderboard',
                    description: error.message,
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

// ── Main Content ──

class _LeaderboardContent extends ConsumerWidget {
  const _LeaderboardContent({required this.state, required this.isDark});

  final LeaderboardLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No subscriptions — show prompt
    if (state.hasNoSubscriptions) {
      return _NoSubscriptionPrompt(isDark: isDark);
    }

    return CustomScrollView(
      slivers: [
        // ── Coach Picker ──
        if (state.coaches.length > 1)
          SliverToBoxAdapter(
            child: _CoachPicker(
              coaches: state.coaches,
              selectedCoachId: state.selectedCoachId,
              isDark: isDark,
              onCoachSelected: (coachId) {
                ref.read(leaderboardProvider.notifier).selectCoach(coachId);
              },
            ),
          ),

        // ── Header Info ──
        SliverToBoxAdapter(
          child: _LeaderboardHeader(state: state, isDark: isDark),
        ),

        // ── Leaderboard Entries ──
        if (state.entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: AppEmptyState.compact(
                icon: Icons.leaderboard_outlined,
                title: 'No Rankings Yet',
                description: 'Complete workouts to appear on the leaderboard!',
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = state.entries[index];
              return LeaderboardRow(entry: entry);
            }, childCount: state.entries.length),
          ),

        // ── Bottom Padding ──
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ── Coach Picker ──

class _CoachPicker extends StatelessWidget {
  const _CoachPicker({
    required this.coaches,
    required this.selectedCoachId,
    required this.isDark,
    required this.onCoachSelected,
  });

  final List<LeaderboardCoach> coaches;
  final String? selectedCoachId;
  final bool isDark;
  final ValueChanged<String> onCoachSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: coaches.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final coach = coaches[index];
            final isSelected = coach.coachId == selectedCoachId;

            return FilterChip(
              label: Text(coach.coachName),
              selected: isSelected,
              onSelected: (_) => onCoachSelected(coach.coachId),
              backgroundColor: isDark
                  ? AppColors.surface1Dark
                  : AppColors.surface1Light,
              selectedColor: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.2)
                  : AppColors.primaryLight.withValues(alpha: 0.15),
              checkmarkColor: isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight,
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : (isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusMd,
              ),
              side: isSelected
                  ? BorderSide(
                      color: isDark
                          ? AppColors.primaryDark.withValues(alpha: 0.5)
                          : AppColors.primaryLight.withValues(alpha: 0.5),
                    )
                  : BorderSide.none,
            );
          },
        ),
      ),
    );
  }
}

// ── Leaderboard Header ──

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader({required this.state, required this.isDark});

  final LeaderboardLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coach name heading (when single coach or for context)
          if (state.coaches.length <= 1 && state.coachName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.coachName,
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
            ),

          // Stats row
          Row(
            children: [
              // Total clients
              _HeaderStat(
                icon: Icons.people_rounded,
                value: '${state.totalClients}',
                label: 'Athletes',
                isDark: isDark,
              ),
              const SizedBox(width: 16),

              // Your rank
              if (state.currentUserRank != null)
                _HeaderStat(
                  icon: Icons.emoji_events_rounded,
                  value: '#${state.currentUserRank}',
                  label: 'Your Rank',
                  isDark: isDark,
                  highlight: true,
                ),

              const Spacer(),

              // Last updated
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.lastUpdatedFormatted,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.mutedDark
                          : AppColors.mutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (state.isRefreshing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                backgroundColor: isDark
                    ? AppColors.surface1Dark
                    : AppColors.surface1Light,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ),

          const Divider(height: 24),
        ],
      ),
    );
  }
}

// ── Header Stat Chip ──

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
    this.highlight = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isDark;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
        : (isDark ? AppColors.foregroundDark : AppColors.foregroundLight);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.numericBody.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── No Subscription Prompt ──

class _NoSubscriptionPrompt extends StatelessWidget {
  const _NoSubscriptionPrompt({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.leaderboard_outlined,
          size: 64,
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        ),
        const SizedBox(height: 16),
        Text(
          'Class Leaderboards',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Subscribe to a coach to compete with other athletes '
          'in class leaderboards. Complete workouts to earn your rank!',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Find a Coach'),
            style: FilledButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight,
              foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusMd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
