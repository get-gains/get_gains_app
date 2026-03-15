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

  /// Total volume for the session as accumulated load per set.
  ///
  /// Product behavior expects this to be the sum of set weights, e.g.
  /// 6 sets at 5kg => 30kg.
  /// If a set's weight is missing, reuse the previous known weight for that
  /// same exercise.
  double get totalVolume {
    final byExercise = <String, List<PerformedSetModel>>{};
    for (final set in performedSets) {
      byExercise.putIfAbsent(set.routineExerciseId, () => []).add(set);
    }

    double total = 0;
    for (final sets in byExercise.values) {
      sets.sort((a, b) => a.setNumber.compareTo(b.setNumber));

      double? lastKnownWeight;
      for (final set in sets) {
        final weight = set.weightKg ?? lastKnownWeight ?? 0;
        if (set.weightKg != null && set.weightKg! > 0) {
          lastKnownWeight = set.weightKg;
        }
        total += weight;
      }
    }

    return total;
  }

  /// Get sets for a specific routine exercise
  List<PerformedSetModel> setsForExercise(String routineExerciseId) =>
      performedSets
          .where((set) => set.routineExerciseId == routineExerciseId)
          .toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
}
