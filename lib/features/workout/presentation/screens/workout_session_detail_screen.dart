import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/widgets.dart';
import '../providers/session_detail_provider.dart';

/// Session detail screen — full workout breakdown.
///
/// Displays session header (name, source badge, date, duration),
/// summary stats (volume, sets, reps), per-exercise set tables,
/// and highlights the heaviest set (PR) per exercise.
class WorkoutSessionDetailScreen extends ConsumerStatefulWidget {
  const WorkoutSessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<WorkoutSessionDetailScreen> createState() =>
      _WorkoutSessionDetailScreenState();
}

class _WorkoutSessionDetailScreenState
    extends ConsumerState<WorkoutSessionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: detailAsync.when(
          data: (detail) {
            if (detail == null) {
              return AppEmptyState(
                icon: Icons.search_off,
                title: 'Session not found',
                description:
                    'This workout session could not be found on the server.',
                actionLabel: 'Go Back',
                onAction: () => context.pop(),
              );
            }
            return _buildContent(context, detail, isDark);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AppErrorState(
            title: 'Failed to load session',
            description: '$error',
            onRetry: () =>
                ref.invalidate(sessionDetailProvider(widget.sessionId)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UnifiedSessionDetail detail,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return CustomScrollView(
      slivers: [
        // ── App Bar ──────────────────────────────────────
        SliverAppBar(
          floating: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Session Detail',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Hero Header Card ─────────────────────────
              _HeroHeaderCard(detail: detail, isDark: isDark),
              const SizedBox(height: 16),

              // ── Summary Stats Row ────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppStatsCard(
                      label: 'Sets',
                      value: '${detail.totalSets}',
                      icon: Icons.repeat,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppStatsCard(
                      label: 'Reps',
                      value: '${detail.totalReps}',
                      icon: Icons.sync,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Duration pill ────────────────────────────
              if (detail.durationMinutes != null) ...[
                _DurationBanner(
                  durationDisplay: detail.durationDisplay,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
              ],

              // ── Notes ────────────────────────────────────
              if (detail.notes != null && detail.notes!.isNotEmpty) ...[
                _NotesBanner(notes: detail.notes!, isDark: isDark),
                const SizedBox(height: 20),
              ],

              // ── Exercises ────────────────────────────────
              if (detail.exercises.isNotEmpty) ...[
                Text(
                  'Exercises',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...detail.exercises.map(
                  (group) => _ExerciseTile(
                    group: group,
                    isDark: isDark,
                  ),
                ),
              ] else ...[
                // No sets logged
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.fitness_center,
                            size: 40, color: secondary),
                        const SizedBox(height: 8),
                        Text(
                          'No sets logged for this session.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Hero Header Card
// ──────────────────────────────────────────────────────────

class _HeroHeaderCard extends StatelessWidget {
  const _HeroHeaderCard({required this.detail, required this.isDark});

  final UnifiedSessionDetail detail;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Source Badge row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    detail.routineName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SourceBadge(isCoach: detail.isCoach, isDark: isDark),
              ],
            ),

            if (detail.programName != null) ...[
              const SizedBox(height: 4),
              Text(
                detail.programName!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Date + Time
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: DateFormat('EEE, MMM d yyyy  ·  h:mm a')
                  .format(detail.startedAt.toLocal()),
              isDark: isDark,
            ),

            // Duration
            if (detail.durationMinutes != null) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.timer_rounded,
                label: '${detail.durationDisplay} workout',
                isDark: isDark,
              ),
            ],

            // Exercises count
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.fitness_center_rounded,
              label:
                  '${detail.exercises.length} exercise${detail.exercises.length == 1 ? '' : 's'}',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Row(
      children: [
        Icon(icon, size: 14, color: secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: secondary,
                ),
          ),
        ),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.isCoach, required this.isDark});

  final bool isCoach;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCoach ? Icons.school_rounded : Icons.person_rounded,
            size: 12,
            color: primary,
          ),
          const SizedBox(width: 4),
          Text(
            isCoach ? 'Coach' : 'Standalone',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Duration Banner
// ──────────────────────────────────────────────────────────

class _DurationBanner extends StatelessWidget {
  const _DurationBanner({
    required this.durationDisplay,
    required this.isDark,
  });

  final String durationDisplay;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.15),
            primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer_rounded, size: 20, color: primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Duration',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                durationDisplay,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Notes Banner
// ──────────────────────────────────────────────────────────

class _NotesBanner extends StatelessWidget {
  const _NotesBanner({required this.notes, required this.isDark});

  final String notes;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notes_rounded, size: 18, color: secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Exercise Tile
// ──────────────────────────────────────────────────────────

class _ExerciseTile extends StatefulWidget {
  const _ExerciseTile({required this.group, required this.isDark});

  final UnifiedExerciseGroup group;
  final bool isDark;

  @override
  State<_ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<_ExerciseTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final secondary = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final maxWeight = widget.group.maxWeightKg;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Exercise icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(Icons.fitness_center,
                          size: 22, color: primary),
                    ),
                    const SizedBox(width: 12),
                    // Name + summary
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.group.exerciseName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.group.sets.length} sets · ${widget.group.totalReps} reps'
                            '${maxWeight != null ? ' · ${maxWeight.toStringAsFixed(1)} kg max' : ''}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: secondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppTheme.durationNormal,
                      child: Icon(Icons.expand_more, color: secondary),
                    ),
                  ],
                ),
              ),
            ),

            // Sets table (animated)
            AnimatedCrossFade(
              firstChild: _buildSetsTable(theme, primary, secondary, maxWeight),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: AppTheme.durationNormal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetsTable(
    ThemeData theme,
    Color primary,
    Color secondary,
    double? maxWeightKg,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Column headers
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _headerCell(theme, 'Set', secondary, flex: 1),
                _headerCell(theme, 'Reps', secondary, flex: 2),
                const Spacer(flex: 2),
                _headerCell(theme, 'Weight', secondary, flex: 2),
                const SizedBox(width: 24), // trophy column
              ],
            ),
          ),
          const Divider(height: 1),
          // Set rows
          ...widget.group.sets.map((set) {
            final isPR = maxWeightKg != null &&
                set.weightKg != null &&
                (set.weightKg! - maxWeightKg).abs() < 0.01;
            return _SetRow(
              set: set,
              isPR: isPR,
              theme: theme,
              primary: primary,
              secondary: secondary,
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(ThemeData theme, String text, Color color,
      {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Individual Set Row
// ──────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.set,
    required this.isPR,
    required this.theme,
    required this.primary,
    required this.secondary,
  });

  final UnifiedSet set;
  final bool isPR;
  final ThemeData theme;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      decoration: isPR
          ? BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '${set.setNumber}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isPR ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${set.repsCompleted}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 2,
            child: Text(
              set.weightKg != null
                  ? '${set.weightKg!.toStringAsFixed(1)} kg'
                  : '—',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isPR ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // PR icon
          SizedBox(
            width: 24,
            child: isPR
                ? Tooltip(
                    message: 'Heaviest set',
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 16,
                      color: Colors.amber.shade600,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
