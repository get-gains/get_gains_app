import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_programs/data/models/program_model.dart';
import '../../../subscription/subscription.dart';
import '../../data/models/models.dart';
import '../../data/workout_repository.dart';

/// My Program List Screen
///
/// Entry point for the coach-assigned workout flow.
/// Shows all active programs assigned to the user. Tapping a program
/// opens [MyProgramDetailScreen] which lists the routines inside it.
///
/// For lapsed subscribers (has coach but subscription expired):
/// - Coach programs are shown read-only with a "Renew" badge (tap opens paywall)
/// - Self-programs are shown normally and are fully accessible
class MyProgramListScreen extends ConsumerStatefulWidget {
  const MyProgramListScreen({super.key});

  @override
  ConsumerState<MyProgramListScreen> createState() =>
      _MyProgramListScreenState();
}

class _MyProgramListScreenState extends ConsumerState<MyProgramListScreen> {
  late Future<List<AssignedProgramModel>> _programsFuture;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  void _loadPrograms() {
    _programsFuture = _syncAndLoad();
  }

  /// Sync coach programs from server; gracefully fall back to local DB on
  /// 402 (subscription expired) or any other network failure.
  Future<List<AssignedProgramModel>> _syncAndLoad() async {
    final repo = ref.read(workoutRepositoryProvider);

    final syncResult = await repo.syncPrograms();
    return syncResult.when(
      success: (programs) => programs,
      failure: (_) async {
        // 402 / network failure — serve cached coach programs from local DB
        final localResult = await repo.getPrograms();
        return localResult.valueOrNull ?? [];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subscriptionTier = ref.watch(subscriptionTierProvider);
    final isSubscribed = ref.watch(isSubscribedProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Program'),
        centerTitle: true,
      ),
      body: isSubscribed
          ? _buildSubscribedBody(isDark)
          : _buildLapsedBody(isDark, subscriptionTier),
    );
  }

  // ─── Subscribed: normal coach-program list ────────────────────────────────

  Widget _buildSubscribedBody(bool isDark) {
    return FutureBuilder<List<AssignedProgramModel>>(
      future: _programsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final programs = snapshot.data ?? [];

        if (programs.isEmpty) {
          return Center(
            child: AppEmptyState(
              icon: Icons.book_outlined,
              title: 'No Programs Yet',
              description:
                  'Your coach hasn\'t assigned a program to you yet.\n'
                  'Check back after your coach sets up your training plan.',
              actionLabel: 'Refresh',
              onAction: () => setState(_loadPrograms),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(_loadPrograms),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: programs.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final program = programs[index];
              return _ProgramCard(
                program: program,
                isDark: isDark,
                isLocked: false,
                onTap: () => context.push(
                  AppRoutes.myProgramDetail.replaceFirst(
                    ':programId',
                    program.id,
                  ),
                  extra: program,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── Lapsed: disabled coach programs + accessible self-programs ───────────

  Widget _buildLapsedBody(bool isDark, SubscriptionTier tier) {
    return FutureBuilder<List<AssignedProgramModel>>(
      future: _programsFuture,
      builder: (context, coachSnapshot) {
        final coachPrograms = coachSnapshot.data ?? [];
        final isLoadingCoach =
            coachSnapshot.connectionState == ConnectionState.waiting;

        return RefreshIndicator(
          onRefresh: () async {
            setState(_loadPrograms);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _RenewalBanner(isDark: isDark)),

              if (isLoadingCoach)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (coachPrograms.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Coach Programs',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: coachPrograms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _ProgramCard(
                      program: coachPrograms[i],
                      isDark: isDark,
                      isLocked: true,
                      onTap: () => context.push(AppRoutes.myProgram),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Renewal Banner ────────────────────────────────────────────────────────────

class _RenewalBanner extends StatelessWidget {
  const _RenewalBanner({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription Expired',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark
                        ? Colors.amber.shade200
                        : Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Coach programs are locked. Renew to resume coach-assigned workouts.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.amber.shade300
                        : Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Program Card ─────────────────────────────────────────────────────────────

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.isDark,
    required this.isLocked,
    required this.onTap,
  });

  final AssignedProgramModel program;
  final bool isDark;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isLocked
        ? const Color(0xFFF59E0B)
        : (isDark ? AppColors.primaryDark : AppColors.primaryLight);

    // Collect all unique days from all routines
    final allDays = program.routines
        .expand((r) => r.daysOfWeek)
        .toSet()
        .toList()
      ..sort(_dayOrder);

    return Opacity(
      opacity: isLocked ? 0.75 : 1.0,
      child: AppCard.elevated(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isLocked ? Icons.lock_outline : Icons.sports_gymnastics,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (program.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            program.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isLocked)
                    AppBadge(
                      label: 'Renew',
                      variant: AppBadgeVariant.warning,
                      size: AppBadgeSize.sm,
                    )
                  else if (program.isActive)
                    AppBadge(
                      label: 'Active',
                      variant: AppBadgeVariant.primary,
                      size: AppBadgeSize.sm,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _Stat(
                    icon: Icons.folder_copy_outlined,
                    label:
                        '${program.routineCount} routine${program.routineCount == 1 ? '' : 's'}',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 16),
                  _Stat(
                    icon: Icons.fitness_center,
                    label:
                        '${program.routines.fold(0, (s, r) => s + r.exercises.length)} exercises',
                    isDark: isDark,
                  ),
                ],
              ),

              // Days-of-week row
              if (allDays.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: allDays
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

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isLocked ? 'Renew to Access' : 'View Routines',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: primaryColor),
                ],
              ),
            ],
          ),
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

  static int _dayOrder(String a, String b) {
    const order = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return order.indexOf(a.toUpperCase()).compareTo(
          order.indexOf(b.toUpperCase()),
        );
  }
}

// ─── Stat row item ────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat({
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
