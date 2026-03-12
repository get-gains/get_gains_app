import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/standalone_program_provider.dart';

/// Standalone Programs List Screen
///
/// Displays user-created programs. Offline-first: shows cached → syncs server.
/// Supports pull-to-refresh, pagination, and navigation to detail/create.
class StandaloneProgramsScreen extends ConsumerStatefulWidget {
  const StandaloneProgramsScreen({super.key});

  @override
  ConsumerState<StandaloneProgramsScreen> createState() =>
      _StandaloneProgramsScreenState();
}

class _StandaloneProgramsScreenState
    extends ConsumerState<StandaloneProgramsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(standaloneProgramsProvider.notifier).loadPrograms(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(standaloneProgramsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Programs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'My Routines',
            onPressed: () => context.push(AppRoutes.standaloneRoutines),
          ),
        ],
      ),
      body: _buildBody(state, isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.standaloneCreateProgram),
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Program'),
      ),
    );
  }

  Widget _buildBody(StandaloneProgramsState state, bool isDark) {
    return switch (state) {
      StandaloneProgramsInitial() || StandaloneProgramsLoading() =>
        const Center(child: CircularProgressIndicator()),
      StandaloneProgramsError(:final error) => _buildError(error, isDark),
      StandaloneProgramsLoaded(:final programs) =>
        programs.isEmpty
            ? _buildEmpty()
            : _buildList(state as StandaloneProgramsLoaded, isDark),
    };
  }

  Widget _buildEmpty() {
    return AppEmptyState(
      icon: Icons.assignment_outlined,
      title: 'No Programs Yet',
      description:
          'Create your first training program to organize routines into a cycle.',
      actionLabel: 'Create Program',
      onAction: () => context.push(AppRoutes.standaloneCreateProgram),
    );
  }

  Widget _buildError(AppError error, bool isDark) {
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
            error.message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Retry',
            onPressed: () =>
                ref.read(standaloneProgramsProvider.notifier).loadPrograms(),
          ),
        ],
      ),
    );
  }

  Widget _buildList(StandaloneProgramsLoaded loaded, bool isDark) {
    final programs = loaded.programs;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(standaloneProgramsProvider.notifier).loadPrograms(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: programs.length + (loaded.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= programs.length) {
            Future.microtask(
              () => ref.read(standaloneProgramsProvider.notifier).loadMore(),
            );
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final program = programs[index];
          return _ProgramCard(
            program: program,
            isDark: isDark,
            onTap: () => context.push(
              AppRoutes.standaloneProgramDetail.replaceFirst(':id', program.id),
            ),
            onDelete: () => _confirmDelete(program),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(StandaloneProgramSummaryModel program) async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Delete Program',
      message:
          'Delete "${program.name}"? This will remove all routine assignments. The routines themselves will not be deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(standaloneProgramsProvider.notifier)
          .deleteProgram(program.id);
      if (mounted) {
        if (success) {
          AppToast.success(context, 'Program deleted');
        } else {
          AppToast.error(context, 'Failed to delete program');
        }
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Program Card
// ──────────────────────────────────────────────────────────

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final StandaloneProgramSummaryModel program;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.interactive(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  program.name,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push(
                      AppRoutes.standaloneEditProgram.replaceFirst(
                        ':id',
                        program.id,
                      ),
                    );
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (program.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              program.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.fitness_center,
                label: '${program.routineCount} routines',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
      ],
    );
  }
}
