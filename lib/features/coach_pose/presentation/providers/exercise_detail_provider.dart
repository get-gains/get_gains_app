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
    this.poseConfig,
    this.isLoading = false,
    this.errorMessage,
    this.isFormActionLoading = false,
  });

  final ExerciseModel? exercise;
  final List<ExerciseFormModel> forms;
  final PoseConfigModel? poseConfig;
  final bool isLoading;
  final String? errorMessage;
  final bool isFormActionLoading; // For delete/activate actions

  ExerciseDetailState copyWith({
    ExerciseModel? exercise,
    List<ExerciseFormModel>? forms,
    PoseConfigModel? poseConfig,
    bool clearPoseConfig = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isFormActionLoading,
  }) {
    return ExerciseDetailState(
      exercise: exercise ?? this.exercise,
      forms: forms ?? this.forms,
      poseConfig: clearPoseConfig ? null : (poseConfig ?? this.poseConfig),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isFormActionLoading: isFormActionLoading ?? this.isFormActionLoading,
    );
  }

  ExerciseFormModel? get activeForm {
    try {
      return forms.firstWhere((f) => f.isActive);
    } catch (_) {
      return null;
    }
  }

  List<ExerciseFormModel> get inactiveForms =>
      forms.where((f) => !f.isActive).toList();
}

/// Manages exercise detail screen state.
///
/// Loads exercise info, forms, and pose config.
/// Handles form activation and deletion.
@riverpod
class ExerciseDetailNotifier extends _$ExerciseDetailNotifier {
  @override
  ExerciseDetailState build(String exerciseId) {
    Future.microtask(() => loadAll());
    return const ExerciseDetailState(isLoading: true);
  }

  /// Load exercise details, forms, and pose config.
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final repo = ref.read(coachPoseRepositoryProvider);

    // Load forms and config in parallel
    final formsResult = await repo.getExerciseForms(exerciseId);
    final configResult = await repo.getPoseConfig(exerciseId);

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

    configResult.when(
      success: (config) {
        if (config != null) {
          state = state.copyWith(poseConfig: config);
        } else {
          state = state.copyWith(clearPoseConfig: true);
          AppLogger.debug(
            'No pose config for $exerciseId yet',
            tag: 'ExerciseDetail',
          );
        }
      },
      failure: (error) {
        AppLogger.warning(
          'Failed to load pose config for $exerciseId: ${error.message}',
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

  /// Activate a specific form version.
  Future<void> activateForm(String formId) async {
    state = state.copyWith(isFormActionLoading: true);

    final repo = ref.read(coachPoseRepositoryProvider);
    final result = await repo.activateForm(formId);

    result.when(
      success: (_) {
        AppLogger.info('Form $formId activated', tag: 'ExerciseDetail');
        // Reload forms to reflect changes
        loadAll();
      },
      failure: (error) {
        state = state.copyWith(
          isFormActionLoading: false,
          errorMessage: error.message,
        );
      },
    );
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
