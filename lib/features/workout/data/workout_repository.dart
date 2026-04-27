import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/api_error_codes.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/database/app_database.dart';
import 'models/models.dart';
import '../../home/data/models/today_status_model.dart';
import '../../subscription/data/models/subscription_model.dart';

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

  /// Get active workout session for a user.
  ///
  /// If the session has no [remoteId] yet (server sync pending), attempts
  /// an eager sync so that the model's `id` resolves to the server ID
  /// before the caller navigates to recording/upload screens.
  Future<Result<WorkoutSessionModel?, AppError>> getActiveSession(
    String userId,
  ) async {
    try {
      final session = await _db.getActiveWorkoutSession(userId);
      if (session == null) return const Success(null);

      // Eagerly sync if remoteId is missing so pose-frame uploads work.
      if (session.remoteId == null) {
        // Resolve the assigned_program_routine.id for the server request.
        // New sessions store it in assignedProgramId; legacy sessions
        // created before the fix may only have routineId set.
        String? programRoutineId = session.assignedProgramId;
        if (programRoutineId == null && session.routineId != null) {
          final routine = await _db.getRoutineById(session.routineId!);
          programRoutineId = routine?.remoteId;
        }

        if (programRoutineId != null) {
          try {
            final serverResult = await _apiClient.post<Map<String, dynamic>>(
              ApiConstants.workoutSessions,
              data: {'assignedProgramRoutineId': programRoutineId},
            );
            await serverResult.when(
              success: (data) async {
                final sessionJson = data['session'] as Map<String, dynamic>;
                final remoteId = sessionJson['id'] as String;
                await _db.updateWorkoutSessionRemoteId(session.id, remoteId);
                AppLogger.info(
                  'Eagerly synced resumed session ${session.id} → $remoteId',
                  tag: 'WorkoutRepo',
                );
              },
              failure: (error) async {
                if (error.code == ApiErrorCode.workoutSessionAlreadyActive) {
                  final activeResult = await _apiClient
                      .get<Map<String, dynamic>>(
                        '${ApiConstants.workoutSessions}/active',
                      );
                  final activeData = activeResult.valueOrNull;
                  final activeSession =
                      activeData?['session'] as Map<String, dynamic>?;
                  if (activeSession != null) {
                    final remoteId = activeSession['id'] as String;
                    await _db.updateWorkoutSessionRemoteId(
                      session.id,
                      remoteId,
                    );
                    AppLogger.info(
                      'Resolved active session on resume ${session.id} → $remoteId',
                      tag: 'WorkoutRepo',
                    );
                  }
                }
              },
            );
          } catch (_) {
            // Best-effort — sync queue will handle it eventually
          }
        }
        // Re-fetch so the model picks up the newly set remoteId
        final updated = await _db.getWorkoutSessionById(session.id);
        if (updated != null) {
          final sets = await _db.getPerformedSets(updated.id);
          return Success(await _mapWorkoutSession(updated, sets));
        }
      }

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

  // ============== Program Operations ==============

  /// Sync assigned programs from server and cache to local DB.
  ///
  /// Returns [Success] with the parsed list on success,
  /// or [Failure] on network/parse error (caller should fall back to local DB).
  Future<Result<List<AssignedProgramModel>, AppError>> syncPrograms() async {
    AppLogger.debug('Syncing programs from server', tag: 'WorkoutRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.workoutPrograms,
    );

    return result.when(
      success: (data) async {
        try {
          final programsList = <AssignedProgramModel>[];
          final programsJson = data['programs'] as List;

          for (final programJson in programsJson) {
            try {
              final program = AssignedProgramModel.fromJson(
                programJson as Map<String, dynamic>,
              );
              programsList.add(program);
            } catch (e) {
              AppLogger.error(
                'Failed to parse individual program',
                tag: 'WorkoutRepo',
                error: e,
              );
              continue;
            }
          }

          // Full replace: clear old cache, write fresh data
          await _db.replaceAssignedPrograms(
            programsList
                .map(
                  (p) => AssignedProgramsCompanion.insert(
                    remoteId: p.id,
                    name: p.name,
                    description: Value(p.description),
                    isActive: Value(p.isActive),
                    startDate: Value(p.startDate),
                    endDate: Value(p.endDate),
                    routinesJson: Value(p.routinesJson),
                  ),
                )
                .toList(),
          );

          AppLogger.info(
            'Synced ${programsList.length} programs',
            tag: 'WorkoutRepo',
          );
          return Success(programsList);
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to parse programs',
            tag: 'WorkoutRepo',
            error: e,
          );
          AppLogger.debug('Stack trace: $stackTrace', tag: 'WorkoutRepo');
          return Failure(
            DatabaseError(message: 'Failed to parse programs: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Get all assigned programs from local DB (offline-first).
  Future<Result<List<AssignedProgramModel>, AppError>> getPrograms() async {
    try {
      AppLogger.debug('Fetching programs from local DB', tag: 'WorkoutRepo');
      final rows = await _db.getAssignedPrograms();

      final models = rows
          .map(
            (row) => AssignedProgramModelX.fromDbRow(
              remoteId: row.remoteId,
              name: row.name,
              description: row.description,
              isActive: row.isActive,
              startDate: row.startDate,
              endDate: row.endDate,
              routinesJson: row.routinesJson,
            ),
          )
          .toList();

      return Success(models);
    } catch (e) {
      AppLogger.error(
        'Failed to load programs from local DB',
        tag: 'WorkoutRepo',
        error: e,
      );
      return Failure(DatabaseError(message: 'Failed to load programs: $e'));
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

  /// Resolve a WorkoutSessionModel.id (remote CUID or local int string) to
  /// the local auto-increment integer ID used by the Drift WorkoutSessions table.
  Future<int?> resolveLocalWorkoutSessionId(String modelId) async {
    // 1. Try parsing as local integer ID
    final localId = int.tryParse(modelId);
    if (localId != null) {
      final session = await _db.getWorkoutSessionById(localId);
      if (session != null) return localId;
    }

    // 2. Fall back to looking up by remoteId
    final session = await _db.getWorkoutSessionByRemoteId(modelId);
    return session?.id;
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
          // Store the assigned_program_routine.id (routineModelId) so that
          // background sync and _autoCreateSession can create the server
          // session with the correct identifier.
          assignedProgramId: Value(routineModelId),
          startedAt: DateTime.now(),
        ),
      );

      // Eagerly sync the session to the server so that remoteId is
      // available before the user navigates to the recording screen.
      // If this fails (e.g. offline), fall back to the async sync queue.
      // NOTE: routineModelId is the assigned_program_routine.id from the
      // server's getPrograms response — exactly what the server expects.
      bool syncedEagerly = false;
      if (routineModelId != null) {
        try {
          final serverResult = await _apiClient.post<Map<String, dynamic>>(
            ApiConstants.workoutSessions,
            data: {'assignedProgramRoutineId': routineModelId},
          );
          await serverResult.when(
            success: (data) async {
              final sessionJson = data['session'] as Map<String, dynamic>;
              final remoteId = sessionJson['id'] as String;
              await _db.updateWorkoutSessionRemoteId(sessionId, remoteId);
              syncedEagerly = true;
              AppLogger.info(
                'Eagerly synced session $sessionId → $remoteId',
                tag: 'WorkoutRepo',
              );
            },
            failure: (error) async {
              // 409 — server already has an active session; fetch its ID
              if (error.code == ApiErrorCode.workoutSessionAlreadyActive) {
                final activeResult = await _apiClient.get<Map<String, dynamic>>(
                  '${ApiConstants.workoutSessions}/active',
                );
                final activeData = activeResult.valueOrNull;
                final activeSession =
                    activeData?['session'] as Map<String, dynamic>?;
                if (activeSession != null) {
                  final remoteId = activeSession['id'] as String;
                  await _db.updateWorkoutSessionRemoteId(sessionId, remoteId);
                  syncedEagerly = true;
                  AppLogger.info(
                    'Resolved existing active session $sessionId → $remoteId',
                    tag: 'WorkoutRepo',
                  );
                }
              } else {
                AppLogger.warning(
                  'Eager session sync failed, will retry via queue: ${error.message}',
                  tag: 'WorkoutRepo',
                );
              }
            },
          );
        } catch (e) {
          AppLogger.warning(
            'Eager session sync threw, will retry via queue: $e',
            tag: 'WorkoutRepo',
          );
        }
      }

      // If eager sync failed, enqueue for deferred background sync
      if (!syncedEagerly) {
        await _db.addToSyncQueue(
          SyncQueueCompanion.insert(
            entityTable: 'workout_sessions',
            recordId: sessionId.toString(),
            operation: 'create',
            payload: jsonEncode({
              'sessionId': sessionId,
              'assignedProgramRoutineId': routineModelId,
            }),
          ),
        );
      }

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

  /// Get today's completed session for a routine (from local DB)
  Future<Result<WorkoutSessionModel?, AppError>> getTodayCompletedSession({
    required String userId,
    required String routineModelId,
  }) async {
    try {
      final localRoutineId = await _resolveLocalRoutineId(routineModelId);
      if (localRoutineId == null) return const Success(null);

      final session = await _db.getTodayCompletedSessionForRoutine(
        userId,
        localRoutineId,
      );
      if (session == null) return const Success(null);

      final sets = await _db.getPerformedSets(session.id);
      return Success(await _mapWorkoutSession(session, sets));
    } catch (e) {
      AppLogger.error(
        'Failed to get today completed session',
        tag: 'WorkoutRepo',
        error: e,
      );
      return Failure(
        DatabaseError(message: 'Failed to get today session: \$e'),
      );
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

  /// Get completed session history from local DB (paginated).
  ///
  /// Returns a [WorkoutHistoryResponse] matching the server format
  /// so the history screen can use local data.
  Future<Result<WorkoutHistoryResponse, AppError>> getLocalSessionHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Clean up sessions older than 7 days
      final deleted = await _db.deleteOldCompletedSessions(days: 7);
      if (deleted > 0) {
        AppLogger.info('Cleaned up $deleted old sessions', tag: 'WorkoutRepo');
      }

      final sessions = await _db.getCompletedSessions(
        userId,
        limit: limit,
        offset: offset,
      );
      final total = await _db.countCompletedSessions(userId);

      final summaries = <WorkoutSessionSummary>[];
      for (final session in sessions) {
        final sets = await _db.getPerformedSets(session.id);
        String? routineName;
        if (session.routineId != null) {
          final routine = await _db.getRoutineById(session.routineId!);
          routineName = routine?.name;
        }
        summaries.add(
          WorkoutSessionSummary(
            id: session.remoteId ?? session.id.toString(),
            userId: session.userId,
            assignedProgramId: session.assignedProgramId,
            routineId: session.routineId?.toString(),
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            notes: session.notes,
            totalSets: sets.length,
            routineName: routineName,
          ),
        );
      }

      return Success(
        WorkoutHistoryResponse(
          sessions: summaries,
          pagination: WorkoutHistoryPagination(
            total: total,
            limit: limit,
            offset: offset,
            hasMore: offset + sessions.length < total,
          ),
        ),
      );
    } catch (e) {
      AppLogger.error(
        'Failed to get local history',
        tag: 'WorkoutRepo',
        error: e,
      );
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
    String? recordedFramesKey,
    double? overallScore,
  }) async {
    try {
      final workoutSessionId = await resolveLocalWorkoutSessionId(
        workoutSessionModelId,
      );
      if (workoutSessionId == null) {
        return Failure(
          DatabaseError(
            message: 'Invalid workout session ID: $workoutSessionModelId',
          ),
        );
      }

      AppLogger.debug(
        'Logging set: session=$workoutSessionId, '
        'apreId=$routineExerciseModelId, '
        'set=$setNumber, reps=$repsCompleted, weight=$weightKg',
        tag: 'WorkoutRepo',
      );

      final setId = await _db.logSet(
        workoutSessionId: workoutSessionId,
        assignedProgramRoutineExerciseId: routineExerciseModelId,
        setNumber: setNumber,
        repsCompleted: repsCompleted,
        weightKg: weightKg,
        rpe: rpe,
        notes: notes,
        recordedFramesKey: recordedFramesKey,
        overallScore: overallScore,
      );

      // Add to sync queue
      await _db.addToSyncQueue(
        SyncQueueCompanion.insert(
          entityTable: 'performed_sets',
          recordId: setId.toString(),
          operation: 'create',
          payload: jsonEncode({
            'workoutSessionId': workoutSessionId,
            'assignedProgramRoutineExerciseId': routineExerciseModelId,
            'setNumber': setNumber,
            'repsCompleted': repsCompleted,
            'weightKg': weightKg,
            'rpe': rpe,
            'notes': notes,
            if (recordedFramesKey != null)
              'recordedFramesKey': recordedFramesKey,
            if (overallScore != null) 'overallScore': overallScore,
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
          recordedFramesKey: recordedFramesKey,
          overallScore: overallScore,
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
    required String assignedProgramRoutineExerciseId,
  }) async {
    try {
      final sets = await _db.getPerformedSetsForExercise(
        workoutSessionId,
        assignedProgramRoutineExerciseId,
      );

      final mappedSets = sets
          .map(
            (s) => PerformedSetModel(
              id: s.remoteId ?? s.id.toString(),
              workoutSessionId: s.workoutSessionId.toString(),
              routineExerciseId: s.assignedProgramRoutineExerciseId,
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
          .toList();

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

  Future<WorkoutSessionModel> _mapWorkoutSession(
    WorkoutSession session,
    List<PerformedSet> sets,
  ) async {
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
              routineExerciseId: s.assignedProgramRoutineExerciseId,
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

    if (result is Success<Map<String, dynamic>, AppError>) {
      final data = result.value;
      try {
        final model = TodayRoutineModel.fromJson(data);
        AppLogger.info(
          'Today routine: ${model.isRestDay ? "Rest Day" : model.today?.routine.name}',
          tag: 'WorkoutRepo',
        );
        // Cache the response for offline use (fire-and-forget)
        _db.upsertCachedApiResponse(
          key: 'today_routine',
          responseJson: jsonEncode(data),
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
    }

    // Server failed — attempt to load from cache
    AppLogger.warning(
      'Server unavailable — trying cached today routine',
      tag: 'WorkoutRepo',
    );
    try {
      final cached = await _db.getCachedApiResponse('today_routine');
      if (cached != null) {
        final model = TodayRoutineModel.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
        AppLogger.info('Loaded today routine from cache', tag: 'WorkoutRepo');
        return Success(model);
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load cached today routine',
        tag: 'WorkoutRepo',
        error: e,
      );
    }

    final failure = result as Failure<Map<String, dynamic>, AppError>;
    AppLogger.error(
      'Failed to fetch today routine — no cache available',
      tag: 'WorkoutRepo',
      error: failure.error,
    );
    return Failure(failure.error);
  }

  /// Fetch unified today status from `GET /api/today`.
  ///
  /// Returns subscription state + coach today + standalone today in one call.
  /// Always 200 — never throws [SubscriptionRequiredError].
  Future<Result<TodayStatusModel, AppError>> getTodayStatus() async {
    AppLogger.debug('Fetching today status', tag: 'WorkoutRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.todayStatus,
    );

    if (result is Success<Map<String, dynamic>, AppError>) {
      try {
        final model = TodayStatusModel.fromJson(result.value);
        AppLogger.info(
          'Today status: isCoach=${model.isCoach} subscribed=${model.isSubscribed} hasSubscribedCoach=${model.hasCoach}',
          tag: 'WorkoutRepo',
        );
        return Success(model);
      } catch (e) {
        AppLogger.error(
          'Failed to parse today status',
          tag: 'WorkoutRepo',
          error: e,
        );
        return Failure(
          UnknownError(
            message: 'Failed to parse today status: $e',
            originalError: e,
          ),
        );
      }
    }

    final failure = result as Failure<Map<String, dynamic>, AppError>;

    if (_shouldFallbackToLegacyTodayStatus(failure.error)) {
      AppLogger.warning(
        'GET /today unavailable (404), using legacy today endpoints fallback',
        tag: 'WorkoutRepo',
      );

      final legacyStatus = await _buildLegacyTodayStatus();
      if (legacyStatus != null) {
        AppLogger.info(
          'Loaded today status via legacy fallback',
          tag: 'WorkoutRepo',
        );
        return Success(legacyStatus);
      }
    }

    AppLogger.error(
      'Failed to fetch today status',
      tag: 'WorkoutRepo',
      error: failure.error,
    );
    return Failure(failure.error);
  }

  bool _shouldFallbackToLegacyTodayStatus(AppError error) {
    return error is NetworkError && error.statusCode == 404;
  }

  Future<TodayStatusModel?> _buildLegacyTodayStatus() async {
    try {
      bool isSubscribed = false;
      TodaySubscriptionInfo? subscription;

      final subscriptionResult = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.subscriptionStatus,
      );
      if (subscriptionResult is Success<Map<String, dynamic>, AppError>) {
        final data = subscriptionResult.value;
        isSubscribed = _asBool(data['isSubscribed']) ?? false;
        subscription = _parseLegacySubscriptionInfo(data['subscription']);
      }

      bool hasCoach = false;
      final subscribedCoachesResult = await _apiClient
          .get<Map<String, dynamic>>(ApiConstants.subscribedCoaches);
      if (subscribedCoachesResult is Success<Map<String, dynamic>, AppError>) {
        final data = subscribedCoachesResult.value;
        final coaches = data['coaches'];
        hasCoach = coaches is List && coaches.isNotEmpty;
      }

      TodayWorkoutDetails? coachToday;
      if (isSubscribed) {
        final coachTodayResult = await _apiClient.get<Map<String, dynamic>>(
          ApiConstants.todayWorkout,
        );
        if (coachTodayResult is Success<Map<String, dynamic>, AppError>) {
          coachToday = _parseLegacyTodayDetails(coachTodayResult.value);
          hasCoach = hasCoach || coachToday != null;
        }
      }

      // NOTE:
      // Do not call legacy `/standalone/today` here. Some deployed backend
      // versions return 500 for that endpoint, which creates noisy retry/error
      // logs on every Home refresh. Keep this fallback resilient by returning
      // coach/subscription state only when unified `/today` is unavailable.
      final TodayWorkoutDetails? standaloneToday = null;

      return TodayStatusModel(
        isSubscribed: isSubscribed,
        hasCoach: hasCoach,
        subscription: subscription,
        coachToday: coachToday,
        standaloneToday: standaloneToday,
      );
    } catch (e) {
      AppLogger.error(
        'Legacy today fallback failed',
        tag: 'WorkoutRepo',
        error: e,
      );
      return null;
    }
  }

  TodaySubscriptionInfo? _parseLegacySubscriptionInfo(dynamic rawSubscription) {
    final sub = _asMap(rawSubscription);
    if (sub == null) return null;

    final id = _asString(sub['id']);
    final status = _parseSubscriptionStatus(sub['status']);
    final currentPeriodEnd = _parseDateTime(sub['currentPeriodEnd']);

    final plan = _asMap(sub['plan']);
    final tierLevel =
        _asInt(sub['tierLevel']) ?? _asInt(plan?['tierLevel']) ?? 0;

    if (id == null || status == null || currentPeriodEnd == null) {
      return null;
    }

    return TodaySubscriptionInfo(
      id: id,
      status: status,
      tierLevel: tierLevel,
      currentPeriodEnd: currentPeriodEnd,
    );
  }

  SubscriptionStatus? _parseSubscriptionStatus(dynamic rawStatus) {
    final value = _asString(rawStatus)?.toUpperCase();
    return switch (value) {
      'ACTIVE' => SubscriptionStatus.active,
      'TRIALING' => SubscriptionStatus.trialing,
      'GRACE_PERIOD' || 'PAST_DUE' => SubscriptionStatus.gracePeriod,
      'PAUSED' => SubscriptionStatus.paused,
      'CANCELLED' || 'CANCELED' => SubscriptionStatus.cancelled,
      'EXPIRED' || 'REVOKED' => SubscriptionStatus.expired,
      _ => null,
    };
  }

  TodayWorkoutDetails? _parseLegacyTodayDetails(Map<String, dynamic> payload) {
    final isRestDay =
        _asBool(payload['isRestDay']) ??
        _asBool(payload['is_rest_day']) ??
        false;

    final todayNode = payload['today'];
    if (todayNode == null) {
      return isRestDay ? const TodayWorkoutDetails(isRestDay: true) : null;
    }

    final todayMap = _asMap(todayNode);
    if (todayMap != null) {
      return _toTodayWorkoutDetails(todayMap, isRestDay: isRestDay);
    }

    if (todayNode is List && todayNode.isNotEmpty) {
      final first = _asMap(todayNode.first);
      if (first != null) {
        return _toTodayWorkoutDetails(first, isRestDay: isRestDay);
      }
    }

    return isRestDay ? const TodayWorkoutDetails(isRestDay: true) : null;
  }

  TodayWorkoutDetails _toTodayWorkoutDetails(
    Map<String, dynamic> data, {
    required bool isRestDay,
  }) {
    final routine = _asMap(data['routine']);

    final dayOfWeek =
        _asString(data['dayOfWeek']) ??
        _extractFirstDayName(data['daysOfWeek']) ??
        _extractFirstDayName(data['days_of_week']);

    final exerciseCount =
        _asInt(data['exerciseCount']) ??
        _asInt(data['exercise_count']) ??
        (routine?['exercises'] is List
            ? (routine!['exercises'] as List).length
            : null) ??
        (data['assigned_program_routine_exercises'] is List
            ? (data['assigned_program_routine_exercises'] as List).length
            : null) ??
        0;

    final estimatedMinutes =
        _asInt(data['estimatedMinutes']) ??
        _asInt(data['estimated_duration_minutes']) ??
        _asInt(routine?['estimatedDurationMinutes']) ??
        _asInt(routine?['estimated_duration_minutes']) ??
        0;

    return TodayWorkoutDetails(
      isRestDay: isRestDay,
      programRoutineId:
          _asString(data['programRoutineId']) ??
          _asString(data['assignedProgramRoutineId']) ??
          _asString(data['id']),
      dayOfWeek: dayOfWeek,
      dayNumber: _asInt(data['dayNumber']),
      programName:
          _asString(data['programName']) ?? _asString(data['program_name']),
      routineName:
          _asString(data['routineName']) ?? _asString(routine?['name']),
      exerciseCount: exerciseCount,
      estimatedMinutes: estimatedMinutes,
    );
  }

  String? _extractFirstDayName(dynamic rawDays) {
    if (rawDays is! List || rawDays.isEmpty) return null;
    return _asString(rawDays.first);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  String? _asString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    final raw = _asString(value);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
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

  /// Fetch unified weekly stats from the new source-aware endpoint.
  ///
  /// Calls `GET /api/stats/weekly` with an optional `weekOf` date.
  /// Returns combined totals and per-source breakdowns (standalone / coach).
  /// Free users receive standalone-only sources; subscribed users see both.
  Future<Result<UnifiedWeeklyStats, AppError>> getUnifiedWeeklyStats({
    DateTime? weekOf,
  }) async {
    AppLogger.debug(
      'Fetching unified weekly stats from server',
      tag: 'WorkoutRepo',
    );

    final queryParams = <String, dynamic>{
      if (weekOf != null) 'weekOf': weekOf.toIso8601String(),
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.unifiedWeeklyStats,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (result is Success<Map<String, dynamic>, AppError>) {
      final data = result.value;
      try {
        final model = UnifiedWeeklyStats.fromJson(data);
        AppLogger.info(
          'Unified weekly stats: ${model.workoutsCompleted} workouts, '
          '${model.totalMinutes}min, ${model.streakDays} streak, '
          '${model.sources.length} sources',
          tag: 'WorkoutRepo',
        );
        // Cache for offline use (fire-and-forget)
        _db.upsertCachedApiResponse(
          key: 'unified_weekly_stats',
          responseJson: jsonEncode(data),
        );
        return Success(model);
      } catch (e) {
        AppLogger.error(
          'Failed to parse unified weekly stats',
          tag: 'WorkoutRepo',
          error: e,
        );
        return Failure(
          UnknownError(
            message: 'Failed to parse unified weekly stats: $e',
            originalError: e,
          ),
        );
      }
    }

    // Server failed — attempt to load from cache
    AppLogger.warning(
      'Server unavailable — trying cached weekly stats',
      tag: 'WorkoutRepo',
    );
    try {
      final cached = await _db.getCachedApiResponse('unified_weekly_stats');
      if (cached != null) {
        final model = UnifiedWeeklyStats.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
        AppLogger.info('Loaded weekly stats from cache', tag: 'WorkoutRepo');
        return Success(model);
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load cached weekly stats',
        tag: 'WorkoutRepo',
        error: e,
      );
    }

    final failure = result as Failure<Map<String, dynamic>, AppError>;
    AppLogger.error(
      'Failed to fetch unified weekly stats — no cache available',
      tag: 'WorkoutRepo',
      error: failure.error,
    );
    return Failure(failure.error);
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

  /// Fetch unified session history with source metadata.
  ///
  /// Calls `GET /api/sessions/history` with optional source filter
  /// and pagination. Returns sessions with source badges ("standalone"
  /// or "coach"), program names, and coach names.
  ///
  /// **Offline-first**: On success the first page (offset 0) is cached
  /// locally. On network failure the cached page is returned so the
  /// user can still browse their history without connectivity.
  ///
  /// All sessions are returned regardless of subscription status —
  /// coach session history is never gated (user's own training data).
  Future<Result<UnifiedSessionHistoryResponse, AppError>>
  getUnifiedSessionHistory({
    String source = 'all',
    int limit = 20,
    int offset = 0,
  }) async {
    AppLogger.debug(
      'Fetching unified session history: source=$source, '
      'limit=$limit, offset=$offset',
      tag: 'WorkoutRepo',
    );

    final queryParams = <String, dynamic>{
      'source': source,
      'limit': limit,
      'offset': offset,
    };

    final cacheKey = 'unified_history_$source';

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.unifiedSessionHistory,
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final response = UnifiedSessionHistoryResponse.fromJson(data);
          AppLogger.info(
            'Fetched ${response.sessions.length} unified sessions '
            '(total: ${response.pagination.total}, source: $source)',
            tag: 'WorkoutRepo',
          );

          // Cache the first page for offline use.
          if (offset == 0) {
            _db
                .upsertCachedApiResponse(
                  key: cacheKey,
                  responseJson: jsonEncode(data),
                )
                .catchError((e) {
                  AppLogger.warning(
                    'Failed to cache unified history: $e',
                    tag: 'WorkoutRepo',
                  );
                });
          }

          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse unified session history',
            tag: 'WorkoutRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse unified session history: $e',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch unified session history',
          tag: 'WorkoutRepo',
          error: error,
        );

        // Network failed — try returning cached first page.
        if (offset == 0) {
          return _loadCachedUnifiedHistory(cacheKey, error);
        }
        return Failure(error);
      },
    );
  }

  /// Attempt to load cached unified history on network failure.
  Future<Result<UnifiedSessionHistoryResponse, AppError>>
  _loadCachedUnifiedHistory(String cacheKey, AppError originalError) async {
    try {
      final cached = await _db.getCachedApiResponse(cacheKey);
      if (cached != null) {
        AppLogger.info(
          'Loaded cached unified history ($cacheKey)',
          tag: 'WorkoutRepo',
        );
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final response = UnifiedSessionHistoryResponse.fromJson(data);
        return Success(response);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to read cached unified history: $e',
        tag: 'WorkoutRepo',
      );
    }
    return Failure(originalError);
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
