import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'routine_model.dart';

part 'assigned_program_model.freezed.dart';
part 'assigned_program_model.g.dart';

/// Normalizes the JSON from `GET /workout/programs` into a consistent shape.
Map<String, dynamic> _normalizeAssignedProgramJson(
  Map<String, dynamic> json,
) {
  final n = Map<String, dynamic>.from(json);

  n['description'] ??= '';
  n['isActive'] ??= n['is_active'] ?? true;
  n['startDate'] ??= n['start_date'];
  n['endDate'] ??= n['end_date'];
  n['routines'] ??= const <dynamic>[];

  return n;
}

/// Assigned Program Model
///
/// Represents a coach-assigned training program that belongs to the user.
/// Contains one or more [RoutineModel]s, each scheduled on specific days.
///
/// Sourced from `GET /workout/programs` and cached locally in [AssignedPrograms].
@freezed
abstract class AssignedProgramModel with _$AssignedProgramModel {
  const factory AssignedProgramModel({
    required String id,
    required String name,
    @Default('') String description,
    @Default(true) bool isActive,
    DateTime? startDate,
    DateTime? endDate,
    @Default([]) List<RoutineModel> routines,
  }) = _AssignedProgramModel;

  factory AssignedProgramModel.fromJson(Map<String, dynamic> json) =>
      _$AssignedProgramModelFromJson(
        _normalizeAssignedProgramJson(json),
      );
}

// ─── Extensions ───────────────────────────────────────────────────────────────

extension AssignedProgramModelX on AssignedProgramModel {
  /// Number of routines in this program.
  int get routineCount => routines.length;

  /// Serialize routines to a JSON string for local DB storage.
  String get routinesJson =>
      jsonEncode(routines.map((r) => r.toJson()).toList());

  /// Build an [AssignedProgramModel] from a local DB row's routinesJson string.
  static AssignedProgramModel fromDbRow({
    required String remoteId,
    required String name,
    required String description,
    required bool isActive,
    required DateTime? startDate,
    required DateTime? endDate,
    required String routinesJson,
  }) {
    final List<dynamic> decoded =
        jsonDecode(routinesJson) as List<dynamic>;
    final routines = decoded
        .map((r) => RoutineModel.fromJson(r as Map<String, dynamic>))
        .toList();

    return AssignedProgramModel(
      id: remoteId,
      name: name,
      description: description,
      isActive: isActive,
      startDate: startDate,
      endDate: endDate,
      routines: routines,
    );
  }
}
