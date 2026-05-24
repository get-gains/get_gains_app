import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/library_exercise_model.dart';
import '../providers/form_library_providers.dart';
import '../widgets/library_exercise_card.dart';

class FormLibraryScreen extends ConsumerStatefulWidget {
  const FormLibraryScreen({super.key});

  @override
  ConsumerState<FormLibraryScreen> createState() => _FormLibraryScreenState();
}

class _FormLibraryScreenState extends ConsumerState<FormLibraryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _muscleGroups = [
    'CHEST',
    'BACK',
    'SHOULDERS',
    'BICEPS',
    'TRICEPS',
    'FOREARMS',
    'ABS',
    'OBLIQUES',
    'QUADS',
    'HAMSTRINGS',
    'GLUTES',
    'CALVES',
  ];

  String? _selectedGroup;
  String _currentSort = 'most_rated';
  bool _searchShown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(formLibraryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final libraryState = ref.watch(formLibraryProvider);
    final notifier = ref.read(formLibraryProvider.notifier);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Form Library'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_searchShown ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searchShown = !_searchShown;
                if (!_searchShown) {
                  _searchController.clear();
                  notifier.setSearch('');
                }
              });
            },
          ),
          PopupMenuButton<String>(
            initialValue: _currentSort,
            onSelected: (value) {
              setState(() => _currentSort = value);
              notifier.setSort(value);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'most_rated',
                child: Text('Most Rated'),
              ),
              const PopupMenuItem(
                value: 'newest',
                child: Text('Newest'),
              ),
            ],
            child: const Icon(Icons.sort_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchShown)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: AppTextField(
                controller: _searchController,
                label: 'Search exercises',
                onChanged: (val) => notifier.setSearch(val),
                variant: AppTextFieldVariant.outlined,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedGroup == null,
                    isDark: isDark,
                    onTap: () {
                      setState(() => _selectedGroup = null);
                      notifier.setMuscleGroup(null);
                    },
                  ),
                  ..._muscleGroups.map((group) => _FilterChip(
                        label: group,
                        isSelected: _selectedGroup == group,
                        isDark: isDark,
                        onTap: () {
                          setState(() =>
                              _selectedGroup = _selectedGroup == group
                                  ? null
                                  : group);
                          notifier.setMuscleGroup(_selectedGroup);
                        },
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: libraryState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorState(
                description: error.toString(),
                onRetry: () => notifier.refresh(),
              ),
              data: (response) {
                if (response == null || response.exercises.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.fitness_center,
                    title: 'No Forms Found',
                    description:
                        'No public exercise forms available.\nCheck back later!',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => notifier.refresh(),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: response.exercises.length,
                    itemBuilder: (_, i) => LibraryExerciseCard(
                      exercise: response.exercises[i],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.15) : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? primary : AppColors.borderDark,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? primary : null,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
          ),
        ),
      ),
    );
  }
}
