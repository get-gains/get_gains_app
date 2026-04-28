import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../../data/models/models.dart';
import '../../data/coach_pose_repository.dart';

part 'exercise_detail_provider.g.dart';

/// Combined state for exercise detail screen.
class ExerciseDetailState {
  const ExerciseDetailState({
    this.exercise,
    this.forms = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isFormActionLoading = false,
  });

  final ExerciseModel? exercise;
  final List<ExerciseFormModel> forms;
  final bool isLoading;
  final String? errorMessage;
  final bool isFormActionLoading; // For delete actions

  ExerciseDetailState copyWith({
    ExerciseModel? exercise,
    List<ExerciseFormModel>? forms,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isFormActionLoading,
  }) {
    return ExerciseDetailState(
      exercise: exercise ?? this.exercise,
      forms: forms ?? this.forms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isFormActionLoading: isFormActionLoading ?? this.isFormActionLoading,
    );
  }
}

/// Manages exercise detail screen state.
///
/// Loads exercise info and forms.
/// Handles form deletion.
@riverpod
class ExerciseDetailNotifier extends _$ExerciseDetailNotifier {
  @override
  ExerciseDetailState build(String exerciseId) {
    Future.microtask(() => loadAll());
    return const ExerciseDetailState(isLoading: true);
  }

  /// Load exercise details and forms.
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final repo = ref.read(coachPoseRepositoryProvider);

    final formsResult = await repo.getExerciseForms(exerciseId);

    formsResult.when(
      success: (forms) {
        state = state.copyWith(forms: forms);
      },
      failure: (error) {
        AppLogger.warning(
          'Failed to load forms for $exerciseId',
          tag: 'ExerciseDetail',
        );
      },
    );

    state = state.copyWith(isLoading: false);
  }

  /// Set the exercise data (passed from list screen).
  void setExercise(ExerciseModel exercise) {
    state = state.copyWith(exercise: exercise);
  }

  /// Delete a form.
  Future<void> deleteForm(String formId) async {
    state = state.copyWith(isFormActionLoading: true);

    final repo = ref.read(coachPoseRepositoryProvider);
    final result = await repo.deleteForm(formId);

    result.when(
      success: (_) {
        AppLogger.info('Form $formId deleted', tag: 'ExerciseDetail');
        state = state.copyWith(
          forms: state.forms.where((f) => f.id != formId).toList(),
          isFormActionLoading: false,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isFormActionLoading: false,
          errorMessage: error.message,
        );
      },
    );
  }

  /// Refresh all data.
  Future<void> refresh() async {
    await loadAll();
  }
}
