import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../workout/data/models/exercise_model.dart';

export '../../../workout/data/models/exercise_model.dart'
    show MuscleGroup, MuscleGroupX;

part 'standalone_exercise_model.freezed.dart';
part 'standalone_exercise_model.g.dart';

/// Personal Exercise Model
///
/// Represents a user-owned exercise in the standalone workout system.
/// Extends the base [ExerciseModel] shape with ownership fields:
/// - [userId] — the owning user (standalone)
/// - [coachId] — null for personal exercises
/// - [isPublic] — visibility to other users
@freezed
abstract class StandaloneExerciseModel with _$StandaloneExerciseModel {
  const factory StandaloneExerciseModel({
    required String id,
    required String name,
    required String description,
    required MuscleGroup primaryMuscleGroup,
    @Default([]) List<String> equipmentNeeded,

    /// User who owns this exercise (null for public/coach exercises).
    String? userId,

    /// Coach who owns this exercise (null for personal exercises).
    String? coachId,

    /// Whether the exercise is publicly visible.
    @Default(false) bool isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StandaloneExerciseModel;

  factory StandaloneExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$StandaloneExerciseModelFromJson(json);
}

/// Extension for standalone exercise helpers.
extension StandaloneExerciseModelX on StandaloneExerciseModel {
  /// Whether this exercise is owned by the current user.
  bool isOwnedBy(String currentUserId) => userId == currentUserId;

  /// Whether this is a personal (user-owned) exercise.
  bool get isPersonal => userId != null;

  /// Whether this is a coach-owned exercise.
  bool get isCoachOwned => coachId != null;

  /// Convert to the base [ExerciseModel] for reuse with workout session flows.
  ExerciseModel toExerciseModel() => ExerciseModel(
    id: id,
    name: name,
    description: description,
    primaryMuscleGroup: primaryMuscleGroup,
    equipmentNeeded: equipmentNeeded,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Paginated response for standalone exercise list.
@freezed
abstract class StandaloneExerciseListResponse
    with _$StandaloneExerciseListResponse {
  const factory StandaloneExerciseListResponse({
    required List<StandaloneExerciseModel> exercises,
    required int total,
    required int limit,
    required int offset,
    @Default(false) bool hasMore,
  }) = _StandaloneExerciseListResponse;

  factory StandaloneExerciseListResponse.fromJson(Map<String, dynamic> json) =>
      _$StandaloneExerciseListResponseFromJson(json);
}
