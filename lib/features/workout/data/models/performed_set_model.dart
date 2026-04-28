import 'package:freezed_annotation/freezed_annotation.dart';

part 'performed_set_model.freezed.dart';
part 'performed_set_model.g.dart';

/// Performed Set Model
///
/// Represents a single set performed by the user during a workout session.
/// This is the actual logged data (sets, reps, weight, RPE).
@freezed
abstract class PerformedSetModel with _$PerformedSetModel {
  const factory PerformedSetModel({
    required String id,
    required String workoutSessionId,
    required String assignedProgramRoutineExerciseId,
    required int setNumber,
    required int repsCompleted,
    double? weightKg,
    int? rpe,
    String? notes,
    String? recordedFramesKey,
    double? overallScore,
    @Default(false) bool isCompleted,
    String? exerciseNameSnapshot,
    int? targetRepsMin,
    int? targetRepsMax,
    int? targetRestSeconds,
    double? targetWeightKg,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PerformedSetModel;

  factory PerformedSetModel.fromJson(Map<String, dynamic> json) =>
      _$PerformedSetModelFromJson(json);
}

/// Local set model for UI state before saving
///
/// Used to track sets being edited in the UI before committing to database.
@freezed
abstract class EditableSetModel with _$EditableSetModel {
  const factory EditableSetModel({
    String? id,
    required int setNumber,
    @Default(0) int reps,
    @Default(0.0) double weight,
    int? rpe,
    String? notes,
    @Default(false) bool isCompleted,
  }) = _EditableSetModel;
}

/// Extension for performed set calculations
extension PerformedSetModelX on PerformedSetModel {
  /// Volume for this set (weight × reps)
  double get volume => (weightKg ?? 0) * repsCompleted;

  /// Display string for the set (e.g., "3 × 10 @ 60kg")
  String get displayString {
    final weightStr = weightKg != null
        ? ' @ ${weightKg!.toStringAsFixed(1)}kg'
        : '';
    return 'Set $setNumber: $repsCompleted reps$weightStr';
  }

  /// Alias for backward-compat reads that reference routineExerciseId.
  String get routineExerciseId => assignedProgramRoutineExerciseId;
}
