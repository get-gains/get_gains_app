// lib/features/home/presentation/widgets/today_hero_block.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/access_gated.dart';
import '../../../../core/access/access_guard.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../subscription/subscription.dart';
import '../../../workout/data/models/models.dart';
import '../providers/home_providers.dart';
import 'workout_summary_card.dart';

/// Hero block displaying today's workout status.
///
/// Covers all 5 [HomeStatus] states:
/// - [HomeStatus.hasRoutine] — workout card with Start CTA.
/// - [HomeStatus.restDay] — rest day illustration.
/// - [HomeStatus.waitingForProgram] — coach building program status.
/// - [HomeStatus.noSubscription] — subscription upgrade CTA.
/// - [HomeStatus.noCoach] — find-a-coach CTA.
///
/// @param todayKey [GlobalKey] forwarded to the card for tour anchoring.
/// @param isCoach When true, hides the noCoach CTA (coach is never their own client).
class TodayHeroBlock extends ConsumerWidget {
  const TodayHeroBlock({super.key, this.todayKey, required this.isCoach});

  final GlobalKey? todayKey;
  final bool isCoach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeStatusAsync = ref.watch(homeStatusProvider);
    final subscriptionTier = ref.watch(subscriptionTierProvider);

    Widget content = homeStatusAsync.when(
      data: (status) {
        switch (status) {
          case HomeStatus.noCoach:
            if (isCoach) return const SizedBox.shrink();
            return _FindCoachCta(isDark: isDark);

          case HomeStatus.noSubscription:
            return AccessGated(
              requires: const AccessRequirement(
                requireTier: SubscriptionTier.premium,
              ),
              feature: SubscriptionFeature.coachWorkout,
              compact: false,
              child: const SizedBox.shrink(),
            );

          case HomeStatus.waitingForProgram:
            return _WaitingForProgramCard(isDark: isDark);

          case HomeStatus.restDay:
            return _buildTodayCard(context, ref, isDark, subscriptionTier);

          case HomeStatus.hasRoutine:
            return _buildTodayCard(context, ref, isDark, subscriptionTier);
        }
      },
      loading: () => _buildSkeleton(isDark),
      error: (_, __) => const SizedBox.shrink(),
    );

    if (todayKey != null) {
      content = KeyedSubtree(key: todayKey, child: content);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: content,
    );
  }

  Widget _buildTodayCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    SubscriptionTier subscriptionTier,
  ) {
    final todayAsync = ref.watch(activeTodayProvider);

    return todayAsync.when(
      data: (today) {
        if (today.isRestDay) {
          return WorkoutSummaryCard(
            routineName: 'Rest Day',
            description:
                'No routine scheduled today. Recovery is part of the process!',
            exerciseCount: 0,
            estimatedMinutes: 0,
            isPlaceholder: true,
            onStartPressed: () {
              if (isCoach || subscriptionTier != SubscriptionTier.free) {
                context.push(AppRoutes.myProgram);
              } else {
                context.push(AppRoutes.selfPrograms);
              }
            },
          );
        }
        if (today.hasRoutine) {
          final details = today.today!;
          return WorkoutSummaryCard(
            routineName: today.displayName,
            description:
                '${details.programName} · ${_formatDay(details.dayOfWeek)}',
            exerciseCount: today.exerciseCount,
            estimatedMinutes: today.estimatedMinutes,
            isPlaceholder: false,
            completedToday: today.completedToday,
            onStartPressed: today.completedToday
                ? null
                : () {
                    if (isCoach || subscriptionTier != SubscriptionTier.free) {
                      context.push(AppRoutes.myProgram);
                    } else {
                      context.push(AppRoutes.selfPrograms);
                    }
                  },
          );
        }
        return _StartProgramCta(
          isDark: isDark,
          isFreeTier: subscriptionTier == SubscriptionTier.free,
        );
      },
      loading: () => _buildSkeleton(isDark),
      error: (_, __) => _StartProgramCta(
        isDark: isDark,
        isFreeTier: subscriptionTier == SubscriptionTier.free,
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  String _formatDay(String dayOfWeek) {
    const labels = {
      'MONDAY': 'Monday',
      'TUESDAY': 'Tuesday',
      'WEDNESDAY': 'Wednesday',
      'THURSDAY': 'Thursday',
      'FRIDAY': 'Friday',
      'SATURDAY': 'Saturday',
      'SUNDAY': 'Sunday',
    };
    return labels[dayOfWeek.trim().toUpperCase()] ?? dayOfWeek;
  }
}

class _StartProgramCta extends StatelessWidget {
  const _StartProgramCta({required this.isDark, required this.isFreeTier});

  final bool isDark;
  final bool isFreeTier;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Start a Program',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isFreeTier
                  ? 'Create a standalone workout program or find a coach to get personalized training.'
                  : 'Find a coach to get personalized training.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            if (isFreeTier) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  label: 'Build My Program',
                  icon: Icons.build,
                  onPressed: () => context.push(AppRoutes.selfPrograms),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FindCoachCta extends StatelessWidget {
  const _FindCoachCta({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_search,
                    color: AppColors.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Find a Coach',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Get personalized workout programs from a certified coach.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Discover Coaches',
                icon: Icons.arrow_forward,
                onPressed: () => context.push(AppRoutes.discoverCoaches),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingForProgramCard extends StatelessWidget {
  const _WaitingForProgramCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.hourglass_top,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waiting for Program',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your coach hasn't assigned a program yet. Check back soon!",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
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
}
