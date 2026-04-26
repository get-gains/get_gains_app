import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/widgets.dart';
import '../../data/models/mission_list_item_model.dart';
import '../providers/missions_provider.dart';

/// Lists active missions and the signed-in user's progress.
class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMissions = ref.watch(missionsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Missions',
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
            ref.invalidate(missionsListProvider);
            await ref.read(missionsListProvider.future);
          },
          child: asyncMissions.when(
            data: (missions) {
              if (missions.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: AppEmptyState.compact(
                        icon: Icons.flag_outlined,
                        title: 'No active missions',
                        description:
                            'Check back later for challenges and rewards.',
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: missions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) => _MissionCard(mission: missions[i]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 100),
                Center(
                  child: AppEmptyState.compact(
                    icon: Icons.error_outline,
                    title: 'Could not load missions',
                    description: e.toString(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission});

  final MissionListItemModel mission;

  String _goalLabel() {
    switch (mission.goalType) {
      case 'COMPLETE_WORKOUTS':
        return 'Workouts';
      case 'EARN_COINS':
        return 'Gains Coins';
      default:
        return 'Progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = mission.displayProgress.clamp(0, mission.goalToReach);
    final ratio = mission.goalToReach > 0 ? progress / mission.goalToReach : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mission.partner != null)
              Text(
                mission.partner!.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            Text(
              mission.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mission.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_goalLabel()}: $progress / ${mission.goalToReach}',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (mission.rewardCoins > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Reward: ${mission.rewardCoins} Gains Coins',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
            if (mission.maxWinners != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Limited to ${mission.maxWinners} winners',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
