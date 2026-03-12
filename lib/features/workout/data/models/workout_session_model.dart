import 'package:freezed_annotation/freezed_annotation.dart';

import 'performed_set_model.dart';

part 'workout_session_model.freezed.dart';
part 'workout_session_model.g.dart';

/// Workout Session Status
enum WorkoutSessionStatus {
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CANCELLED')
  cancelled,
}

/// Workout Session Model
///
/// Represents a single workout session performed by the user.
@freezed
abstract class WorkoutSessionModel with _$WorkoutSessionModel {
  const factory WorkoutSessionModel({
    required String id,
    required String userId,
    String? assignedProgramId,
    String? routineId,
    required DateTime startedAt,
    DateTime? completedAt,
    String? notes,
    @Default([]) List<PerformedSetModel> performedSets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _WorkoutSessionModel;

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionModelFromJson(json);
}

/// Extension for workout session calculations
extension WorkoutSessionModelX on WorkoutSessionModel {
  /// Whether the session is still in progress
  bool get isInProgress => completedAt == null;

  /// Whether the session is completed
  bool get isCompleted => completedAt != null;

  /// Duration of the workout session
  Duration? get duration => completedAt != null
      ? completedAt!.difference(startedAt)
      : DateTime.now().difference(startedAt);

  /// Number of completed sets
  int get completedSetsCount => performedSets.length;

  /// Total volume (weight × reps) for the session
  double get totalVolume => performedSets.fold(
    0.0,
    (sum, set) => sum + ((set.weightKg ?? 0) * set.repsCompleted),
  );

  /// Get sets for a specific routine exercise
  List<PerformedSetModel> setsForExercise(String routineExerciseId) =>
      performedSets
          .where((set) => set.routineExerciseId == routineExerciseId)
          .toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
}
