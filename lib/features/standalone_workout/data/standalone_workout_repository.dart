import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/cache/cache_service.dart';
import '../../../services/database/app_database.dart'
    hide StandaloneProgram, StandaloneProgramRoutine;
import '../../../services/outbox/outbox_service.dart';
import '../../../services/storage/secure_storage_service.dart';
import '../../workout/data/models/models.dart';
import 'models/models.dart';

part 'standalone_workout_repository.g.dart';

@Riverpod(keepAlive: true)
StandaloneWorkoutRepository standaloneWorkoutRepository(Ref ref) {
  return StandaloneWorkoutRepository(
    apiClient: ref.watch(apiClientProvider),
    database: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxServiceProvider),
    cache: ref.watch(cacheServiceProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
}

class StandaloneWorkoutRepository {
  StandaloneWorkoutRepository({
    required ApiClient apiClient,
    required AppDatabase database,
    required OutboxService outbox,
    required CacheService cache,
    required SecureStorageService storage,
  }) : _apiClient = apiClient,
       _db = database,
       _outbox = outbox,
       _cache = cache,
       _storage = storage;

  final ApiClient _apiClient;
  final AppDatabase _db;
  final OutboxService _outbox;
  final CacheService _cache;
  final SecureStorageService _storage;

  Future<String> get _userId async => (await _storage.getUserId()) ?? '';

  static const _ckPrograms = 'standalone_programs';
  static String _ckProgram(String id) => 'standalone_program:$id';
  static const _ckActiveProgram = 'standalone_active_program';
  static const _ckActiveSession = 'standalone_active_session';
  static String _ckSession(String id) => 'standalone_session:$id';
  static const _ckSessionsHistory = 'standalone_sessions_history';
  static const _ckStats = 'standalone_stats';
  static String _ckExerciseStat(String id) => 'standalone_exercise_stat:$id';
  static String _now() => DateTime.now().toIso8601String();

  // ============== PROGRAM OPERATIONS ==============

  Future<Result<StandaloneProgramListResponse, AppError>> getPrograms({
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standalonePrograms,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      final pagination = d['pagination'] as Map<String, dynamic>?;
      if (pagination != null) {
        d['total'] = pagination['total'];
        d['limit'] = pagination['limit'];
        d['offset'] = pagination['offset'];
        d['hasMore'] = pagination['hasMore'];
      }
      _cache.putJson(_ckPrograms, d, version: _now());
      return Success(StandaloneProgramListResponse.fromJson(d));
    }
    final cached = await _cache.get<Map<String, dynamic>>(_ckPrograms, (json) => json);
    if (cached != null) return Success(StandaloneProgramListResponse.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<StandaloneProgramDetail, AppError>> getProgram(
    String programId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId',
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      final program = d['program'] as Map<String, dynamic>? ?? d;
      _cache.putJson(_ckProgram(programId), program, version: _now());
      return Success(StandaloneProgramDetail.fromJson(program));
    }
    final cached = await _cache.get<Map<String, dynamic>>(_ckProgram(programId), (json) => json);
    if (cached != null) return Success(StandaloneProgramDetail.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<StandaloneProgramDetail, AppError>> getActiveProgram() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneActiveProgram,
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      final program = d['program'] as Map<String, dynamic>? ?? d;
      _cache.putJson(_ckActiveProgram, program, version: _now());
      return Success(StandaloneProgramDetail.fromJson(program));
    }
    final cached = await _cache.get<Map<String, dynamic>>(_ckActiveProgram, (json) => json);
    if (cached != null) return Success(StandaloneProgramDetail.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<StandaloneProgram, AppError>> createProgram(
    CreateStandaloneProgramRequest request,
  ) async {
    final id = _outbox.newId();
    final userId = await _userId;
    final now = DateTime.now();

    await _db.upsertStandaloneProgram(
      StandaloneProgramsCompanion.insert(
        id: id,
        userId: userId,
        name: request.name,
        description: request.description,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _outbox.enqueue(
      entityType: 'standalone_program',
      operation: 'create',
      payload: jsonEncode({...request.toJson(), 'id': id}),
    );

    return Success(StandaloneProgram(
      id: id,
      name: request.name,
      description: request.description,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<Result<StandaloneProgram, AppError>> updateProgram(
    String programId,
    UpdateStandaloneProgramRequest request,
  ) async {
    final now = DateTime.now();

    await _db.upsertStandaloneProgram(
      StandaloneProgramsCompanion.insert(
        id: programId,
        userId: await _userId,
        name: request.name ?? '',
        description: request.description ?? '',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _outbox.enqueue(
      entityType: 'standalone_program',
      operation: 'update',
      payload: jsonEncode({...request.toJson(), 'id': programId}),
    );

    return Success(StandaloneProgram(
      id: programId,
      name: request.name ?? '',
      description: request.description ?? '',
      createdAt: null,
      updatedAt: now,
    ));
  }

  Future<Result<void, AppError>> deleteProgram(String programId) async {
    await _db.deleteStandaloneProgram(programId);
    await _outbox.enqueue(
      entityType: 'standalone_program',
      operation: 'delete',
      payload: jsonEncode({'id': programId}),
    );
    return const Success(null);
  }

  Future<Result<void, AppError>> activateProgram(String programId) async {
    final userId = await _userId;
    await _db.deactivateAllStandaloneAssignments(userId);
    await _db.upsertStandaloneAssignment(
      StandaloneAssignedProgramsCompanion.insert(
        id: _outbox.newId(),
        userId: userId,
        programId: programId,
        startDate: DateTime.now(),
        isActive: const Value(true),
        updatedAt: DateTime.now(),
      ),
    );

    await _outbox.enqueue(
      entityType: 'standalone_program',
      operation: 'activate',
      payload: jsonEncode({'id': programId}),
    );

    return const Success(null);
  }

  Future<Result<void, AppError>> deactivateProgram(String programId) async {
    final userId = await _userId;
    await _db.deactivateAllStandaloneAssignments(userId);

    await _outbox.enqueue(
      entityType: 'standalone_program',
      operation: 'deactivate',
      payload: jsonEncode({'id': programId}),
    );

    return const Success(null);
  }

  // ============== BUILDER (BULK) ==============

  Future<Result<StandaloneProgramDetail, AppError>> buildProgram(
    BuildStandaloneProgramRequest request,
  ) async {
    final id = _outbox.newId();
    final userId = await _userId;
    final now = DateTime.now();

    await _db.upsertStandaloneProgram(
      StandaloneProgramsCompanion.insert(
        id: id,
        userId: userId,
        name: request.name,
        description: request.description,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final routines = <StandaloneProgramRoutine>[];
    for (final r in request.routines) {
      final prId = _outbox.newId();
      await _db.upsertStandaloneProgramRoutine(
        StandaloneProgramRoutinesCompanion.insert(
          id: prId,
          programId: id,
          routineId: r.routineId,
          dayOfWeek: '',
          createdAt: now,
        ),
      );
      routines.add(StandaloneProgramRoutine(
        id: prId,
        routineId: r.routineId,
        routineName: '',
        orderInProgram: r.orderInProgram,
      ));
    }

    await _outbox.enqueue(
      entityType: 'standalone_program',
      operation: 'create',
      payload: jsonEncode({...request.toJson(), 'id': id}),
    );

    return Success(StandaloneProgramDetail(
      id: id,
      name: request.name,
      description: request.description,
      routines: routines,
      createdAt: now,
    ));
  }

  // ============== PROGRAM ROUTINE OPERATIONS ==============

  Future<Result<StandaloneProgramDetail, AppError>> addProgramRoutine(
    String programId,
    AddProgramRoutineRequest request,
  ) async {
    final id = _outbox.newId();
    final now = DateTime.now();

    await _db.upsertStandaloneProgramRoutine(
      StandaloneProgramRoutinesCompanion.insert(
        id: id,
        programId: programId,
        routineId: request.routineId,
        dayOfWeek: '',
        createdAt: now,
      ),
    );

    await _outbox.enqueue(
      entityType: 'standalone_program_routine',
      operation: 'create',
      payload: jsonEncode({
        'id': id,
        'program_id': programId,
        'routine_id': request.routineId,
        'order_in_program': request.orderInProgram,
      }),
    );

    final cached = await _cache.get<Map<String, dynamic>>(_ckProgram(programId), (json) => json);
    if (cached != null) return Success(StandaloneProgramDetail.fromJson(cached));
    return getProgram(programId);
  }

  Future<Result<void, AppError>> updateProgramRoutine(
    String programId,
    String programRoutineId,
    UpdateProgramRoutineRequest request,
  ) async {
    await _outbox.enqueue(
      entityType: 'standalone_program_routine',
      operation: 'update',
      payload: jsonEncode({
        'id': programRoutineId,
        'program_id': programId,
        'order_in_program': request.orderInProgram,
      }),
    );
    return const Success(null);
  }

  Future<Result<void, AppError>> deleteProgramRoutine(
    String programId,
    String programRoutineId,
  ) async {
    await _db.deleteStandaloneProgramRoutine(programRoutineId);
    await _outbox.enqueue(
      entityType: 'standalone_program_routine',
      operation: 'delete',
      payload: jsonEncode({'id': programRoutineId, 'program_id': programId}),
    );
    return const Success(null);
  }

  // ============== ROUTINE EXERCISE OPERATIONS ==============

  Future<Result<void, AppError>> addRoutineExercise(
    String routineId,
    AddRoutineExerciseRequest request,
  ) async {
    final id = _outbox.newId();

    await _db.upsertRoutineExercise(
      RoutineExercisesCompanion.insert(
        id: id,
        routineId: routineId,
        exerciseId: request.exerciseId,
        sets: request.sets,
        repsMin: request.repsMin,
        repsMax: request.repsMax,
        restSeconds: request.restSeconds,
        orderInRoutine: request.orderInRoutine,
      ),
    );

    await _outbox.enqueue(
      entityType: 'standalone_routine_exercise',
      operation: 'create',
      payload: jsonEncode({
        'id': id,
        'routine_id': routineId,
        'exercise_id': request.exerciseId,
        'sets': request.sets,
        'reps_min': request.repsMin,
        'reps_max': request.repsMax,
        'rest_seconds': request.restSeconds,
        'order_in_routine': request.orderInRoutine,
      }),
    );

    return const Success(null);
  }

  Future<Result<void, AppError>> updateRoutineExercise(
    String routineId,
    String routineExerciseId,
    UpdateRoutineExerciseRequest request,
  ) async {
    final payload = <String, dynamic>{'id': routineExerciseId, 'routine_id': routineId};
    if (request.sets != null) payload['sets'] = request.sets;
    if (request.repsMin != null) payload['reps_min'] = request.repsMin;
    if (request.repsMax != null) payload['reps_max'] = request.repsMax;
    if (request.restSeconds != null) payload['rest_seconds'] = request.restSeconds;
    if (request.orderInRoutine != null) payload['order_in_routine'] = request.orderInRoutine;

    await _outbox.enqueue(
      entityType: 'standalone_routine_exercise',
      operation: 'update',
      payload: jsonEncode(payload),
    );

    return const Success(null);
  }

  Future<Result<void, AppError>> deleteRoutineExercise(
    String routineId,
    String routineExerciseId,
  ) async {
    await _outbox.enqueue(
      entityType: 'standalone_routine_exercise',
      operation: 'delete',
      payload: jsonEncode({'id': routineExerciseId, 'routine_id': routineId}),
    );
    return const Success(null);
  }

  // ============== STANDALONE ROUTINE CRUD ==============

  Future<Result<String, AppError>> createRoutine({
    required String name,
    String description = '',
    int estimatedDurationMinutes = 45,
  }) async {
    final id = _outbox.newId();
    final now = DateTime.now();

    await _db.upsertRoutine(
      RoutinesCompanion.insert(
        id: id,
        name: name,
        description: description,
        estimatedDurationMinutes: estimatedDurationMinutes,
        updatedAt: now,
      ),
    );

    await _outbox.enqueue(
      entityType: 'standalone_routine',
      operation: 'create',
      payload: jsonEncode({
        'id': id,
        'name': name,
        'description': description,
        'estimated_duration_minutes': estimatedDurationMinutes,
      }),
    );

    return Success(id);
  }

  // ============== PERSONAL EXERCISE CRUD ==============

  Future<Result<String, AppError>> createExercise({
    required String name,
    String description = '',
  }) async {
    final id = _outbox.newId();
    final now = DateTime.now();

    await _db.upsertExercise(
      ExercisesCompanion.insert(
        id: id,
        name: name,
        description: description,
        primaryMuscleGroup: '',
        updatedAt: now,
      ),
    );

    await _outbox.enqueue(
      entityType: 'standalone_exercise',
      operation: 'create',
      payload: jsonEncode({
        'id': id,
        'name': name,
        'description': description,
      }),
    );

    return Success(id);
  }

  // ============== SESSION OPERATIONS ==============

  Future<Result<StandaloneSession, AppError>> startSession(
    StartStandaloneSessionRequest request,
  ) async {
    final id = _outbox.newId();
    final userId = await _userId;
    final now = DateTime.now();

    await _db.insertWorkoutSession(
      WorkoutSessionsCompanion.insert(
        id: id,
        userId: userId,
        standaloneProgramRoutineId: Value(request.programRoutineId),
        startedAt: now,
        createdAt: now,
      ),
    );

    await _outbox.enqueue(
      entityType: 'standalone_session',
      operation: 'create',
      payload: jsonEncode({
        'id': id,
        'program_routine_id': request.programRoutineId,
      }),
    );

    final exercises = await _loadRoutineExercises(request.programRoutineId);

    return Success(StandaloneSession(
      id: id,
      userId: userId,
      programRoutineId: request.programRoutineId,
      startedAt: now,
      exercises: exercises,
    ));
  }

  Future<Result<StandaloneSession?, AppError>> getActiveSession() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneActiveSession,
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      final session = d['session'];
      if (session == null) return const Success(null);
      _cache.putJson(_ckActiveSession, session as Map<String, dynamic>, version: _now());
      return Success(StandaloneSession.fromJson(session));
    }
    final cached = await _cache.get<Map<String, dynamic>>(_ckActiveSession, (json) => json);
    if (cached != null) return Success(StandaloneSession.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<
    Result<
      ({
        WorkoutSessionModel session,
        List<RoutineExerciseModel> exercises,
        String routineName,
      })?,
      AppError
    >
  >
  resumeActiveSession() async {
    final result = await getActiveSession();
    return result.when(
      success: (session) {
        if (session == null) return const Success(null);
        final workoutSession = WorkoutSessionModel(
          id: session.id,
          userId: session.userId,
          assignedProgramRoutineId: session.programRoutineId,
          startedAt: session.startedAt,
          completedAt: session.completedAt,
          notes: session.feedback,
          createdAt: session.createdAt,
          performedSets: const [],
        );
        final exercises = session.exercises
            .map((e) => RoutineExerciseModel(
                  id: e.id,
                  exerciseId: e.exerciseId,
                  sets: e.sets,
                  repsMin: e.repsMin,
                  repsMax: e.repsMax,
                  restSeconds: e.restSeconds,
                  orderInRoutine: e.orderInRoutine,
                ))
            .toList();
        return Success((session: workoutSession, exercises: exercises, routineName: session.routineName ?? 'Workout'));
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneSession, AppError>> getSession(String sessionId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standaloneSessions}/$sessionId',
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      final session = d['session'] as Map<String, dynamic>;
      _cache.putJson(_ckSession(sessionId), session, version: _now());
      return Success(StandaloneSession.fromJson(session));
    }
    final cached = await _cache.get<Map<String, dynamic>>(_ckSession(sessionId), (json) => json);
    if (cached != null) return Success(StandaloneSession.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<StandaloneSessionListResponse, AppError>> getSessionHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneSessions,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      final pagination = d['pagination'] as Map<String, dynamic>?;
      if (pagination != null) {
        d['total'] = pagination['total'];
        d['limit'] = pagination['limit'];
        d['offset'] = pagination['offset'];
        d['hasMore'] = pagination['hasMore'];
      }
      _cache.putJson(_ckSessionsHistory, d, version: _now());
      return Success(StandaloneSessionListResponse.fromJson(d));
    }
    final cached = await _cache.get<Map<String, dynamic>>(_ckSessionsHistory, (json) => json);
    if (cached != null) return Success(StandaloneSessionListResponse.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<StandaloneSession, AppError>> completeSession(
    String sessionId, {
    String? feedback,
  }) async {
    await _db.completeWorkoutSession(sessionId, notes: feedback);

    await _outbox.enqueue(
      entityType: 'standalone_session',
      operation: 'complete',
      payload: jsonEncode({'id': sessionId, 'feedback': feedback}),
    );

    return getSession(sessionId);
  }

  Future<Result<WorkoutSessionModel, AppError>> startWorkoutSession({
    required String userId,
    required String programRoutineId,
  }) async {
    AppLogger.debug('Starting standalone workout session', tag: 'StandaloneRepo');

    final id = _outbox.newId();
    final now = DateTime.now();

    await _db.insertWorkoutSession(
      WorkoutSessionsCompanion.insert(
        id: id,
        userId: userId,
        standaloneProgramRoutineId: Value(programRoutineId),
        startedAt: now,
        createdAt: now,
      ),
    );

    await _outbox.enqueue(
      entityType: 'standalone_session',
      operation: 'create',
      payload: jsonEncode({'id': id, 'program_routine_id': programRoutineId}),
    );

    AppLogger.info('Standalone session started: $id', tag: 'StandaloneRepo');
    return Success(WorkoutSessionModel(
      id: id,
      userId: userId,
      assignedProgramRoutineId: programRoutineId,
      startedAt: now,
      createdAt: now,
      performedSets: const [],
    ));
  }

  // ============== PERFORMED SET OPERATIONS ==============

  Future<Result<StandalonePerformedSet, AppError>> logSet(
    String sessionId,
    LogStandaloneSetRequest request,
  ) async {
    final id = _outbox.newId();
    final now = DateTime.now();

    await _db.upsertPerformedSet(
      PerformedSetsCompanion.insert(
        id: id,
        workoutSessionId: sessionId,
        assignedProgramRoutineExerciseId: request.routineExerciseId,
        setNumber: request.setNumber,
        repsCompleted: request.reps,
        weightKg: Value(request.weight),
        createdAt: now,
      ),
    );

    await _outbox.enqueue(
      entityType: 'standalone_set_log',
      operation: 'create',
      payload: jsonEncode({
        'id': id,
        'session_id': sessionId,
        'routine_exercise_id': request.routineExerciseId,
        'set_number': request.setNumber,
        'reps': request.reps,
        'weight': request.weight,
      }),
    );

    return Success(StandalonePerformedSet(
      id: id,
      routineExerciseId: request.routineExerciseId,
      setNumber: request.setNumber,
      reps: request.reps,
      weight: request.weight,
      createdAt: now,
    ));
  }

  Future<Result<StandalonePerformedSet, AppError>> updateSet(
    String sessionId,
    String setId,
    UpdateStandaloneSetRequest request,
  ) async {
    final payload = <String, dynamic>{'id': setId, 'session_id': sessionId};
    if (request.reps != null) payload['reps'] = request.reps;
    if (request.weight != null) payload['weight'] = request.weight;

    await _outbox.enqueue(
      entityType: 'standalone_set_log',
      operation: 'update',
      payload: jsonEncode(payload),
    );

    return Success(StandalonePerformedSet(
      id: setId,
      routineExerciseId: '',
      setNumber: 0,
      reps: request.reps ?? 0,
      weight: request.weight ?? 0,
    ));
  }

  Future<Result<void, AppError>> deleteSet(
    String sessionId,
    String setId,
  ) async {
    await _db.deletePerformedSet(setId);

    await _outbox.enqueue(
      entityType: 'standalone_set_log',
      operation: 'delete',
      payload: jsonEncode({'id': setId, 'session_id': sessionId}),
    );

    return const Success(null);
  }

  // ============== STATS OPERATIONS ==============

  Future<Result<StandaloneStats, AppError>> getStats() async {
    final result = await _apiClient.get<Map<String, dynamic>>(ApiConstants.standaloneStats);
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      _cache.putJson(_ckStats, d, version: _now());
      return Success(StandaloneStats.fromJson(d));
    }
    final cached = await _cache.get<Map<String, dynamic>>(_ckStats, (json) => json);
    if (cached != null) return Success(StandaloneStats.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<StandaloneExerciseStat, AppError>> getExerciseStat(
    String exerciseId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standaloneStats}/exercise/$exerciseId',
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      _cache.putJson(_ckExerciseStat(exerciseId), d, version: _now());
      return Success(StandaloneExerciseStat.fromJson(d));
    }
    final cached = await _cache.get<Map<String, dynamic>>(_ckExerciseStat(exerciseId), (json) => json);
    if (cached != null) return Success(StandaloneExerciseStat.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  // ============== HELPERS ==============

  Future<List<StandaloneSessionExercise>> _loadRoutineExercises(String programRoutineId) async {
    try {
      final pr = await (_db.select(_db.standaloneProgramRoutines)
            ..where((tbl) => tbl.id.equals(programRoutineId)))
          .getSingleOrNull();
      if (pr == null) return [];

      final exercises = await _db.getRoutineExercises(pr.routineId);
      return exercises
          .map((re) => StandaloneSessionExercise(
                id: re.id,
                exerciseId: re.exerciseId,
                exerciseName: '',
                sets: re.sets,
                repsMin: re.repsMin,
                repsMax: re.repsMax,
                restSeconds: re.restSeconds,
                orderInRoutine: re.orderInRoutine,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
