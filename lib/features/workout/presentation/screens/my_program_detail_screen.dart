import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';

/// My Program Detail Screen
///
/// Shows all routines inside a single [AssignedProgramModel].
/// Each routine card displays its name, days-of-week schedule,
/// exercise count, and estimated duration.
/// Tapping a routine navigates to the existing [RoutineDetailScreen].
class MyProgramDetailScreen extends StatelessWidget {
  const MyProgramDetailScreen({
    super.key,
    required this.program,
  });

  final AssignedProgramModel program;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing App Bar ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                program.name,
                style: const TextStyle(fontSize: 18),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      isDark
                          ? AppColors.primaryDark.withValues(alpha: 0.65)
                          : AppColors.primaryLight.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Program Meta ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (program.description.isNotEmpty) ...[
                    Text(
                      program.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Stats chips
                  Row(
                    children: [
                      _Chip(
                        icon: Icons.folder_copy_outlined,
                        label:
                            '${program.routineCount} routine${program.routineCount == 1 ? '' : 's'}',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _Chip(
                        icon: Icons.fitness_center,
                        label:
                            '${program.routines.fold(0, (s, r) => s + r.exercises.length)} exercises',
                        isDark: isDark,
                      ),
                      if (program.isActive) ...[
                        const SizedBox(width: 12),
                        AppBadge(
                          label: 'Active',
                          variant: AppBadgeVariant.primary,
                          size: AppBadgeSize.sm,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Routines',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // ── Routine List ──────────────────────────────────────────
          if (program.routines.isEmpty)
            SliverFillRemaining(
              child: AppEmptyState(
                icon: Icons.folder_open_outlined,
                title: 'No Routines',
                description: 'This program has no routines assigned yet.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final routine = program.routines[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RoutineCard(
                        routine: routine,
                        isDark: isDark,
                        onTap: () => context.push(
                          AppRoutes.routineDetail.replaceFirst(
                            ':id',
                            routine.id,
                          ),
                          extra: routine,
                        ),
                      ),
                    );
                  },
                  childCount: program.routines.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Routine Card ─────────────────────────────────────────────────────────────

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.isDark,
    required this.onTap,
  });

  final RoutineModel routine;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return AppCard.elevated(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            Text(
              routine.name,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            if (routine.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                routine.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Stats row
            Row(
              children: [
                _MiniStat(
                  icon: Icons.fitness_center,
                  label: '${routine.exercises.length} exercises',
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  icon: Icons.timer_outlined,
                  label: '${routine.estimatedDurationMinutes} min',
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  icon: Icons.repeat,
                  label: '${routine.totalSets} sets',
                  isDark: isDark,
                ),
              ],
            ),

            // Days of week chips
            if (routine.daysOfWeek.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: routine.daysOfWeek
                    .map(
                      (d) => AppBadge(
                        label: _shortDay(d),
                        variant: AppBadgeVariant.outline,
                        size: AppBadgeSize.sm,
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Exercises',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _shortDay(String day) {
    const map = {
      'MONDAY': 'Mon',
      'TUESDAY': 'Tue',
      'WEDNESDAY': 'Wed',
      'THURSDAY': 'Thu',
      'FRIDAY': 'Fri',
      'SATURDAY': 'Sat',
      'SUNDAY': 'Sun',
    };
    return map[day.toUpperCase()] ?? day;
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
