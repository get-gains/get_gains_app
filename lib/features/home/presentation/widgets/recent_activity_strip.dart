// lib/features/home/presentation/widgets/recent_activity_strip.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../providers/home_providers.dart';
import 'recent_activity_card.dart';

/// Vertical list of up to 3 recent workout sessions.
///
/// Shows a "See All" action that navigates to [AppRoutes.workoutHistory].
///
/// @param activityKey [GlobalKey] forwarded for tour anchoring.
class RecentActivityStrip extends ConsumerWidget {
  const RecentActivityStrip({super.key, this.activityKey});

  final GlobalKey? activityKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentActivityProvider);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.workoutHistory),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        recentAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppEmptyState.compact(
                  icon: Icons.history,
                  title: 'No Recent Workouts',
                  description: 'Your completed workouts will appear here.',
                ),
              );
            }
            final display = sessions.take(3).toList();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: display.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => RecentActivityCard(session: display[i]),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppEmptyState.compact(
              icon: Icons.history,
              title: 'Loading...',
              description: '',
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppEmptyState.compact(
              icon: Icons.history,
              title: 'No Recent Workouts',
              description: 'Your completed workouts will appear here.',
            ),
          ),
        ),
      ],
    );

    if (activityKey != null) {
      content = KeyedSubtree(key: activityKey, child: content);
    }

    return content;
  }
}
