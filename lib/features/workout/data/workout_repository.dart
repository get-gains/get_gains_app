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

  // ============== Workout Session Operations ==============

  /// Get active workout session for a user
  Future<Result<WorkoutSessionModel?, AppError>> getActiveSession(
    String userId,
  ) async {
    try {
      final session = await _db.getActiveWorkoutSession(userId);
      if (session == null) return const Success(null);

      final sets = await _db.getPerformedSets(session.id);
      return Success(_mapWorkoutSession(session, sets));
    } catch (e) {
      AppLogger.error(
        'Failed to get active session',
        tag: 'WorkoutRepo',
        error: e,
      );
      return Failure(DatabaseError(message: 'Failed to get session: $e'));
    }
  }

  /// Start a new workout session
  Future<Result<WorkoutSessionModel, AppError>> startWorkoutSession({
    required String userId,
    int? routineId,
    String? assignedProgramId,
  }) async {
    try {
      AppLogger.info('Starting workout session', tag: 'WorkoutRepo');

      final sessionId = await _db.startWorkoutSession(
        WorkoutSessionsCompanion.insert(
          userId: userId,
          routineId: Value(routineId),
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
      return Success(_mapWorkoutSession(session, []));
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
      return Success(_mapWorkoutSession(session, sets));
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
      return Success(_mapWorkoutSession(session!, sets));
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
        sessionModels.add(_mapWorkoutSession(session, sets));
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
    required int workoutSessionId,
    required int routineExerciseId,
    required int setNumber,
    required int repsCompleted,
    double? weightKg,
    int? rpe,
    String? notes,
  }) async {
    try {
      AppLogger.debug(
        'Logging set: session=$workoutSessionId, exercise=$routineExerciseId, '
        'set=$setNumber, reps=$repsCompleted, weight=$weightKg',
        tag: 'WorkoutRepo',
      );

      final setId = await _db.logSet(
        workoutSessionId: workoutSessionId,
        routineExerciseId: routineExerciseId,
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
            'routineExerciseId': routineExerciseId,
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
          routineExerciseId: routineExerciseId.toString(),
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

      return Success(sets.map((s) => _mapPerformedSet(s)).toList());
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

  WorkoutSessionModel _mapWorkoutSession(
    WorkoutSession session,
    List<PerformedSet> sets,
  ) {
    return WorkoutSessionModel(
      id: session.remoteId ?? session.id.toString(),
      userId: session.userId,
      assignedProgramId: session.assignedProgramId,
      routineId: session.routineId?.toString(),
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      notes: session.notes,
      performedSets: sets.map(_mapPerformedSet).toList(),
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
  }

  PerformedSetModel _mapPerformedSet(PerformedSet set) {
    return PerformedSetModel(
      id: set.remoteId ?? set.id.toString(),
      workoutSessionId: set.workoutSessionId.toString(),
      routineExerciseId: set.routineExerciseId.toString(),
      setNumber: set.setNumber,
      repsCompleted: set.repsCompleted,
      weightKg: set.weightKg,
      rpe: set.rpe,
      notes: set.notes,
      isCompleted: set.isCompleted,
      createdAt: set.createdAt,
      updatedAt: set.updatedAt,
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
