import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/database/app_database.dart';
import 'models/models.dart';

part 'workout_repository.g.dart';

/// Workout Repository

/// Handles all workout-related data operations.
/// Implements offline-first patterns:
/// - Local database (Drift) for offline access
/// - API client for server sync
/// - Sync queue for pending changes

class WorkoutRepository {
  WorkoutRepository({
    required AppDatabase database,
    required ApiClient apiClient,
  }) : _db = database,
       _apiClient = apiClient;

  final AppDatabase _db;
  final ApiClient _apiClient;

  // ============== Exercise Operations ==============

  /// Get all exercises from local database
  Future<Result<List<ExerciseModel>, AppError>> getExercises() async {
    try {
      AppLogger.debug('Fetching exercises from local DB', tag: 'WorkoutRepo');
      final exercises = await _db.getAllExercises();

      return Success(
        exercises
            .map(
              (e) => ExerciseModel(
                id: e.remoteId ?? e.id.toString(),
                name: e.name,
                description: e.description,
                primaryMuscleGroup: _parseMuscleGroup(e.primaryMuscleGroup),
                equipmentNeeded: _parseJsonList(e.equipmentNeeded),
                createdAt: e.createdAt,
                updatedAt: e.updatedAt,
              ),
            )
            .toList(),
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch exercises',
        tag: 'WorkoutRepo',
        error: e,
      );
      return Failure(DatabaseError(message: 'Failed to load exercises: $e'));
    }
  }

