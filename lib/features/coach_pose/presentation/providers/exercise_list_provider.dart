import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../../data/coach_pose_repository.dart';

part 'exercise_list_provider.g.dart';

/// State for the exercise list screen.
class ExerciseListState {
  const ExerciseListState({
    this.exercises = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedMuscleGroup,
    this.errorMessage,
    this.hasMore = true,
  });

  final List<ExerciseModel> exercises;
  final bool isLoading;
  final String searchQuery;
  final MuscleGroup? selectedMuscleGroup;
  final String? errorMessage;
  final bool hasMore;

  ExerciseListState copyWith({
    List<ExerciseModel>? exercises,
    bool? isLoading,
    String? searchQuery,
    MuscleGroup? selectedMuscleGroup,
    bool clearMuscleGroup = false,
    String? errorMessage,
    bool clearError = false,
    bool? hasMore,
  }) {
    return ExerciseListState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMuscleGroup: clearMuscleGroup
          ? null
          : (selectedMuscleGroup ?? this.selectedMuscleGroup),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Manages the exercise list with search and filter capabilities.
@riverpod
class ExerciseListNotifier extends _$ExerciseListNotifier {
  static const int _pageSize = 50;

  @override
  ExerciseListState build() {
    // Auto-load exercises on creation
    Future.microtask(() => loadExercises());
    return const ExerciseListState(isLoading: true);
  }

  /// Load exercises from the API (fresh load).
  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final repo = ref.read(coachPoseRepositoryProvider);
    final result = await repo.getExercises(
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      muscleGroup: state.selectedMuscleGroup?.name.toUpperCase(),
      limit: _pageSize,
      offset: 0,
    );

    result.when(
      success: (exercises) {
        state = state.copyWith(
          exercises: exercises,
          isLoading: false,
          hasMore: exercises.length >= _pageSize,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Failed to load exercises',
          tag: 'ExerciseList',
          error: error,
        );
        state = state.copyWith(isLoading: false, errorMessage: error.message);
      },
    );
  }

  /// Load the next page of exercises.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    final repo = ref.read(coachPoseRepositoryProvider);
    final result = await repo.getExercises(
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      muscleGroup: state.selectedMuscleGroup?.name.toUpperCase(),
      limit: _pageSize,
      offset: state.exercises.length,
    );

    result.when(
      success: (exercises) {
        state = state.copyWith(
          exercises: [...state.exercises, ...exercises],
          isLoading: false,
          hasMore: exercises.length >= _pageSize,
        );
      },
      failure: (error) {
        state = state.copyWith(isLoading: false, errorMessage: error.message);
      },
    );
  }

  /// Update the search query and reload.
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadExercises();
  }

  /// Set the muscle group filter and reload.
  Future<void> filterByMuscleGroup(MuscleGroup? muscleGroup) async {
    if (muscleGroup == null) {
      state = state.copyWith(clearMuscleGroup: true);
    } else {
      state = state.copyWith(selectedMuscleGroup: muscleGroup);
    }
    await loadExercises();
  }

  /// Refresh the list (pull-to-refresh).
  Future<void> refresh() async {
    await loadExercises();
  }
}
