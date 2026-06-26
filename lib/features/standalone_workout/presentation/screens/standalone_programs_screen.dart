import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/standalone_program_provider.dart';

class StandaloneProgramsScreen extends ConsumerWidget {
  const StandaloneProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final programsAsync = ref.watch(standaloneProgramListProvider);
    final pagination = ref.watch(standaloneProgramPaginationProvider);

    void loadMore() {
      ref.read(standaloneProgramPaginationProvider.notifier).loadMore();
    }

    Future<void> refresh() async {
      await ref.read(standaloneProgramPaginationProvider.notifier).reset();
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'My Programs',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.standaloneProgramBuilder),
        icon: const Icon(Icons.add),
        label: const Text('New Program'),
      ),
      body: programsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could Not Load',
          description: error.toString(),
          actionLabel: 'Retry',
          onAction: refresh,
        ),
        data: (response) {
          final programs = response.programs;
          if (programs.isEmpty) {
            return AppEmptyState(
              icon: Icons.fitness_center,
              title: 'No Programs Yet',
              description:
                  'Build your first workout program using the workout builder.',
              actionLabel: 'Build My First Program',
              onAction: () => context.push(AppRoutes.standaloneProgramBuilder),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200) {
                  loadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: programs.length + (pagination.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= programs.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final program = programs[index];
                  return _ProgramListItem(
                    program: program,
                    isDark: isDark,
                    onTap: () => context.push(
                      AppRoutes.standaloneProgramDetail.replaceAll(
                        ':id',
                        program.id,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgramListItem extends ConsumerWidget {
  const _ProgramListItem({
    required this.program,
    required this.isDark,
    required this.onTap,
  });

  final StandaloneProgram program;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard.elevated(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    program.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: AppTextStyles.fontFamilySans,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (program.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTextStyles.fontFamilySans,
                      ),
                    ),
                  ),
              ],
            ),
            if (program.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                program.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
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
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
