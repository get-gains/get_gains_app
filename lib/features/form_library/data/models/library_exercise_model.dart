import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_exercise_model.freezed.dart';
part 'library_exercise_model.g.dart';

@freezed
abstract class LibraryExerciseModel with _$LibraryExerciseModel {
  const factory LibraryExerciseModel({
    required String id,
    required String name,
    required String description,
    @Default([]) List<String> targetMuscles,
    @JsonKey(name: 'coach_name') @Default('') String coachName,
    String? coachAvatarUrl,
    @Default(0) int thumbsUpCount,
    @Default(false) bool isRatedByUser,
    @Default(false) bool hasForms,
    DateTime? createdAt,
  }) = _LibraryExerciseModel;

  factory LibraryExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$LibraryExerciseModelFromJson(json);
}

@freezed
abstract class FormLibraryResponse with _$FormLibraryResponse {
  const factory FormLibraryResponse({
    required List<LibraryExerciseModel> exercises,
    required int total,
    required int limit,
    required int offset,
    @Default(false) bool hasMore,
  }) = _FormLibraryResponse;

  factory FormLibraryResponse.fromJson(Map<String, dynamic> json) =>
      _$FormLibraryResponseFromJson(json);
}
