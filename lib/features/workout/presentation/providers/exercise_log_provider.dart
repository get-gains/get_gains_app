import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import 'workout_session_provider.dart';

part 'exercise_log_provider.g.dart';

/// Exercise Log State
///
/// Manages the state for logging sets within a single exercise.
class ExerciseLogState {
  const ExerciseLogState({
    required this.routineExercise,
    required this.sets,
    required this.currentSetIndex,
    this.isSubmitting = false,
  });

  final RoutineExerciseModel routineExercise;
  final List<EditableSetModel> sets;
  final int currentSetIndex;
  final bool isSubmitting;

  /// Current set being edited
  EditableSetModel? get currentSet =>
      currentSetIndex < sets.length ? sets[currentSetIndex] : null;

  /// Number of completed sets
  int get completedSetsCount => sets.where((s) => s.isCompleted).length;

  /// Progress through the exercise (0.0 - 1.0)
  double get progress =>
      routineExercise.sets > 0 ? completedSetsCount / routineExercise.sets : 0;

  /// Whether all sets are completed
  bool get isAllSetsCompleted => completedSetsCount >= routineExercise.sets;

  /// Get rep range display string
  String get repRangeDisplay =>
      '${routineExercise.repsMin}-${routineExercise.repsMax}';

  ExerciseLogState copyWith({
    RoutineExerciseModel? routineExercise,
    List<EditableSetModel>? sets,
    int? currentSetIndex,
    bool? isSubmitting,
  }) {
    return ExerciseLogState(
      routineExercise: routineExercise ?? this.routineExercise,
      sets: sets ?? this.sets,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Exercise Log Provider
///
/// Manages set logging for a specific exercise.
/// Creates editable set entries and syncs with workout session.
///
/// Usage:
/// ```dart
/// // Initialize for an exercise
/// ref.read(exerciseLogProvider.notifier).initializeForExercise(routineExercise);
///
/// // Update current set
/// ref.read(exerciseLogProvider.notifier).updateCurrentSet(
///   reps: 10,
///   weight: 60.0,
/// );
///
/// // Complete current set
/// await ref.read(exerciseLogProvider.notifier).completeCurrentSet();
/// ```
@riverpod
class ExerciseLogNotifier extends _$ExerciseLogNotifier {
  @override
  ExerciseLogState? build() {
    return null;
  }

  /// Initialize for a specific exercise
  void initializeForExercise(
    RoutineExerciseModel routineExercise, {
    List<PerformedSetModel> existingSets = const [],
  }) {
    // Create editable sets based on prescription
    final editableSets = <EditableSetModel>[];

    for (int i = 1; i <= routineExercise.sets; i++) {
      // Check if this set was already completed
      final existingSet = existingSets
          .where((s) => s.setNumber == i)
          .firstOrNull;

      if (existingSet != null) {
        editableSets.add(EditableSetModel(
          id: existingSet.id,
          setNumber: i,
          reps: existingSet.repsCompleted,
          weight: existingSet.weightKg ?? 0.0,
          rpe: existingSet.rpe,
          notes: existingSet.notes,
          isCompleted: existingSet.isCompleted,
        ));
      } else {
        // Create new empty set with suggested values
        editableSets.add(EditableSetModel(
          setNumber: i,
          reps: routineExercise.repsMin,
          weight: 0.0,
          isCompleted: false,
        ));
      }
    }

    // Find first incomplete set
    final firstIncompleteIndex = editableSets.indexWhere((s) => !s.isCompleted);

    state = ExerciseLogState(
      routineExercise: routineExercise,
      sets: editableSets,
      currentSetIndex: firstIncompleteIndex >= 0 ? firstIncompleteIndex : 0,
    );
  }

  /// Update the current set values
  void updateCurrentSet({
    int? reps,
    double? weight,
    int? rpe,
    String? notes,
  }) {
    if (state == null) return;

    final currentIndex = state!.currentSetIndex;
    if (currentIndex >= state!.sets.length) return;

    final updatedSets = [...state!.sets];
    final currentSet = updatedSets[currentIndex];

    updatedSets[currentIndex] = EditableSetModel(
      id: currentSet.id,
      setNumber: currentSet.setNumber,
      reps: reps ?? currentSet.reps,
      weight: weight ?? currentSet.weight,
      rpe: rpe ?? currentSet.rpe,
      notes: notes ?? currentSet.notes,
      isCompleted: currentSet.isCompleted,
    );

    state = state!.copyWith(sets: updatedSets);
  }

  /// Update a specific set by index
  void updateSet(
    int index, {
    int? reps,
    double? weight,
    int? rpe,
    String? notes,
  }) {
    if (state == null || index >= state!.sets.length) return;

    final updatedSets = [...state!.sets];
    final targetSet = updatedSets[index];

    updatedSets[index] = EditableSetModel(
      id: targetSet.id,
      setNumber: targetSet.setNumber,
      reps: reps ?? targetSet.reps,
      weight: weight ?? targetSet.weight,
      rpe: rpe ?? targetSet.rpe,
      notes: notes ?? targetSet.notes,
      isCompleted: targetSet.isCompleted,
    );

    state = state!.copyWith(sets: updatedSets);
  }

  /// Complete the current set and save to repository
  Future<void> completeCurrentSet() async {
    if (state == null) return;

    final currentIndex = state!.currentSetIndex;
    if (currentIndex >= state!.sets.length) return;

    state = state!.copyWith(isSubmitting: true);

    final currentSet = state!.sets[currentIndex];

    // Log the set via workout session provider
    final sessionNotifier = ref.read(workoutSessionProvider.notifier);
    await sessionNotifier.logSet(
      setNumber: currentSet.setNumber,
      reps: currentSet.reps,
      weight: currentSet.weight > 0 ? currentSet.weight : null,
      rpe: currentSet.rpe,
      notes: currentSet.notes,
    );

    // Mark as completed
    final updatedSets = [...state!.sets];
    updatedSets[currentIndex] = EditableSetModel(
      id: currentSet.id,
      setNumber: currentSet.setNumber,
      reps: currentSet.reps,
      weight: currentSet.weight,
      rpe: currentSet.rpe,
      notes: currentSet.notes,
      isCompleted: true,
    );

    // Move to next incomplete set
    final nextIncompleteIndex = updatedSets
        .indexWhere((s) => !s.isCompleted, currentIndex + 1);

    state = state!.copyWith(
      sets: updatedSets,
      currentSetIndex: nextIncompleteIndex >= 0 ? nextIncompleteIndex : currentIndex,
      isSubmitting: false,
    );
  }

  /// Select a specific set to edit
  void selectSet(int index) {
    if (state == null || index >= state!.sets.length) return;
    state = state!.copyWith(currentSetIndex: index);
  }

  /// Increment reps for current set
  void incrementReps() {
    if (state == null) return;
    final currentReps = state!.currentSet?.reps ?? 0;
    updateCurrentSet(reps: currentReps + 1);
  }

  /// Decrement reps for current set
  void decrementReps() {
    if (state == null) return;
    final currentReps = state!.currentSet?.reps ?? 0;
    if (currentReps > 0) {
      updateCurrentSet(reps: currentReps - 1);
    }
  }

  /// Increment weight for current set
  void incrementWeight({double amount = 2.5}) {
    if (state == null) return;
    final currentWeight = state!.currentSet?.weight ?? 0.0;
    updateCurrentSet(weight: currentWeight + amount);
  }

  /// Decrement weight for current set
  void decrementWeight({double amount = 2.5}) {
    if (state == null) return;
    final currentWeight = state!.currentSet?.weight ?? 0.0;
    if (currentWeight >= amount) {
      updateCurrentSet(weight: currentWeight - amount);
    }
  }

  /// Reset to clear state
  void reset() {
    state = null;
  }
}
