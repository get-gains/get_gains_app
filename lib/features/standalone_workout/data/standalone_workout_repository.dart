import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:get_gains_app/features/standalone_workout/data/models/standalone_request_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/database/app_database.dart';
import '../../workout/data/models/exercise_model.dart';
import '../../workout/data/models/routine_model.dart';
import '../../workout/data/models/weekly_stats_model.dart';
import '../../workout/data/models/workout_session_model.dart';
import 'models/models.dart';

part 'standalone_workout_repository.g.dart';

/// Standalone Workout Repository
///
/// Handles all standalone (user-owned) workout data operations.
/// Implements **offline-first** patterns:
/// - Local database (Drift) for exercises, routines, programs, sessions
/// - API client for server sync and server-only operations
/// - Sync queue for pending local changes
///
/// Server-only operations (no local cache):
/// - Today's workout resolution
/// - Weekly stats aggregation
///
/// Offline-first operations (local DB + sync):
/// - Exercise CRUD
/// - Routine CRUD (with exercises)
/// - Program CRUD (with routine assignments)
/// - Program activation/deactivation
/// - Session lifecycle (start, complete)
class StandaloneWorkoutRepository {
  StandaloneWorkoutRepository({
    required AppDatabase database,
    required ApiClient apiClient,
  }) : _db = database,
       _apiClient = apiClient;

  final AppDatabase _db;
  final ApiClient _apiClient;

  // ════════════════════════════════════════════════════════
  //  EXERCISE OPERATIONS
  // ════════════════════════════════════════════════════════

  /// Get exercises from local database (user-owned + public).
  Future<Result<List<StandaloneExerciseModel>, AppError>>
  getExercisesLocal() async {
    try {
      AppLogger.debug(
        'Fetching standalone exercises from local DB',
        tag: 'StandaloneRepo',
      );
      final exercises = await _db.getAllExercises();
      return Success(
        exercises
            .map(
              (e) => StandaloneExerciseModel(
                id: e.remoteId ?? e.id.toString(),
                name: e.name,
                description: e.description,
                primaryMuscleGroup: _parseMuscleGroup(e.primaryMuscleGroup),
                equipmentNeeded: _parseJsonList(e.equipmentNeeded),
                isPublic: true, // local cache doesn't track ownership
                createdAt: e.createdAt,
                updatedAt: e.updatedAt,
              ),
            )
            .toList(),
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch exercises from local DB',
        tag: 'StandaloneRepo',
        error: e,
      );
      return Failure(DatabaseError(message: 'Failed to load exercises: $e'));
    }
  }

