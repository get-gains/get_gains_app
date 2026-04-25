import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../../data/models/exercise_form_model.dart';
import '../providers/exercise_detail_provider.dart';
import '../widgets/form_card.dart';

/// Exercise detail screen showing info, forms, and config.
///
/// Receives exercise data via extra, loads forms and config from API.
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    this.exercise,
  });

  final String exerciseId;
  final ExerciseModel? exercise;

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Pass exercise data if available
    if (widget.exercise != null) {
      Future.microtask(() {
        ref
            .read(exerciseDetailProvider(widget.exerciseId).notifier)
            .setExercise(widget.exercise!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseDetailProvider(widget.exerciseId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exercise = state.exercise ?? widget.exercise;

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise?.name ?? 'Exercise Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark
              ? AppColors.primaryDark
              : AppColors.primaryLight,
          labelColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          unselectedLabelColor: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Forms'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(exercise: exercise, isDark: isDark),
          _FormsTab(
            exerciseId: widget.exerciseId,
            state: state,
            isDark: isDark,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(
            AppRoutes.recordForm.replaceFirst(':id', widget.exerciseId),
          );
        },
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.videocam),
        label: const Text('Record Form'),
      ),
    );
  }
}

/// Tab showing exercise information.
class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.exercise, required this.isDark});

  final ExerciseModel? exercise;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (exercise == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface1Dark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            exercise!.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 20),

        // Primary Muscle Group
        Text(
          'Primary Muscle Group',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface1Dark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                exercise!.primaryMuscleGroup.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Equipment
        if (exercise!.equipmentNeeded.isNotEmpty) ...[
          Text(
            'Equipment',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: exercise!.equipmentNeeded.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surface2Dark
                      : AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.build_outlined,
                      size: 16,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    const SizedBox(width: 6),
                    Text(e, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Tab showing recorded forms.
class _FormsTab extends ConsumerWidget {
  const _FormsTab({
    required this.exerciseId,
    required this.state,
    required this.isDark,
  });

  final String exerciseId;
  final ExerciseDetailState state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.forms.isEmpty) {
      return AppEmptyState.compact(
        icon: Icons.videocam_off_outlined,
        title: 'No Forms Recorded',
        description:
            'Record a reference form for this exercise using the button below.',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(exerciseDetailProvider(exerciseId).notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.forms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final form = state.forms[index];
          return FormCard(
            form: form,
            onTap: () {
              context.push(
                AppRoutes.coachViewForm
                    .replaceFirst(':id', exerciseId)
                    .replaceFirst(':formId', form.id),
              );
            },
            onDelete: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Form?'),
                  content: Text(
                    'Are you sure you want to delete this ${form.cameraAngle.displayName} form? '
                    'This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.error
                            : AppColors.errorLight,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                ref
                    .read(exerciseDetailProvider(exerciseId).notifier)
                    .deleteForm(form.id);
              }
            },
          );
        },
      ),
    );
  }
}
