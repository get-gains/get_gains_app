import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_result_model.freezed.dart';
part 'form_result_model.g.dart';

/// A single form comparison result for a client.
@freezed
abstract class ClientFormResult with _$ClientFormResult {
  const factory ClientFormResult({
    required String id,
    @Default(0.0) double overallScore,
    @Default({}) Map<String, dynamic> segmentScores,
    @Default([]) List<FormCorrection> corrections,
    String? cameraAngle,
    String? recordedFramesKey,
    String? exerciseName,
    int? durationMs,
    int? totalFrames,
    required DateTime createdAt,
    FormResultExerciseForm? exerciseForm,
  }) = _ClientFormResult;

  factory ClientFormResult.fromJson(Map<String, dynamic> json) =>
      _$ClientFormResultFromJson(json);
}

/// Correction detail for a specific body segment.
@freezed
abstract class FormCorrection with _$FormCorrection {
  const factory FormCorrection({
    required String segment,
    required String message,
  }) = _FormCorrection;

  factory FormCorrection.fromJson(Map<String, dynamic> json) =>
      _$FormCorrectionFromJson(json);
}

/// Exercise form metadata nested in a form result.
@freezed
abstract class FormResultExerciseForm with _$FormResultExerciseForm {
  const factory FormResultExerciseForm({
    required String id,
    String? cameraAngle,
    FormResultExercise? exercise,
    FormResultCoach? coach,
  }) = _FormResultExerciseForm;

  factory FormResultExerciseForm.fromJson(Map<String, dynamic> json) =>
      _$FormResultExerciseFormFromJson(json);
}

/// Minimal exercise info nested in form result.
@freezed
abstract class FormResultExercise with _$FormResultExercise {
  const factory FormResultExercise({required String id, required String name}) =
      _FormResultExercise;

  factory FormResultExercise.fromJson(Map<String, dynamic> json) =>
      _$FormResultExerciseFromJson(json);
}

/// Minimal coach info nested in form result.
@freezed
abstract class FormResultCoach with _$FormResultCoach {
  const factory FormResultCoach({required String id, required String name}) =
      _FormResultCoach;

  factory FormResultCoach.fromJson(Map<String, dynamic> json) =>
      _$FormResultCoachFromJson(json);
}
