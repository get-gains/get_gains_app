import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/coach_model.dart';
import '../providers/coach_discovery_provider.dart';

/// Coach Discovery Screen
///
/// Browse and search for public coaches. Supports search,
/// pull-to-refresh, and infinite scroll pagination.
class CoachDiscoveryScreen extends ConsumerStatefulWidget {
  const CoachDiscoveryScreen({super.key});

  @override
  ConsumerState<CoachDiscoveryScreen> createState() =>
      _CoachDiscoveryScreenState();
}

class _CoachDiscoveryScreenState extends ConsumerState<CoachDiscoveryScreen> {
  final _searchController = TextEditingController();
  String? _activeSearch;
  String? _activeSpecialty;

  static const _specialties = [
    ('Strength', Icons.fitness_center),
    ('Bodybuilding', Icons.health_and_safety),
    ('Resistance', Icons.autorenew),
    ('Calisthenics', Icons.accessibility_new),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(coachDiscoveryProvider.notifier).loadCoaches(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    setState(() {
      _activeSearch = query.isEmpty ? null : query;
      _activeSpecialty = null;
    });
    ref
        .read(coachDiscoveryProvider.notifier)
        .loadCoaches(search: query.isEmpty ? null : query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _activeSearch = null;
      _activeSpecialty = null;
    });
    ref.read(coachDiscoveryProvider.notifier).loadCoaches();
  }

  void _onSpecialtyFilter(String specialty) {
    if (_activeSpecialty == specialty) {
      setState(() => _activeSpecialty = null);
      _searchController.clear();
      ref.read(coachDiscoveryProvider.notifier).loadCoaches();
    } else {
      _searchController.text = specialty;
      setState(() {
        _activeSpecialty = specialty;
        _activeSearch = specialty;
      });
      ref
          .read(coachDiscoveryProvider.notifier)
          .loadCoaches(specialty: specialty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachDiscoveryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Coach'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            tooltip: 'My Coaches',
            onPressed: () => context.push(AppRoutes.subscribedCoaches),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppTextField.search(
              controller: _searchController,
              hint: 'Search coaches by name or specialty...',
              onSubmitted: (_) => _onSearch(),
              onClear: _clearSearch,
            ),
          ),
          // Quick specialty filter chips
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _specialties.map((s) {
                  final (label, icon) = s;
                  final isSelected = _activeSpecialty == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: label,
                      leadingIcon: icon,
                      selected: isSelected,
                      variant: isSelected
                          ? AppChipVariant.filled
                          : AppChipVariant.tonal,
                      onTap: () => _onSpecialtyFilter(label),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Results
          Expanded(child: _buildBody(state, isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(CoachDiscoveryState state, bool isDark) {
    return switch (state) {
      CoachDiscoveryInitial() || CoachDiscoveryLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      CoachDiscoveryError(:final error) => _buildError(error.message, isDark),
      CoachDiscoveryLoaded(:final coaches, :final pagination) =>
        coaches.isEmpty
            ? _buildEmpty()
            : _buildList(coaches, pagination, isDark),
    };
  }

  Widget _buildEmpty() {
    return AppEmptyState(
      icon: Icons.person_search_outlined,
      title: _activeSearch != null ? 'No Coaches Found' : 'No Coaches Yet',
      description: _activeSearch != null
          ? 'Try adjusting your search terms or browse all coaches.'
          : 'Check back soon — coaches are joining the platform regularly.',
      actionLabel: _activeSearch != null ? 'Clear Search' : null,
      onAction: _activeSearch != null ? _clearSearch : null,
    );
  }

  Widget _buildError(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? AppColors.error : AppColors.errorLight,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Retry',
            onPressed: () => ref
                .read(coachDiscoveryProvider.notifier)
                .loadCoaches(search: _activeSearch),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<CoachSummaryModel> coaches,
    CoachPaginationMeta pagination,
    bool isDark,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref
          .read(coachDiscoveryProvider.notifier)
          .loadCoaches(search: _activeSearch),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: coaches.length + (pagination.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= coaches.length) {
            Future.microtask(
              () => ref
                  .read(coachDiscoveryProvider.notifier)
                  .loadMore(search: _activeSearch),
            );
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final coach = coaches[index];
          return _CoachDiscoveryCard(
            coach: coach,
            isDark: isDark,
            onTap: () => context.push(
              AppRoutes.coachProfile.replaceFirst(':id', coach.id),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Coach Discovery Card
// ──────────────────────────────────────────────────────────

class _CoachDiscoveryCard extends StatelessWidget {
  const _CoachDiscoveryCard({
    required this.coach,
    required this.isDark,
    required this.onTap,
  });

  final CoachSummaryModel coach;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.interactive(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          AppAvatar(
            imageUrl: coach.avatarUrl,
            name: coach.name,
            size: AppAvatarSize.lg,
          ),
          const SizedBox(width: 12),
          // Coach info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        coach.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (coach.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 18,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ],
                  ],
                ),
                if (coach.bio != null && coach.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    coach.bio!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (coach.yearsExperience > 0)
                      _CoachInfoChip(
                        icon: Icons.workspace_premium_outlined,
                        label: '${coach.yearsExperience}y exp',
                        isDark: isDark,
                      ),
                    ...coach.specialties
                        .take(2)
                        .map(
                          (s) => _CoachInfoChip(
                            icon: Icons.fitness_center,
                            label: s,
                            isDark: isDark,
                          ),
                        ),
                    if (coach.specialties.length > 2)
                      _CoachInfoChip(
                        icon: Icons.more_horiz,
                        label: '+${coach.specialties.length - 2}',
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ],
      ),
    );
  }
}

class _CoachInfoChip extends StatelessWidget {
  const _CoachInfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface3Dark.withValues(alpha: 0.5)
            : AppColors.surface3Light.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ],
      ),
    );
  }
}