  /// Sync exercises from server
  Future<Result<List<ExerciseModel>, AppError>> syncExercises() async {
    AppLogger.debug('Syncing exercises from server', tag: 'WorkoutRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.exercises,
    );

    return result.when(
      success: (data) async {
        try {
          final exercisesList = (data['exercises'] as List)
              .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList();

          // Save to local database
          await _db.insertExercises(
            exercisesList
                .map(
                  (e) => ExercisesCompanion.insert(
                    remoteId: Value(e.id),
                    name: e.name,
                    description: e.description,
                    primaryMuscleGroup: e.primaryMuscleGroup.name,
                    equipmentNeeded: Value(jsonEncode(e.equipmentNeeded)),
                    isSynced: const Value(true),
                  ),
                )
                .toList(),
          );

          AppLogger.info(
            'Synced ${exercisesList.length} exercises',
            tag: 'WorkoutRepo',
          );
          return Success(exercisesList);
        } catch (e) {
          AppLogger.error(
            'Failed to parse exercises',
            tag: 'WorkoutRepo',
            error: e,
          );
          return Failure(
            DatabaseError(message: 'Failed to parse exercises: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  // ============== Routine Operations ==============

  /// Sync routines from server (fetches user's assigned routines)
  Future<Result<List<RoutineModel>, AppError>> syncRoutines() async {
    AppLogger.debug('Syncing routines from server', tag: 'WorkoutRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.routines,
    );

    return result.when(
      success: (data) async {
        try {
          final routinesList = <RoutineModel>[];
          final routinesJson = data['routines'] as List;

          for (final routineJson in routinesJson) {
            try {
              final routine = RoutineModel.fromJson(
                routineJson as Map<String, dynamic>,
              );
              routinesList.add(routine);
            } catch (e) {
              AppLogger.error(
                'Failed to parse individual routine',
                tag: 'WorkoutRepo',
                error: e,
              );
              AppLogger.debug('Routine JSON: $routineJson', tag: 'WorkoutRepo');
              // Continue processing other routines
              continue;
            }
          }

          // Clear all existing routines before syncing new ones
          // This ensures we don't keep old/unassigned routines
          await _db.deleteAllRoutines();
          AppLogger.debug(
            'Cleared existing routines from local DB',
            tag: 'WorkoutRepo',
          );

          // Save routines to local database
          for (final routine in routinesList) {
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

            // Save routine exercises
            for (final exercise in routine.exercises) {
              // Ensure exercise exists locally
              if (exercise.exercise != null) {
                await _db.upsertExercise(
                  ExercisesCompanion.insert(
                    remoteId: Value(exercise.exercise!.id),
                    name: exercise.exercise!.name,
                    description: exercise.exercise!.description,
                    primaryMuscleGroup:
                        exercise.exercise!.primaryMuscleGroup.name,
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
          }

          AppLogger.info(
            'Synced ${routinesList.length} routines',
            tag: 'WorkoutRepo',
          );
          return Success(routinesList);
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to parse routines',
            tag: 'WorkoutRepo',
            error: e,
          );
          AppLogger.debug('Stack trace: $stackTrace', tag: 'WorkoutRepo');
          return Failure(
            DatabaseError(message: 'Failed to parse routines: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Find exercise by remote ID
  Future<Exercise?> _findExerciseByRemoteId(String remoteId) async {
    final exercises = await _db.getAllExercises();
    try {
      return exercises.firstWhere((e) => e.remoteId == remoteId);
    } catch (_) {
      return null;
    }
  }

  /// Get all routines from local database
  Future<Result<List<RoutineModel>, AppError>> getRoutines() async {
    try {
      AppLogger.debug('Fetching routines from local DB', tag: 'WorkoutRepo');
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
      AppLogger.error('Failed to fetch routines', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load routines: $e'));
    }
  }

  /// Get routine by ID with exercises
  Future<Result<RoutineModel?, AppError>> getRoutineById(int id) async {
    try {
      final routine = await _db.getRoutineById(id);
      if (routine == null) return const Success(null);

      final exercises = await _db.getRoutineExercises(id);
      return Success(
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
    } catch (e) {
      AppLogger.error('Failed to fetch routine', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load routine: $e'));
    }
  }

  /// Get routine by model ID (remote CUID or local int string)
  Future<Result<RoutineModel?, AppError>> getRoutineByModelId(
    String modelId,
  ) async {
    try {
      final localId = await _resolveLocalRoutineId(modelId);
      if (localId == null) return const Success(null);
      return getRoutineById(localId);
    } catch (e) {
      AppLogger.error('Failed to fetch routine', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load routine: $e'));
    }
  }

  // ============== Workout Session Operations ==============

  /// Get active workout session for a user
  Future<Result<WorkoutSessionModel?, AppError>> getActiveSession(
    String userId,
  ) async {
    try {
      final session = await _db.getActiveWorkoutSession(userId);
      if (session == null) return const Success(null);

      final sets = await _db.getPerformedSets(session.id);
      return Success(await _mapWorkoutSession(session, sets));
    } catch (e) {
      AppLogger.error(
        'Failed to get active session',
        tag: 'WorkoutRepo',
        error: e,
      );
      return Failure(DatabaseError(message: 'Failed to get session: $e'));
    }
  }

  /// Resolve a RoutineModel.id (remote CUID or local int string) to the
  /// local auto-increment integer ID used by the Drift Routines table.
  Future<int?> _resolveLocalRoutineId(String modelId) async {
    // 1. Try parsing as local integer ID
    final localId = int.tryParse(modelId);
    if (localId != null) {
      final routine = await _db.getRoutineById(localId);
      if (routine != null) return localId;
    }

    // 2. Fall back to looking up by remoteId
    final routine = await _db.getRoutineByRemoteId(modelId);
    return routine?.id;
  }

  /// Resolve a RoutineExerciseModel.id (remote CUID or local int string) to
  /// the local auto-increment integer ID used by the Drift RoutineExercises table.
  Future<int?> _resolveLocalRoutineExerciseId(String modelId) async {
    // 1. Try parsing as local integer ID
    final localId = int.tryParse(modelId);
    if (localId != null) {
      final re = await _db.getRoutineExerciseById(localId);
      if (re != null) return localId;
    }

    // 2. Fall back to looking up by remoteId
    final re = await _db.getRoutineExerciseByRemoteId(modelId);
    return re?.id;
  }

  /// Start a new workout session
  Future<Result<WorkoutSessionModel, AppError>> startWorkoutSession({
    required String userId,
    String? routineModelId,
    String? assignedProgramId,
  }) async {
    try {
      AppLogger.info('Starting workout session', tag: 'WorkoutRepo');

      // Resolve the routine model ID to the local DB integer ID
      int? localRoutineId;
      if (routineModelId != null) {
        localRoutineId = await _resolveLocalRoutineId(routineModelId);
        if (localRoutineId == null) {
          AppLogger.warning(
            'Could not resolve routine ID: $routineModelId',
            tag: 'WorkoutRepo',
          );
        }
      }

      final sessionId = await _db.startWorkoutSession(
        WorkoutSessionsCompanion.insert(
          userId: userId,
          routineId: Value(localRoutineId),
          assignedProgramId: Value(assignedProgramId),
          startedAt: DateTime.now(),
        ),
      );

      final session = await _db.getWorkoutSessionById(sessionId);
      if (session == null) {
        return const Failure(
          DatabaseError(message: 'Failed to create session'),
        );
      }

      AppLogger.info('Workout session started: $sessionId', tag: 'WorkoutRepo');
      return Success(await _mapWorkoutSession(session, []));
    } catch (e) {
      AppLogger.error('Failed to start session', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to start session: $e'));
    }
  }

  /// Get workout session by ID
  Future<Result<WorkoutSessionModel?, AppError>> getWorkoutSession(
    int sessionId,
  ) async {
    try {
      final session = await _db.getWorkoutSessionById(sessionId);
      if (session == null) return const Success(null);

      final sets = await _db.getPerformedSets(sessionId);
      return Success(await _mapWorkoutSession(session, sets));
    } catch (e) {
      AppLogger.error('Failed to get session', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to get session: $e'));
    }
  }

  /// Complete a workout session
  Future<Result<WorkoutSessionModel, AppError>> completeWorkoutSession({
    required int sessionId,
    String? notes,
  }) async {
    try {
      AppLogger.info(
        'Completing workout session: $sessionId',
        tag: 'WorkoutRepo',
      );

      await _db.completeWorkoutSession(sessionId, notes: notes);

      // Add to sync queue
      await _db.addToSyncQueue(
        SyncQueueCompanion.insert(
          entityTable: 'workout_sessions',
          recordId: sessionId.toString(),
          operation: 'complete',
          payload: jsonEncode({
            'sessionId': sessionId,
            'notes': notes,
            'completedAt': DateTime.now().toIso8601String(),
          }),
        ),
      );

      final session = await _db.getWorkoutSessionById(sessionId);
      final sets = await _db.getPerformedSets(sessionId);

      AppLogger.info('Workout session completed', tag: 'WorkoutRepo');
      return Success(await _mapWorkoutSession(session!, sets));
    } catch (e) {
      AppLogger.error(
        'Failed to complete session',
        tag: 'WorkoutRepo',
        error: e,
      );
      return Failure(DatabaseError(message: 'Failed to complete session: $e'));
    }
  }

  /// Get workout history for a user
  Future<Result<List<WorkoutSessionModel>, AppError>> getWorkoutHistory(
    String userId,
  ) async {
    try {
      final sessions = await _db.getWorkoutSessions(userId);
      final sessionModels = <WorkoutSessionModel>[];

      for (final session in sessions) {
        final sets = await _db.getPerformedSets(session.id);
        sessionModels.add(await _mapWorkoutSession(session, sets));
      }

      return Success(sessionModels);
    } catch (e) {
      AppLogger.error('Failed to get history', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load history: $e'));
    }
  }

  // ============== Performed Set Operations ==============

  /// Log a completed set
  Future<Result<PerformedSetModel, AppError>> logSet({
    required String workoutSessionModelId,
    required String routineExerciseModelId,
    required int setNumber,
    required int repsCompleted,
    double? weightKg,
    int? rpe,
    String? notes,
  }) async {
    try {
      // Resolve model IDs to local integer IDs
      final workoutSessionId = int.tryParse(workoutSessionModelId);
      if (workoutSessionId == null) {
        return Failure(
          DatabaseError(
            message: 'Invalid workout session ID: $workoutSessionModelId',
          ),
        );
      }

      final localRoutineExerciseId = await _resolveLocalRoutineExerciseId(
        routineExerciseModelId,
      );
      if (localRoutineExerciseId == null) {
        return Failure(
          DatabaseError(
            message:
                'Could not resolve routine exercise ID: $routineExerciseModelId',
          ),
        );
      }

      AppLogger.debug(
        'Logging set: session=$workoutSessionId, exercise=$localRoutineExerciseId '
        '(modelId=$routineExerciseModelId), '
        'set=$setNumber, reps=$repsCompleted, weight=$weightKg',
        tag: 'WorkoutRepo',
      );

      final setId = await _db.logSet(
        workoutSessionId: workoutSessionId,
        routineExerciseId: localRoutineExerciseId,
        setNumber: setNumber,
        repsCompleted: repsCompleted,
        weightKg: weightKg,
        rpe: rpe,
        notes: notes,
      );

      // Add to sync queue
      await _db.addToSyncQueue(
        SyncQueueCompanion.insert(
          entityTable: 'performed_sets',
          recordId: setId.toString(),
          operation: 'create',
          payload: jsonEncode({
            'workoutSessionId': workoutSessionId,
            'routineExerciseId': localRoutineExerciseId,
            'setNumber': setNumber,
            'repsCompleted': repsCompleted,
            'weightKg': weightKg,
            'rpe': rpe,
            'notes': notes,
          }),
        ),
      );

      return Success(
        PerformedSetModel(
          id: setId.toString(),
          workoutSessionId: workoutSessionId.toString(),
          routineExerciseId: routineExerciseModelId,
          setNumber: setNumber,
          repsCompleted: repsCompleted,
          weightKg: weightKg,
          rpe: rpe,
          notes: notes,
          isCompleted: true,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to log set', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to log set: $e'));
    }
  }

  /// Update an existing set
  Future<Result<PerformedSetModel, AppError>> updateSet({
    required int setId,
    int? repsCompleted,
    double? weightKg,
    int? rpe,
    String? notes,
    bool? isCompleted,
  }) async {
    try {
      await _db.updatePerformedSet(
        setId,
        PerformedSetsCompanion(
          repsCompleted: repsCompleted != null
              ? Value(repsCompleted)
              : const Value.absent(),
          weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
          rpe: rpe != null ? Value(rpe) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
          isCompleted: isCompleted != null
              ? Value(isCompleted)
              : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Add to sync queue
      await _db.addToSyncQueue(
        SyncQueueCompanion.insert(
          entityTable: 'performed_sets',
          recordId: setId.toString(),
          operation: 'update',
          payload: jsonEncode({
            'repsCompleted': repsCompleted,
            'weightKg': weightKg,
            'rpe': rpe,
            'notes': notes,
            'isCompleted': isCompleted,
          }),
        ),
      );

      return Success(
        PerformedSetModel(
          id: setId.toString(),
          workoutSessionId: '',
          routineExerciseId: '',
          setNumber: 0,
          repsCompleted: repsCompleted ?? 0,
          weightKg: weightKg,
          rpe: rpe,
          notes: notes,
          isCompleted: isCompleted ?? false,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to update set', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to update set: $e'));
    }
  }

  /// Delete a set
  Future<Result<void, AppError>> deleteSet(int setId) async {
    try {
      await _db.deletePerformedSet(setId);
      return const Success(null);
    } catch (e) {
      AppLogger.error('Failed to delete set', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to delete set: $e'));
    }
  }

  /// Get sets for a specific exercise in a session
  Future<Result<List<PerformedSetModel>, AppError>> getSetsForExercise({
    required int workoutSessionId,
    required int routineExerciseId,
  }) async {
    try {
      final sets = await _db.getPerformedSetsForExercise(
        workoutSessionId,
        routineExerciseId,
      );

      final mappedSets = <PerformedSetModel>[];
      for (final s in sets) {
        final re = await _db.getRoutineExerciseById(s.routineExerciseId);
        mappedSets.add(
          PerformedSetModel(
            id: s.remoteId ?? s.id.toString(),
            workoutSessionId: s.workoutSessionId.toString(),
            routineExerciseId: re?.remoteId ?? s.routineExerciseId.toString(),
            setNumber: s.setNumber,
            repsCompleted: s.repsCompleted,
            weightKg: s.weightKg,
            rpe: s.rpe,
            notes: s.notes,
            isCompleted: s.isCompleted,
            createdAt: s.createdAt,
            updatedAt: s.updatedAt,
          ),
        );
      }

      return Success(mappedSets);
    } catch (e) {
      AppLogger.error('Failed to get sets', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to get sets: $e'));
    }
  }

  // ============== Helper Methods ==============

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
          exerciseId: re.exerciseId.toString(),
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

  Future<WorkoutSessionModel> _mapWorkoutSession(
    WorkoutSession session,
    List<PerformedSet> sets,
  ) async {
    // Build a lookup of local routine_exercise ID → model-level ID
    // so that setsForExercise() matching works correctly.
    final reIdMap = <int, String>{};
    for (final s in sets) {
      if (!reIdMap.containsKey(s.routineExerciseId)) {
        final re = await _db.getRoutineExerciseById(s.routineExerciseId);
        reIdMap[s.routineExerciseId] =
            re?.remoteId ?? s.routineExerciseId.toString();
      }
    }

    return WorkoutSessionModel(
      id: session.remoteId ?? session.id.toString(),
      userId: session.userId,
      assignedProgramId: session.assignedProgramId,
      routineId: session.routineId?.toString(),
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      notes: session.notes,
      performedSets: sets
          .map(
            (s) => PerformedSetModel(
              id: s.remoteId ?? s.id.toString(),
              workoutSessionId: s.workoutSessionId.toString(),
              routineExerciseId:
                  reIdMap[s.routineExerciseId] ??
                  s.routineExerciseId.toString(),
              setNumber: s.setNumber,
              repsCompleted: s.repsCompleted,
              weightKg: s.weightKg,
              rpe: s.rpe,
              notes: s.notes,
              isCompleted: s.isCompleted,
              createdAt: s.createdAt,
              updatedAt: s.updatedAt,
            ),
          )
          .toList(),
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
  }

  // ============== Server-Only Operations (No Local Cache) ==============

  /// Fetch today's scheduled routine from the server.
  ///
  /// Calls `GET /api/workout/today` which calculates the routine based on
  /// the user's active assigned program and day-cycle logic.
  ///
  /// Returns [TodayRoutineModel] with `isRestDay` flag and optional routine.
  Future<Result<TodayRoutineModel, AppError>> getTodayRoutine({
    String? assignedProgramId,
  }) async {
    AppLogger.debug('Fetching today routine from server', tag: 'WorkoutRepo');

    final queryParams = <String, dynamic>{
      if (assignedProgramId != null) 'assignedProgramId': assignedProgramId,
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.todayWorkout,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return result.when(
      success: (data) {
        try {
          final model = TodayRoutineModel.fromJson(data);
          AppLogger.info(
            'Today routine: ${model.isRestDay ? "Rest Day" : model.today?.routine.name}',
            tag: 'WorkoutRepo',
          );
          return Success(model);
        } catch (e) {
          AppLogger.error(
            'Failed to parse today routine',
            tag: 'WorkoutRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse today routine: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch today routine',
          tag: 'WorkoutRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  /// Fetch aggregated weekly workout statistics from the server.
  ///
  /// Calls `GET /api/workout/stats/weekly` with an optional `weekOf` date.
  /// Returns workouts completed, total minutes, and streak days.
  Future<Result<WeeklyStatsModel, AppError>> getWeeklyStats({
    DateTime? weekOf,
  }) async {
    AppLogger.debug('Fetching weekly stats from server', tag: 'WorkoutRepo');

    final queryParams = <String, dynamic>{
      if (weekOf != null) 'weekOf': weekOf.toIso8601String(),
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.weeklyStats,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return result.when(
      success: (data) {
        try {
          final statsJson = data['stats'] as Map<String, dynamic>;
          final model = WeeklyStatsModel.fromJson(statsJson);
          AppLogger.info(
            'Weekly stats: ${model.workoutsCompleted} workouts, '
            '${model.totalMinutes}min, ${model.streakDays} streak',
            tag: 'WorkoutRepo',
          );
          return Success(model);
        } catch (e) {
          AppLogger.error(
            'Failed to parse weekly stats',
            tag: 'WorkoutRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse weekly stats: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch weekly stats',
          tag: 'WorkoutRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  /// Fetch paginated workout session history from the server.
  ///
  /// Calls `GET /api/workout/sessions` with pagination and optional
  /// date-range filters. Returns completed sessions with total set counts.
  Future<Result<WorkoutHistoryResponse, AppError>> getSessionHistory({
    int limit = 20,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.debug(
      'Fetching session history: limit=$limit, offset=$offset',
      tag: 'WorkoutRepo',
    );

    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.workoutSessions,
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final response = WorkoutHistoryResponse.fromJson(data);
          AppLogger.info(
            'Fetched ${response.sessions.length} sessions '
            '(total: ${response.pagination.total})',
            tag: 'WorkoutRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse session history',
            tag: 'WorkoutRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse session history: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch session history',
          tag: 'WorkoutRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  /// Start a workout session on the server.
  ///
  /// Calls `POST /api/workout/sessions`. The server validates subscription
  /// status and rejects with 409 if an active session already exists.
  Future<Result<WorkoutSessionModel, AppError>> startServerSession({
    String? assignedProgramId,
  }) async {
    AppLogger.debug('Starting server session', tag: 'WorkoutRepo');

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.workoutSessions,
      data: {
        if (assignedProgramId != null) 'assignedProgramId': assignedProgramId,
      },
    );

    return result.when(
      success: (data) {
        try {
          final sessionJson = data['session'] as Map<String, dynamic>;
          final model = WorkoutSessionModel.fromJson(sessionJson);
          AppLogger.info(
            'Server session started: ${model.id}',
            tag: 'WorkoutRepo',
          );
          return Success(model);
        } catch (e) {
          AppLogger.error(
            'Failed to parse server session',
            tag: 'WorkoutRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse server session: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to start server session',
          tag: 'WorkoutRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  /// Complete a workout session on the server.
  ///
  /// Calls `POST /api/workout/sessions/:sessionId/complete`.
  Future<Result<WorkoutSessionModel, AppError>> completeServerSession({
    required String sessionId,
    String? notes,
  }) async {
    AppLogger.debug(
      'Completing server session: $sessionId',
      tag: 'WorkoutRepo',
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.workoutSessions}/$sessionId/complete',
      data: {if (notes != null) 'notes': notes},
    );

    return result.when(
      success: (data) {
        try {
          final sessionJson = data['session'] as Map<String, dynamic>;
          final model = WorkoutSessionModel.fromJson(sessionJson);
          AppLogger.info(
            'Server session completed: ${model.id}',
            tag: 'WorkoutRepo',
          );
          return Success(model);
        } catch (e) {
          AppLogger.error(
            'Failed to parse completed session',
            tag: 'WorkoutRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse completed session: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to complete server session: $sessionId',
          tag: 'WorkoutRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  /// Batch-sync locally-recorded sets to the server.
  ///
  /// Calls `POST /api/workout/sets/sync` with the array of sets.
  /// Returns per-set results mapping `localId` → `serverId`.
  Future<Result<BatchSyncResult, AppError>> batchSyncSets({
    required List<Map<String, dynamic>> sets,
  }) async {
    AppLogger.debug(
      'Batch syncing ${sets.length} sets to server',
      tag: 'WorkoutRepo',
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.performedSetsSync,
      data: {'sets': sets},
    );

    return result.when(
      success: (data) {
        try {
          final results = (data['results'] as List)
              .map((r) => SetSyncResult.fromJson(r as Map<String, dynamic>))
              .toList();
          final summary = data['summary'] as Map<String, dynamic>?;
          final model = BatchSyncResult(
            results: results,
            totalProcessed: summary?['total'] as int? ?? results.length,
            successful:
                summary?['successful'] as int? ??
                results.where((r) => r.success).length,
            failed:
                summary?['failed'] as int? ??
                results.where((r) => !r.success).length,
          );
          AppLogger.info(
            'Batch sync: ${model.successful}/${model.totalProcessed} successful',
            tag: 'WorkoutRepo',
          );
          return Success(model);
        } catch (e) {
          AppLogger.error(
            'Failed to parse batch sync result',
            tag: 'WorkoutRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse batch sync result: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to batch sync sets',
          tag: 'WorkoutRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }
}

/// Provider for WorkoutRepository
@Riverpod(keepAlive: true)
WorkoutRepository workoutRepository(Ref ref) {
  return WorkoutRepository(
    database: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
  );
}

/// Result of a batch set sync operation.
class BatchSyncResult {
  BatchSyncResult({
    required this.results,
    required this.totalProcessed,
    required this.successful,
    required this.failed,
  });

  final List<SetSyncResult> results;
  final int totalProcessed;
  final int successful;
  final int failed;

  bool get hasFailures => failed > 0;
}

/// Individual set sync result.
class SetSyncResult {
  SetSyncResult({
    this.localId,
    this.serverId,
    required this.success,
    this.error,
  });

  final String? localId;
  final String? serverId;
  final bool success;
  final String? error;

  factory SetSyncResult.fromJson(Map<String, dynamic> json) {
    return SetSyncResult(
      localId: json['localId'] as String?,
      serverId: json['serverId'] as String?,
      success: json['success'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }
}
