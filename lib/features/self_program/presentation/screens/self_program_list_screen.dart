import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_programs/data/models/program_model.dart';
import '../providers/self_programs_list_provider.dart';

class SelfProgramListScreen extends ConsumerStatefulWidget {
  const SelfProgramListScreen({super.key});

  @override
  ConsumerState<SelfProgramListScreen> createState() => _SelfProgramListScreenState();
}

class _SelfProgramListScreenState extends ConsumerState<SelfProgramListScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selfProgramsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Programs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [       
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: isDark ? AppColors.error : AppColors.errorLight,
              ),
              const SizedBox(height: 12),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AppButton(
                label: 'Retry',
                onPressed: () => ref.read(selfProgramsListProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        data: (programs) => _buildBody(programs, isDark),
      ),
    );
  }

  Widget _buildBody(List<ClientProgramModel> programs, bool isDark) {
    if (programs.isEmpty) {
      return AppEmptyState(
        icon: Icons.fitness_center,
        title: 'No Programs Yet',
        description: 'Build your own custom training program. You can create up to 5.',
        actionLabel: 'Build My Program',
        onAction: () => _navigateToBuilder(),
      );
    }

    final activePrograms = programs.where((p) => p.isActive).toList();
    final draftPrograms = programs.where((p) => !p.isActive).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(selfProgramsListProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activePrograms.isNotEmpty) ...[
            const Text(
              'Active Programs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...activePrograms.map((p) => _ProgramCard(program: p, isDark: isDark, onEdit: () => _navigateToBuilder(programId: p.id))),
            const SizedBox(height: 24),
          ],
          if (draftPrograms.isNotEmpty) ...[
            const Text(
              'Draft Programs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...draftPrograms.map((p) => _ProgramCard(program: p, isDark: isDark, onEdit: () => _navigateToBuilder(programId: p.id))),
          ],
          if (programs.length < 5) ...[
            const SizedBox(height: 24),
            AppButton.outline(
              label: 'Create Another Program (${programs.length}/5)',
              icon: Icons.add,
              isFullWidth: true,
              onPressed: () => _navigateToBuilder(),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Text(
              'You have reached the maximum of 5 programs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _navigateToBuilder({String? programId}) async {
    final uri = Uri(
      path: AppRoutes.selfProgramBuilder,
      queryParameters: programId != null ? {'programId': programId} : const {},
    );
    await context.push(uri.toString());
    if (mounted) {
      ref.read(selfProgramsListProvider.notifier).refresh();
    }
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program, required this.isDark, required this.onEdit});

  final ClientProgramModel program;
  final bool isDark;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard.elevated(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(program.name, style: theme.textTheme.titleMedium),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                ),
              ],
            ),
            if (program.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                program.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                AppBadge(
                  label: '${program.routineCount} routines',
                  variant: AppBadgeVariant.info,
                ),
                const SizedBox(width: 8),
                AppBadge(
                  label: '${program.totalExerciseCount} exercises',
                  variant: AppBadgeVariant.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