  /// Sync exercises from server (user-owned + public).
  ///
  /// Calls `GET /api/standalone/exercises` with optional filters.
  Future<Result<StandaloneExerciseListResponse, AppError>> syncExercises({
    MuscleGroup? muscleGroup,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    AppLogger.debug(
      'Syncing standalone exercises from server',
      tag: 'StandaloneRepo',
    );

    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (muscleGroup != null) 'muscleGroup': muscleGroup.name.toUpperCase(),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneExercises,
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final response = StandaloneExerciseListResponse.fromJson(data);

          // Cache exercises locally
          _cacheExercises(response.exercises);

          AppLogger.info(
            'Synced ${response.exercises.length} standalone exercises',
            tag: 'StandaloneRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse exercises',
            tag: 'StandaloneRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse exercises: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Create a personal exercise.
  ///
  /// Saves locally first, then syncs to server.
  /// On server success, updates the local record with the remote ID.
  Future<Result<StandaloneExerciseModel, AppError>> createExercise(
    CreateStandaloneExerciseRequest request,
  ) async {
    AppLogger.debug('Creating standalone exercise', tag: 'StandaloneRepo');

    // 1. Save locally
    final localId = await _db.upsertExercise(
      ExercisesCompanion.insert(
        name: request.name,
        description: request.description,
        primaryMuscleGroup: request.primaryMuscleGroup.name.toUpperCase(),
        equipmentNeeded: Value(jsonEncode(request.equipmentNeeded)),
        isSynced: const Value(false),
      ),
    );

    // 2. Try server sync
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standaloneExercises,
      data: request.toJson(),
    );

    return result.when(
      success: (data) async {
        try {
          final exercise = StandaloneExerciseModel.fromJson(
            data['exercise'] as Map<String, dynamic>,
          );
          // Update local record with remote ID
          await _db.upsertExercise(
            ExercisesCompanion(
              id: Value(localId),
              remoteId: Value(exercise.id),
              isSynced: const Value(true),
            ),
          );
          AppLogger.info(
            'Created standalone exercise: ${exercise.name}',
            tag: 'StandaloneRepo',
          );
          return Success(exercise);
        } catch (e) {
          AppLogger.error(
            'Failed to parse created exercise',
            tag: 'StandaloneRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse exercise: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) async {
        // Queue for later sync
        await _db.addToSyncQueue(
          SyncQueueCompanion.insert(
            entityTable: 'standalone_exercises',
            recordId: localId.toString(),
            operation: 'create',
            payload: jsonEncode(request.toJson()),
          ),
        );
        AppLogger.warning(
          'Exercise saved locally, queued for sync',
          tag: 'StandaloneRepo',
        );
        // Return local model
        return Success(
          StandaloneExerciseModel(
            id: localId.toString(),
            name: request.name,
            description: request.description,
            primaryMuscleGroup: request.primaryMuscleGroup,
            equipmentNeeded: request.equipmentNeeded,
            isPublic: request.isPublic,
            createdAt: DateTime.now(),
          ),
        );
      },
    );
  }

  /// Update a personal exercise.
  Future<Result<StandaloneExerciseModel, AppError>> updateExercise({
    required String exerciseId,
    required UpdateStandaloneExerciseRequest request,
  }) async {
    AppLogger.debug(
      'Updating standalone exercise: $exerciseId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.standaloneExercises}/$exerciseId',
      data: request.toJson()..removeWhere((_, v) => v == null),
    );

    return result.when(
      success: (data) {
        try {
          final exercise = StandaloneExerciseModel.fromJson(
            data['exercise'] as Map<String, dynamic>,
          );
          AppLogger.info(
            'Updated standalone exercise: ${exercise.name}',
            tag: 'StandaloneRepo',
          );
          return Success(exercise);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse exercise: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Delete a personal exercise.
  Future<Result<void, AppError>> deleteExercise(String exerciseId) async {
    AppLogger.debug(
      'Deleting standalone exercise: $exerciseId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.standaloneExercises}/$exerciseId',
    );

    return result.when(
      success: (_) {
        AppLogger.info(
          'Deleted standalone exercise: $exerciseId',
          tag: 'StandaloneRepo',
        );
        return const Success(null);
      },
      failure: (error) => Failure(error),
    );
  }

  // ════════════════════════════════════════════════════════
  //  ROUTINE OPERATIONS
  // ════════════════════════════════════════════════════════

  /// Get routines from local database.
  Future<Result<List<RoutineModel>, AppError>> getRoutinesLocal() async {
    try {
      AppLogger.debug(
        'Fetching standalone routines from local DB',
        tag: 'StandaloneRepo',
      );
      final routines = await _db.getAllRoutines();
      final routineModels = <RoutineModel>[];

      for (final routine in routines) {
        final exercises = await _db.getRoutineExercises(routine.id);
        routineModels.add(
          RoutineModel(
            id: routine.remoteId ?? routine.id.toString(),
            name: routine.name,
            description: routine.description,
            estimatedDurationMinutes: routine.estimatedDurationMinutes,
            muscleGroupsTargeted: _parseMuscleGroups(
              routine.muscleGroupsTargeted,
            ),
            exercises: await _mapRoutineExercises(exercises),
            createdAt: routine.createdAt,
            updatedAt: routine.updatedAt,
          ),
        );
      }

      return Success(routineModels);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch routines from local DB',
        tag: 'StandaloneRepo',
        error: e,
      );
      return Failure(DatabaseError(message: 'Failed to load routines: $e'));
    }
  }

  /// Sync user's routines from server (paginated).
  Future<Result<StandaloneRoutineListResponse, AppError>> syncRoutines({
    int limit = 50,
    int offset = 0,
  }) async {
    AppLogger.debug(
      'Syncing standalone routines from server',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneRoutines,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.when(
      success: (data) {
        try {
          final response = StandaloneRoutineListResponse.fromJson(data);
          AppLogger.info(
            'Synced ${response.routines.length} standalone routines',
            tag: 'StandaloneRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse routines',
            tag: 'StandaloneRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse routines: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Get a single routine detail with exercises.
  Future<Result<RoutineModel, AppError>> getRoutineDetail(
    String routineId,
  ) async {
    AppLogger.debug(
      'Fetching routine detail: $routineId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standaloneRoutines}/$routineId',
    );

    return result.when(
      success: (data) {
        try {
          final routine = RoutineModel.fromJson(
            data['routine'] as Map<String, dynamic>,
          );

          // Cache locally
          _cacheRoutine(routine);

          return Success(routine);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse routine: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Create a personal routine.
  Future<Result<RoutineModel, AppError>> createRoutine(
    CreateStandaloneRoutineRequest request,
  ) async {
    AppLogger.debug('Creating standalone routine', tag: 'StandaloneRepo');

    // 1. Save locally first
    final localId = await _db.upsertRoutine(
      RoutinesCompanion.insert(
        name: request.name,
        description: request.description,
        estimatedDurationMinutes: request.estimatedDurationMinutes,
        muscleGroupsTargeted: Value(
          jsonEncode(request.muscleGroupsTargeted.map((m) => m.name).toList()),
        ),
        isSynced: const Value(false),
      ),
    );

    // 2. Try server sync
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standaloneRoutines,
      data: request.toJson(),
    );

    return result.when(
      success: (data) async {
        try {
          final routine = RoutineModel.fromJson(
            data['routine'] as Map<String, dynamic>,
          );
          await _db.upsertRoutine(
            RoutinesCompanion(
              id: Value(localId),
              remoteId: Value(routine.id),
              isSynced: const Value(true),
            ),
          );
          AppLogger.info(
            'Created standalone routine: ${routine.name}',
            tag: 'StandaloneRepo',
          );
          return Success(routine);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse routine: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) async {
        await _db.addToSyncQueue(
          SyncQueueCompanion.insert(
            entityTable: 'standalone_routines',
            recordId: localId.toString(),
            operation: 'create',
            payload: jsonEncode(request.toJson()),
          ),
        );
        return Success(
          RoutineModel(
            id: localId.toString(),
            name: request.name,
            description: request.description,
            estimatedDurationMinutes: request.estimatedDurationMinutes,
            muscleGroupsTargeted: request.muscleGroupsTargeted,
            createdAt: DateTime.now(),
          ),
        );
      },
    );
  }

  /// Update a personal routine.
  Future<Result<RoutineModel, AppError>> updateRoutine({
    required String routineId,
    required UpdateStandaloneRoutineRequest request,
  }) async {
    AppLogger.debug(
      'Updating standalone routine: $routineId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.standaloneRoutines}/$routineId',
      data: request.toJson()..removeWhere((_, v) => v == null),
    );

    return result.when(
      success: (data) {
        try {
          final routine = RoutineModel.fromJson(
            data['routine'] as Map<String, dynamic>,
          );
          AppLogger.info(
            'Updated standalone routine: ${routine.name}',
            tag: 'StandaloneRepo',
          );
          return Success(routine);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse routine: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Delete a personal routine.
  Future<Result<void, AppError>> deleteRoutine(String routineId) async {
    AppLogger.debug(
      'Deleting standalone routine: $routineId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.standaloneRoutines}/$routineId',
    );

    return result.when(
      success: (_) {
        AppLogger.info(
          'Deleted standalone routine: $routineId',
          tag: 'StandaloneRepo',
        );
        return const Success(null);
      },
      failure: (error) => Failure(error),
    );
  }

  // ── Routine Exercise Junction ──────────────────────────

  /// Add an exercise to a routine.
  Future<Result<RoutineExerciseModel, AppError>> addRoutineExercise({
    required String routineId,
    required AddStandaloneRoutineExerciseRequest request,
  }) async {
    AppLogger.debug(
      'Adding exercise to routine: $routineId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standaloneRoutines}/$routineId/exercises',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        try {
          final re = RoutineExerciseModel.fromJson(
            data['routineExercise'] as Map<String, dynamic>,
          );
          return Success(re);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse routine exercise: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Update an exercise prescription in a routine.
  Future<Result<RoutineExerciseModel, AppError>> updateRoutineExercise({
    required String routineId,
    required String routineExerciseId,
    required UpdateStandaloneRoutineExerciseRequest request,
  }) async {
    AppLogger.debug(
      'Updating routine exercise: $routineExerciseId in $routineId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.standaloneRoutines}/$routineId/exercises/$routineExerciseId',
      data: request.toJson()..removeWhere((_, v) => v == null),
    );

    return result.when(
      success: (data) {
        try {
          final re = RoutineExerciseModel.fromJson(
            data['routineExercise'] as Map<String, dynamic>,
          );
          return Success(re);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse routine exercise: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Remove an exercise from a routine.
  Future<Result<void, AppError>> removeRoutineExercise({
    required String routineId,
    required String routineExerciseId,
  }) async {
    AppLogger.debug(
      'Removing exercise $routineExerciseId from routine $routineId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.standaloneRoutines}/$routineId/exercises/$routineExerciseId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) => Failure(error),
    );
  }

  // ════════════════════════════════════════════════════════
  //  PROGRAM OPERATIONS
  // ════════════════════════════════════════════════════════

  /// Get programs from local database.
  Future<Result<List<StandaloneProgramSummaryModel>, AppError>>
  getProgramsLocal(String userId) async {
    try {
      AppLogger.debug(
        'Fetching standalone programs from local DB',
        tag: 'StandaloneRepo',
      );
      final programs = await _db.getStandalonePrograms(userId);
      return Success(
        programs
            .map(
              (p) => StandaloneProgramSummaryModel(
                id: p.remoteId ?? p.id.toString(),
                name: p.name,
                description: p.description,
                userId: p.userId,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt,
              ),
            )
            .toList(),
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch programs from local DB',
        tag: 'StandaloneRepo',
        error: e,
      );
      return Failure(DatabaseError(message: 'Failed to load programs: $e'));
    }
  }

  /// Sync programs from server (paginated).
  Future<Result<StandaloneProgramListResponse, AppError>> syncPrograms({
    int limit = 50,
    int offset = 0,
  }) async {
    AppLogger.debug(
      'Syncing standalone programs from server',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standalonePrograms,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.when(
      success: (data) {
        try {
          final response = StandaloneProgramListResponse.fromJson(data);

          // Cache programs locally
          _cachePrograms(response.programs);

          AppLogger.info(
            'Synced ${response.programs.length} standalone programs',
            tag: 'StandaloneRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse programs',
            tag: 'StandaloneRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse programs: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Get full program detail with routine tree.
  Future<Result<StandaloneProgramDetailModel, AppError>> getProgramDetail(
    String programId,
  ) async {
    AppLogger.debug(
      'Fetching program detail: $programId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId',
    );

    return result.when(
      success: (data) {
        try {
          final program = StandaloneProgramDetailModel.fromJson(
            data['program'] as Map<String, dynamic>,
          );
          return Success(program);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse program: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Create a personal program.
  Future<Result<StandaloneProgramSummaryModel, AppError>> createProgram(
    CreateStandaloneProgramRequest request, {
    required String userId,
  }) async {
    AppLogger.debug('Creating standalone program', tag: 'StandaloneRepo');

    // 1. Save locally
    final localId = await _db.upsertStandaloneProgram(
      StandaloneProgramsCompanion.insert(
        userId: userId,
        name: request.name,
        description: request.description,
        isSynced: const Value(false),
      ),
    );

    // 2. Try server sync
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standalonePrograms,
      data: request.toJson(),
    );

    return result.when(
      success: (data) async {
        try {
          final program = StandaloneProgramSummaryModel.fromJson(
            data['program'] as Map<String, dynamic>,
          );
          await _db.upsertStandaloneProgram(
            StandaloneProgramsCompanion(
              id: Value(localId),
              remoteId: Value(program.id),
              isSynced: const Value(true),
            ),
          );
          AppLogger.info(
            'Created standalone program: ${program.name}',
            tag: 'StandaloneRepo',
          );
          return Success(program);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse program: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) async {
        await _db.addToSyncQueue(
          SyncQueueCompanion.insert(
            entityTable: 'standalone_programs',
            recordId: localId.toString(),
            operation: 'create',
            payload: jsonEncode(request.toJson()),
          ),
        );
        return Success(
          StandaloneProgramSummaryModel(
            id: localId.toString(),
            name: request.name,
            description: request.description,
            userId: userId,
            createdAt: DateTime.now(),
          ),
        );
      },
    );
  }

  /// Update a personal program.
  Future<Result<StandaloneProgramSummaryModel, AppError>> updateProgram({
    required String programId,
    required UpdateStandaloneProgramRequest request,
  }) async {
    AppLogger.debug(
      'Updating standalone program: $programId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId',
      data: request.toJson()..removeWhere((_, v) => v == null),
    );

    return result.when(
      success: (data) {
        try {
          final program = StandaloneProgramSummaryModel.fromJson(
            data['program'] as Map<String, dynamic>,
          );
          AppLogger.info(
            'Updated standalone program: ${program.name}',
            tag: 'StandaloneRepo',
          );
          return Success(program);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse program: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Delete a personal program.
  Future<Result<void, AppError>> deleteProgram(String programId) async {
    AppLogger.debug(
      'Deleting standalone program: $programId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId',
    );

    return result.when(
      success: (_) {
        AppLogger.info(
          'Deleted standalone program: $programId',
          tag: 'StandaloneRepo',
        );
        return const Success(null);
      },
      failure: (error) => Failure(error),
    );
  }

  // ── ProgramRoutine Junction ────────────────────────────

  /// Assign a routine to a program day.
  Future<Result<StandaloneProgramRoutineModel, AppError>> assignRoutine({
    required String programId,
    required AssignStandaloneRoutineRequest request,
  }) async {
    AppLogger.debug(
      'Assigning routine to program: $programId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId/routines',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        try {
          final pr = StandaloneProgramRoutineModel.fromJson(
            data['programRoutine'] as Map<String, dynamic>,
          );
          return Success(pr);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse program routine: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Update a program-routine day number.
  Future<Result<StandaloneProgramRoutineModel, AppError>> updateProgramRoutine({
    required String programId,
    required String programRoutineId,
    required UpdateStandaloneProgramRoutineRequest request,
  }) async {
    AppLogger.debug(
      'Updating program routine: $programRoutineId in $programId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId/routines/$programRoutineId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        try {
          final pr = StandaloneProgramRoutineModel.fromJson(
            data['programRoutine'] as Map<String, dynamic>,
          );
          return Success(pr);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse program routine: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Remove a routine from a program.
  Future<Result<void, AppError>> removeProgramRoutine({
    required String programId,
    required String programRoutineId,
  }) async {
    AppLogger.debug(
      'Removing routine $programRoutineId from program $programId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId/routines/$programRoutineId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) => Failure(error),
    );
  }

  // ════════════════════════════════════════════════════════
  //  SELF-ASSIGNMENT (ACTIVATE / DEACTIVATE)
  // ════════════════════════════════════════════════════════

  /// Activate a personal program (self-assign).
  ///
  /// Deactivates any currently active standalone assignment first.
  Future<Result<StandaloneAssignedProgramModel, AppError>> activateProgram({
    required String programId,
    ActivateStandaloneProgramRequest? request,
  }) async {
    AppLogger.debug(
      'Activating standalone program: $programId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId/activate',
      data: request?.toJson() ?? {},
    );

    return result.when(
      success: (data) {
        try {
          final assignment = StandaloneAssignedProgramModel.fromJson(
            data['assignment'] as Map<String, dynamic>,
          );
          AppLogger.info(
            'Activated standalone program: $programId',
            tag: 'StandaloneRepo',
          );
          return Success(assignment);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse assignment: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Deactivate a personal program.
  Future<Result<StandaloneAssignedProgramModel, AppError>> deactivateProgram(
    String programId,
  ) async {
    AppLogger.debug(
      'Deactivating standalone program: $programId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId/deactivate',
    );

    return result.when(
      success: (data) {
        try {
          final assignment = StandaloneAssignedProgramModel.fromJson(
            data['assignment'] as Map<String, dynamic>,
          );
          AppLogger.info(
            'Deactivated standalone program: $programId',
            tag: 'StandaloneRepo',
          );
          return Success(assignment);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse assignment: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Get the currently active standalone program assignment.
  Future<Result<StandaloneAssignedProgramModel?, AppError>>
  getActiveProgram() async {
    AppLogger.debug(
      'Fetching active standalone program',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneActiveProgram,
    );

    return result.when(
      success: (data) {
        try {
          final assignmentJson = data['assignment'];
          if (assignmentJson == null) return const Success(null);
          final assignment = StandaloneAssignedProgramModel.fromJson(
            assignmentJson as Map<String, dynamic>,
          );
          return Success(assignment);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse active program: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        // 404 means no active program — not an error
        if (error is NetworkError && error.statusCode == 404) {
          return const Success(null);
        }
        return Failure(error);
      },
    );
  }

  // ════════════════════════════════════════════════════════
  //  TODAY'S WORKOUT (Server-Only)
  // ════════════════════════════════════════════════════════

  /// Resolve today's routine from the active standalone program.
  ///
  /// Server-only operation — no local caching (depends on server-side
  /// day-cycling logic).
  Future<Result<StandaloneTodayModel, AppError>> getTodayRoutine({
    String? assignedProgramId,
  }) async {
    AppLogger.debug('Fetching standalone today routine', tag: 'StandaloneRepo');

    final queryParams = <String, dynamic>{
      if (assignedProgramId != null) 'assignedProgramId': assignedProgramId,
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneToday,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return result.when(
      success: (data) async {
        try {
          // ── Debug: log raw data shape ──
          AppLogger.debug(
            'Raw data keys: ${data.keys.toList()}',
            tag: 'StandaloneRepo',
          );

          // ── 1. Extract today list ──
          final todayRaw = data['today'];
          AppLogger.debug(
            'today type: ${todayRaw.runtimeType}',
            tag: 'StandaloneRepo',
          );

          // Defensive: unwrap if server ever sends a bare Map instead of List
          final todayList = todayRaw is List<dynamic>
              ? todayRaw
              : todayRaw != null
                  ? [todayRaw]
                  : null;

          final isRestDay = data['is_rest_day'] as bool? ?? false;
          if (isRestDay || todayList == null || todayList.isEmpty) {
            return Success(const StandaloneTodayModel(isRestDay: true));
          }

          // ── 2. Extract routine map ──
          final firstItem = todayList.first;
          AppLogger.debug(
            'firstItem type: ${firstItem.runtimeType}',
            tag: 'StandaloneRepo',
          );
          if (firstItem is! Map<String, dynamic>) {
            return Failure(
              UnknownError(
                message:
                    'Expected today[0] to be Map<String,dynamic>, '
                    'got ${firstItem.runtimeType}',
              ),
            );
          }
          final routineJson = Map<String, dynamic>.from(firstItem);

          // ── 3. Map fields ──
          final daysOfWeek = routineJson['days_of_week'];
          AppLogger.debug(
            'days_of_week type: ${daysOfWeek.runtimeType}',
            tag: 'StandaloneRepo',
          );
          final dayOfWeek = (daysOfWeek is List && daysOfWeek.isNotEmpty)
              ? daysOfWeek.first.toString()
              : _todayDayOfWeek();

          // Rename exercises key
          if (!routineJson.containsKey('exercises')) {
            final rawExercises = routineJson['assigned_program_routine_exercises'];
            AppLogger.debug(
              'raw exercises type: ${rawExercises.runtimeType}',
              tag: 'StandaloneRepo',
            );
            routineJson['exercises'] = rawExercises ?? const [];
          }

          // ── 4. Parse routine ──
          AppLogger.debug(
            'About to call RoutineModel.fromJson',
            tag: 'StandaloneRepo',
          );
          final routine = RoutineModel.fromJson(routineJson);

          // ── 5. Enrich exercises from local DB ──
          final enrichedExercises = await Future.wait(
            routine.exercises.map((re) async {
              final dbExercise = await _findExerciseByRemoteId(re.exerciseId);
              if (dbExercise == null) return re;
              final exerciseModel = _driftExerciseToModel(dbExercise);
              return re.copyWith(exercise: exerciseModel);
            }),
          );
          final enrichedRoutine = routine.copyWith(exercises: enrichedExercises);

          // ── 6. Build model ──
          final model = StandaloneTodayModel(
            isRestDay: false,
            today: StandaloneTodayDetails(
              programRoutineId: routineJson['id'] as String,
              dayOfWeek: dayOfWeek,
              assignedProgramId:
                  routineJson['assigned_program_id'] as String? ?? '',
              programName: routineJson['name'] as String? ?? '',
              routine: enrichedRoutine,
            ),
          );

          AppLogger.info(
            'Standalone today parsed OK: ${model.today?.routine.name}',
            tag: 'StandaloneRepo',
          );
          return Success(model);
        } catch (e, stackTrace) {
          AppLogger.error(
            'Parse error in getTodayRoutine: $e',
            tag: 'StandaloneRepo',
            error: e,
          );
          AppLogger.debug('Stack: $stackTrace', tag: 'StandaloneRepo');
          return Failure(
            UnknownError(
              message: 'Failed to parse today routine: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        // 404 means no active program — wrap as a valid "no program" state
        if (error is NetworkError && error.statusCode == 404) {
          return const Success(
            StandaloneTodayModel(
              message: 'No active standalone program assigned',
            ),
          );
        }
        return Failure(error);
      },
    );
  }

  // ════════════════════════════════════════════════════════
  //  SESSION OPERATIONS
  // ════════════════════════════════════════════════════════

  /// Start a standalone workout session.
  ///
  /// Creates the session on the server. Returns 409 if a session
  /// is already in progress.
  Future<Result<WorkoutSessionModel, AppError>> startSession({
    required String userId,
    String? assignedProgramId,
  }) async {
    AppLogger.debug('Starting standalone session', tag: 'StandaloneRepo');

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standaloneSessions,
      data: {
        if (assignedProgramId != null) 'assigned_program_routine_id': assignedProgramId,
      },
    );

    return result.when(
      success: (data) async {
        try {
          final sessionJson = data['session'] as Map<String, dynamic>;
          final session = _parseWorkoutSessionModel(sessionJson);

          // Persist to local DB so set-logging can resolve the session
          await _db.startWorkoutSession(
            WorkoutSessionsCompanion.insert(
              userId: userId,
              remoteId: Value(session.id),
              assignedProgramRoutineId: Value(session.assignedProgramRoutineId),
              startedAt: session.startedAt,
              isSynced: const Value(true),
            ),
          );
          AppLogger.info(
            'Standalone session started: ${session.id}',
            tag: 'StandaloneRepo',
          );
          return Success(session);
        } catch (e, st) {
          AppLogger.error(
            'Failed to parse or persist standalone session',
            tag: 'StandaloneRepo',
            error: e,
            stackTrace: st,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse session: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Get the currently active standalone session.
  Future<Result<WorkoutSessionModel?, AppError>> getActiveSession() async {
    AppLogger.debug(
      'Fetching active standalone session',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneActiveSession,
    );

    return result.when(
      success: (data) {
        try {
          final sessionJson = data['session'];
          if (sessionJson == null) return const Success(null);
          final session = _parseWorkoutSessionModel(
            sessionJson as Map<String, dynamic>,
          );
          return Success(session);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse session: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        if (error is NetworkError && error.statusCode == 404) {
          return const Success(null);
        }
        return Failure(error);
      },
    );
  }

  /// Get standalone session detail with performed sets.
  Future<Result<WorkoutSessionModel, AppError>> getSessionDetail(
    String sessionId,
  ) async {
    AppLogger.debug(
      'Fetching session detail: $sessionId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standaloneSessions}/$sessionId',
    );

    return result.when(
      success: (data) {
        try {
          final session = _parseWorkoutSessionModel(
            data['session'] as Map<String, dynamic>,
          );
          return Success(session);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse session: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Parses a server session response handling both snake_case and camelCase.
  WorkoutSessionModel _parseWorkoutSessionModel(
    Map<String, dynamic> json,
  ) {
    final String id = json['id'] as String;
    final String userId =
        (json['user_id'] ?? json['userId'] ?? '') as String;
    final String? assignedProgramRoutineId =
        (json['assigned_program_routine_id'] ?? json['assignedProgramRoutineId'])
            as String?;
    final DateTime startedAt =
        DateTime.parse((json['started_at'] ?? json['startedAt']) as String);
    final DateTime? completedAt = json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String)
        : json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null;
    final String? notes = (json['notes'] ?? json['notes']) as String?;
    final DateTime? createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null;
    final DateTime? updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null;

    return WorkoutSessionModel(
      id: id,
      userId: userId,
      assignedProgramRoutineId: assignedProgramRoutineId,
      startedAt: startedAt,
      completedAt: completedAt,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// List past standalone sessions (paginated).
  Future<Result<StandaloneSessionListResponse, AppError>> getSessionHistory({
    int limit = 20,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.debug(
      'Fetching standalone session history: limit=$limit, offset=$offset',
      tag: 'StandaloneRepo',
    );

    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneSessions,
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final response = StandaloneSessionListResponse.fromJson(data);
          AppLogger.info(
            'Fetched ${response.sessions.length} standalone sessions',
            tag: 'StandaloneRepo',
          );
          return Success(response);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse session history: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Complete a standalone session.
  Future<Result<WorkoutSessionModel, AppError>> completeSession({
    required String sessionId,
    String? notes,
  }) async {
    AppLogger.debug(
      'Completing standalone session: $sessionId',
      tag: 'StandaloneRepo',
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standaloneSessions}/$sessionId/complete',
      data: {if (notes != null) 'notes': notes},
    );

    return result.when(
      success: (data) {
        try {
          final session = _parseWorkoutSessionModel(
            data['session'] as Map<String, dynamic>,
          );
          AppLogger.info(
            'Standalone session completed: ${session.id}',
            tag: 'StandaloneRepo',
          );
          return Success(session);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse session: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  // ════════════════════════════════════════════════════════
  //  WEEKLY STATS (Server-Only)
  // ════════════════════════════════════════════════════════

  /// Fetch aggregated weekly workout statistics.
  ///
  /// Server-only — always fresh from the server.
  Future<Result<WeeklyStatsModel, AppError>> getWeeklyStats({
    DateTime? weekOf,
  }) async {
    AppLogger.debug('Fetching standalone weekly stats', tag: 'StandaloneRepo');

    final queryParams = <String, dynamic>{
      if (weekOf != null) 'weekOf': weekOf.toIso8601String(),
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneWeeklyStats,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return result.when(
      success: (data) {
        try {
          final statsJson = data['stats'] as Map<String, dynamic>;
          final model = WeeklyStatsModel.fromJson(statsJson);
          AppLogger.info(
            'Standalone weekly stats: ${model.workoutsCompleted} workouts, '
            '${model.totalMinutes}min, ${model.streakDays} streak',
            tag: 'StandaloneRepo',
          );
          return Success(model);
        } catch (e) {
          return Failure(
            UnknownError(
              message: 'Failed to parse weekly stats: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  // ════════════════════════════════════════════════════════
  //  PRIVATE HELPERS — Local Caching & Mapping
  // ════════════════════════════════════════════════════════

  /// Cache exercises in the local Drift database.
  Future<void> _cacheExercises(List<StandaloneExerciseModel> exercises) async {
    try {
      await _db.insertExercises(
        exercises
            .map(
              (e) => ExercisesCompanion.insert(
                remoteId: Value(e.id),
                name: e.name,
                description: e.description,
                primaryMuscleGroup: e.primaryMuscleGroup.name.toUpperCase(),
                equipmentNeeded: Value(jsonEncode(e.equipmentNeeded)),
                isSynced: const Value(true),
              ),
            )
            .toList(),
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to cache exercises locally: $e',
        tag: 'StandaloneRepo',
      );
    }
  }

  /// Cache a single routine (with exercises) in the local Drift database.
  Future<void> _cacheRoutine(RoutineModel routine) async {
    try {
      final routineId = await _db.upsertRoutine(
        RoutinesCompanion.insert(
          remoteId: Value(routine.id),
          name: routine.name,
          description: routine.description,
          estimatedDurationMinutes: routine.estimatedDurationMinutes,
          muscleGroupsTargeted: Value(
            jsonEncode(
              routine.muscleGroupsTargeted.map((m) => m.name).toList(),
            ),
          ),
          isSynced: const Value(true),
        ),
      );

      for (final exercise in routine.exercises) {
        // Ensure exercise exists locally
        if (exercise.exercise != null) {
          await _db.upsertExercise(
            ExercisesCompanion.insert(
              remoteId: Value(exercise.exercise!.id),
              name: exercise.exercise!.name,
              description: exercise.exercise!.description,
              primaryMuscleGroup: exercise.exercise!.primaryMuscleGroup.name
                  .toUpperCase(),
              equipmentNeeded: Value(
                jsonEncode(exercise.exercise!.equipmentNeeded),
              ),
              isSynced: const Value(true),
            ),
          );
        }

        // Find local exercise ID
        final localExercise = exercise.exercise != null
            ? await _findExerciseByRemoteId(exercise.exercise!.id)
            : null;

        if (localExercise != null) {
          await _db.upsertRoutineExercise(
            RoutineExercisesCompanion.insert(
              remoteId: Value(exercise.id),
              routineId: routineId,
              exerciseId: localExercise.id,
              sets: exercise.sets,
              repsMin: exercise.repsMin,
              repsMax: exercise.repsMax,
              restSeconds: exercise.restSeconds,
              orderInRoutine: exercise.orderInRoutine,
              notes: Value(exercise.notes),
              isSynced: const Value(true),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to cache routine locally: $e',
        tag: 'StandaloneRepo',
      );
    }
  }

  /// Cache programs in the local Drift database.
  Future<void> _cachePrograms(
    List<StandaloneProgramSummaryModel> programs,
  ) async {
    try {
      for (final program in programs) {
        await _db.upsertStandaloneProgram(
          StandaloneProgramsCompanion.insert(
            remoteId: Value(program.id),
            userId: program.userId ?? '',
            name: program.name,
            description: program.description,
            isSynced: const Value(true),
          ),
        );
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to cache programs locally: $e',
        tag: 'StandaloneRepo',
      );
    }
  }

  /// Find exercise by remote ID.
  Future<Exercise?> _findExerciseByRemoteId(String remoteId) async {
    final exercises = await _db.getAllExercises();
    try {
      return exercises.firstWhere((e) => e.remoteId == remoteId);
    } catch (_) {
      return null;
    }
  }

  /// Map Drift RoutineExercise rows to RoutineExerciseModel list.
  Future<List<RoutineExerciseModel>> _mapRoutineExercises(
    List<RoutineExercise> exercises,
  ) async {
    final models = <RoutineExerciseModel>[];
    for (final re in exercises) {
      final exercise = await _db.getExerciseById(re.exerciseId);
      models.add(
        RoutineExerciseModel(
          id: re.remoteId ?? re.id.toString(),
          routineId: re.routineId.toString(),
          exerciseId: exercise?.remoteId ?? re.exerciseId.toString(),
          sets: re.sets,
          repsMin: re.repsMin,
          repsMax: re.repsMax,
          restSeconds: re.restSeconds,
          orderInRoutine: re.orderInRoutine,
          notes: re.notes,
          exercise: exercise != null
              ? ExerciseModel(
                  id: exercise.remoteId ?? exercise.id.toString(),
                  name: exercise.name,
                  description: exercise.description,
                  primaryMuscleGroup: _parseMuscleGroup(
                    exercise.primaryMuscleGroup,
                  ),
                  equipmentNeeded: _parseJsonList(exercise.equipmentNeeded),
                )
              : null,
          createdAt: re.createdAt,
          updatedAt: re.updatedAt,
        ),
      );
    }
    return models;
  }

  MuscleGroup _parseMuscleGroup(String value) {
    try {
      return MuscleGroup.values.firstWhere(
        (mg) => mg.name.toUpperCase() == value.toUpperCase(),
        orElse: () => MuscleGroup.chest,
      );
    } catch (_) {
      return MuscleGroup.chest;
    }
  }

  List<MuscleGroup> _parseMuscleGroups(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => _parseMuscleGroup(e.toString())).toList();
    } catch (_) {
      return [];
    }
  }

  List<String> _parseJsonList(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Convert a Drift [Exercise] row into a domain [ExerciseModel].
  ExerciseModel _driftExerciseToModel(Exercise e) {
    MuscleGroup muscleGroup;
    try {
      muscleGroup = MuscleGroup.values.firstWhere(
        (mg) => mg.name.toUpperCase() == e.primaryMuscleGroup.toUpperCase(),
        orElse: () => MuscleGroup.chest,
      );
    } catch (_) {
      muscleGroup = MuscleGroup.chest;
    }

    List<String> equipment;
    try {
      equipment = (jsonDecode(e.equipmentNeeded) as List)
          .map((item) => item.toString())
          .toList();
    } catch (_) {
      equipment = [];
    }

    return ExerciseModel(
      id: e.remoteId ?? e.id.toString(),
      name: e.name,
      description: e.description,
      primaryMuscleGroup: muscleGroup,
      equipmentNeeded: equipment,
    );
  }

  /// Current day of week as a server-style string (e.g. 'MONDAY').
  String _todayDayOfWeek() {
    const days = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
      'FRIDAY', 'SATURDAY', 'SUNDAY',
    ];
    return days[DateTime.now().weekday - 1];
  }
}

/// Provider for StandaloneWorkoutRepository
@Riverpod(keepAlive: true)
StandaloneWorkoutRepository standaloneWorkoutRepository(Ref ref) {
  return StandaloneWorkoutRepository(
    database: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
  );
}
