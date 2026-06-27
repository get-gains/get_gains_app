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
    // 1. Try local DB first
    final userId = await _userId;
    final localResult = await _readLocalPrograms(userId);
    if (localResult != null) return Success(localResult);

    // 2. Try server
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
    final cached = await _cache.get<Map<String, dynamic>>(
      _ckPrograms,
      (json) => json,
    );
    if (cached != null)
      return Success(StandaloneProgramListResponse.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<StandaloneProgramDetail, AppError>> getProgram(
    String programId,
  ) async {
    // 1. Try local DB first
    final localResult = await _readLocalProgram(programId);
    if (localResult != null) return Success(localResult);

    // 2. Try server
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId',
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      final program = d['program'] as Map<String, dynamic>? ?? d;
      _cache.putJson(_ckProgram(programId), program, version: _now());
      return Success(StandaloneProgramDetail.fromJson(program));
    }
    final cached = await _cache.get<Map<String, dynamic>>(
      _ckProgram(programId),
      (json) => json,
    );
    if (cached != null)
      return Success(StandaloneProgramDetail.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<StandaloneProgramDetail, AppError>> getActiveProgram() async {
    // 1. Try local DB first
    final userId = await _userId;
    final localResult = await _readLocalActiveProgram(userId);
    if (localResult != null) return Success(localResult);

    // 2. Try server
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneActiveProgram,
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      final program = d['program'] as Map<String, dynamic>? ?? d;
      _cache.putJson(_ckActiveProgram, program, version: _now());
      return Success(StandaloneProgramDetail.fromJson(program));
    }
    final cached = await _cache.get<Map<String, dynamic>>(
      _ckActiveProgram,
      (json) => json,
    );
    if (cached != null)
      return Success(StandaloneProgramDetail.fromJson(cached));
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

    return Success(
      StandaloneProgram(
        id: id,
        name: request.name,
        description: request.description,
        createdAt: now,
        updatedAt: now,
      ),
    );
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

    return Success(
      StandaloneProgram(
        id: programId,
        name: request.name ?? '',
        description: request.description ?? '',
        createdAt: null,
        updatedAt: now,
      ),
    );
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
      routines.add(
        StandaloneProgramRoutine(
          id: prId,
          routineId: r.routineId,
          routineName: '',
          orderInProgram: r.orderInProgram,
        ),
      );
    }

    await _outbox.enqueue(
      entityType: 'standalone_program',
      operation: 'create',
      payload: jsonEncode({...request.toJson(), 'id': id}),
    );

    return Success(
      StandaloneProgramDetail(
        id: id,
        name: request.name,
        description: request.description,
        routines: routines,
        createdAt: now,
      ),
    );
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

    return getProgram(programId);
  }

  Future<Result<void, AppError>> updateProgramRoutine(
    String programId,
    String programRoutineId,
    UpdateProgramRoutineRequest request,
  ) async {
    await _db.updateStandaloneProgramRoutineOrder(
      programRoutineId,
      request.orderInProgram,
    );
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
    await _db.updateRoutineExerciseById(
      routineExerciseId,
      sets: request.sets,
      repsMin: request.repsMin,
      repsMax: request.repsMax,
      restSeconds: request.restSeconds,
      orderInRoutine: request.orderInRoutine,
    );

    final payload = <String, dynamic>{
      'id': routineExerciseId,
      'routine_id': routineId,
    };
    if (request.sets != null) payload['sets'] = request.sets;
    if (request.repsMin != null) payload['reps_min'] = request.repsMin;
    if (request.repsMax != null) payload['reps_max'] = request.repsMax;
    if (request.restSeconds != null)
      payload['rest_seconds'] = request.restSeconds;
    if (request.orderInRoutine != null)
      payload['order_in_routine'] = request.orderInRoutine;

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
    await _db.deleteRoutineExerciseById(routineExerciseId);
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
      payload: jsonEncode({'id': id, 'name': name, 'description': description}),
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

    return Success(
      StandaloneSession(
        id: id,
        userId: userId,
        programRoutineId: request.programRoutineId,
        startedAt: now,
        exercises: exercises,
      ),
    );
  }

  Future<Result<StandaloneSession?, AppError>> getActiveSession() async {
    // 1. Try local DB first
    final userId = await _userId;
    final localResult = await _readLocalActiveSession(userId);
    if (localResult != null) return Success(localResult);

    // 2. Try server
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneActiveSession,
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      final session = d['session'];
      if (session == null) return const Success(null);
      _cache.putJson(
        _ckActiveSession,
        session as Map<String, dynamic>,
        version: _now(),
      );
      return Success(StandaloneSession.fromJson(session));
    }
    final cached = await _cache.get<Map<String, dynamic>>(
      _ckActiveSession,
      (json) => json,
    );
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
            .map(
              (e) => RoutineExerciseModel(
                id: e.id,
                exerciseId: e.exerciseId,
                sets: e.sets,
                repsMin: e.repsMin,
                repsMax: e.repsMax,
                restSeconds: e.restSeconds,
                orderInRoutine: e.orderInRoutine,
              ),
            )
            .toList();
        return Success((
          session: workoutSession,
          exercises: exercises,
          routineName: session.routineName ?? 'Workout',
        ));
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneSession, AppError>> getSession(
    String sessionId,
  ) async {
    // 1. Try local DB first
    final localResult = await _readLocalSession(sessionId);
    if (localResult != null) return Success(localResult);

    // 2. Try server
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standaloneSessions}/$sessionId',
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      final session = d['session'] as Map<String, dynamic>;
      _cache.putJson(_ckSession(sessionId), session, version: _now());
      return Success(StandaloneSession.fromJson(session));
    }
    final cached = await _cache.get<Map<String, dynamic>>(
      _ckSession(sessionId),
      (json) => json,
    );
    if (cached != null) return Success(StandaloneSession.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<StandaloneSessionListResponse, AppError>> getSessionHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    // 1. Try local DB first
    final userId = await _userId;
    final localResult = await _readLocalSessionHistory(
      userId,
      limit: limit,
      offset: offset,
    );
    if (localResult != null) return Success(localResult);

    // 2. Try server
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
    final cached = await _cache.get<Map<String, dynamic>>(
      _ckSessionsHistory,
      (json) => json,
    );
    if (cached != null)
      return Success(StandaloneSessionListResponse.fromJson(cached));
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
    AppLogger.debug(
      'Starting standalone workout session',
      tag: 'StandaloneRepo',
    );

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
    return Success(
      WorkoutSessionModel(
        id: id,
        userId: userId,
        assignedProgramRoutineId: programRoutineId,
        startedAt: now,
        createdAt: now,
        performedSets: const [],
      ),
    );
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

    return Success(
      StandalonePerformedSet(
        id: id,
        routineExerciseId: request.routineExerciseId,
        setNumber: request.setNumber,
        reps: request.reps,
        weight: request.weight,
        createdAt: now,
      ),
    );
  }

  Future<Result<StandalonePerformedSet, AppError>> updateSet(
    String sessionId,
    String setId,
    UpdateStandaloneSetRequest request,
  ) async {
    await _db.updatePerformedSet(
      setId,
      PerformedSetsCompanion(
        repsCompleted: request.reps != null
            ? Value(request.reps!)
            : const Value.absent(),
        weightKg: request.weight != null
            ? Value(request.weight)
            : const Value.absent(),
      ),
    );

    final payload = <String, dynamic>{'id': setId, 'session_id': sessionId};
    if (request.reps != null) payload['reps'] = request.reps;
    if (request.weight != null) payload['weight'] = request.weight;

    await _outbox.enqueue(
      entityType: 'standalone_set_log',
      operation: 'update',
      payload: jsonEncode(payload),
    );

    return Success(
      StandalonePerformedSet(
        id: setId,
        routineExerciseId: '',
        setNumber: 0,
        reps: request.reps ?? 0,
        weight: request.weight ?? 0,
      ),
    );
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
    // 1. Try local DB first
    final userId = await _userId;
    final localResult = await _readLocalStats(userId);
    if (localResult != null) return Success(localResult);

    // 2. Try server
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneStats,
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      _cache.putJson(_ckStats, d, version: _now());
      return Success(StandaloneStats.fromJson(d));
    }
    final cached = await _cache.get<Map<String, dynamic>>(
      _ckStats,
      (json) => json,
    );
    if (cached != null) return Success(StandaloneStats.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<StandaloneExerciseStat, AppError>> getExerciseStat(
    String exerciseId,
  ) async {
    // 1. Try local DB first
    final userId = await _userId;
    final localResult = await _readLocalExerciseStat(userId, exerciseId);
    if (localResult != null) return Success(localResult);

    // 2. Try server
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standaloneStats}/exercise/$exerciseId',
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final d = result.value;
      _cache.putJson(_ckExerciseStat(exerciseId), d, version: _now());
      return Success(StandaloneExerciseStat.fromJson(d));
    }
    final cached = await _cache.get<Map<String, dynamic>>(
      _ckExerciseStat(exerciseId),
      (json) => json,
    );
    if (cached != null) return Success(StandaloneExerciseStat.fromJson(cached));
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  // ============== LOCAL DB READ HELPERS ==============

  Future<StandaloneProgramListResponse?> _readLocalPrograms(
    String userId,
  ) async {
    try {
      final programs = await _db.getStandalonePrograms(userId);
      if (programs.isEmpty) return null;

      final assignments = await _db.getStandaloneAssignments(userId);
      final activeIds = assignments
          .where((a) => a.isActive)
          .map((a) => a.programId)
          .toSet();

      final routineCounts = <String, int>{};
      for (final p in programs) {
        final routines = await _db.getStandaloneProgramRoutines(p.id);
        routineCounts[p.id] = routines.length;
      }

      return StandaloneProgramListResponse(
        programs: programs
            .map(
              (p) => StandaloneProgram(
                id: p.id,
                name: p.name,
                description: p.description,
                isActive: activeIds.contains(p.id),
                routineCount: routineCounts[p.id] ?? 0,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt,
              ),
            )
            .toList(),
        total: programs.length,
        limit: programs.length,
        offset: 0,
        hasMore: false,
      );
    } catch (e, st) {
      AppLogger.error(
        'Local program list read failed',
        tag: 'StandaloneRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<StandaloneProgramDetail?> _readLocalProgram(String programId) async {
    try {
      final program = await _db.getStandaloneProgramById(programId);
      if (program == null) return null;

      final programRoutines = await _db.getStandaloneProgramRoutines(programId);
      final routines = <StandaloneProgramRoutine>[];
      for (final pr in programRoutines) {
        final routine = await _db.getRoutineById(pr.routineId);
        final exerciseRows = await _db.getRoutineExercises(pr.routineId);
        final exercises = <StandaloneRoutineExercise>[];
        for (final re in exerciseRows) {
          final exercise = await _db.getExerciseById(re.exerciseId);
          exercises.add(
            StandaloneRoutineExercise(
              id: re.id,
              exerciseId: re.exerciseId,
              exerciseName: exercise?.name ?? '',
              sets: re.sets,
              repsMin: re.repsMin,
              repsMax: re.repsMax,
              restSeconds: re.restSeconds,
              orderInRoutine: re.orderInRoutine,
            ),
          );
        }
        routines.add(
          StandaloneProgramRoutine(
            id: pr.id,
            routineId: pr.routineId,
            routineName: routine?.name ?? '',
            routineDescription: routine?.description ?? '',
            orderInProgram: await _db.getStandaloneProgramRoutineOrder(pr.id),
            exercises: exercises,
          ),
        );
      }

      return StandaloneProgramDetail(
        id: program.id,
        name: program.name,
        description: program.description,
        routines: routines,
        createdAt: program.createdAt,
      );
    } catch (e, st) {
      AppLogger.error(
        'Local program read failed',
        tag: 'StandaloneRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<StandaloneProgramDetail?> _readLocalActiveProgram(
    String userId,
  ) async {
    try {
      final assignment = await _db.getActiveStandaloneAssignment(userId);
      if (assignment == null) return null;
      return _readLocalProgram(assignment.programId);
    } catch (e, st) {
      AppLogger.error(
        'Local active program read failed',
        tag: 'StandaloneRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<StandaloneSession?> _readLocalActiveSession(String userId) async {
    try {
      final session = await _db.getActiveStandaloneSession(userId);
      if (session == null || session.standaloneProgramRoutineId == null)
        return null;

      final exercises = await _loadRoutineExercises(
        session.standaloneProgramRoutineId!,
      );
      final performedSets = await _db.getPerformedSets(session.id);

      return StandaloneSession(
        id: session.id,
        userId: session.userId,
        programRoutineId: session.standaloneProgramRoutineId!,
        startedAt: session.startedAt,
        completedAt: session.completedAt,
        feedback: session.notes,
        exercises: exercises,
        performedSets: performedSets
            .map(
              (ps) => StandalonePerformedSet(
                id: ps.id,
                routineExerciseId: ps.assignedProgramRoutineExerciseId,
                setNumber: ps.setNumber,
                reps: ps.repsCompleted,
                weight: ps.weightKg ?? 0,
                createdAt: ps.createdAt,
              ),
            )
            .toList(),
        setCount: performedSets.length,
        createdAt: session.createdAt,
      );
    } catch (e, st) {
      AppLogger.error(
        'Local active session read failed',
        tag: 'StandaloneRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<StandaloneSession?> _readLocalSession(String sessionId) async {
    try {
      final session = await _db.getWorkoutSessionById(sessionId);
      if (session == null) return null;

      final exercises = session.standaloneProgramRoutineId != null
          ? await _loadRoutineExercises(session.standaloneProgramRoutineId!)
          : <StandaloneSessionExercise>[];

      final performedSets = await _db.getPerformedSets(session.id);

      return StandaloneSession(
        id: session.id,
        userId: session.userId,
        programRoutineId: session.standaloneProgramRoutineId ?? '',
        startedAt: session.startedAt,
        completedAt: session.completedAt,
        feedback: session.notes,
        exercises: exercises,
        performedSets: performedSets
            .map(
              (ps) => StandalonePerformedSet(
                id: ps.id,
                routineExerciseId: ps.assignedProgramRoutineExerciseId,
                setNumber: ps.setNumber,
                reps: ps.repsCompleted,
                weight: ps.weightKg ?? 0,
                createdAt: ps.createdAt,
              ),
            )
            .toList(),
        setCount: performedSets.length,
        createdAt: session.createdAt,
      );
    } catch (e, st) {
      AppLogger.error(
        'Local session read failed',
        tag: 'StandaloneRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<StandaloneSessionListResponse?> _readLocalSessionHistory(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final sessions = await _db.getStandaloneCompletedSessions(
        userId,
        limit: 1000,
        offset: 0,
      );
      if (sessions.isEmpty) return null;

      final summaries = <StandaloneSessionSummary>[];
      for (final s in sessions) {
        final setCount = (await _db.getPerformedSets(s.id)).length;
        summaries.add(
          StandaloneSessionSummary(
            id: s.id,
            routineName: '',
            startedAt: s.startedAt,
            completedAt: s.completedAt,
            feedback: s.notes,
            setCount: setCount,
          ),
        );
      }

      final total = summaries.length;
      final paginated = summaries.skip(offset).take(limit).toList();

      return StandaloneSessionListResponse(
        sessions: paginated,
        total: total,
        limit: limit,
        offset: offset,
        hasMore: offset + limit < total,
      );
    } catch (e, st) {
      AppLogger.error(
        'Local session history read failed',
        tag: 'StandaloneRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<StandaloneStats?> _readLocalStats(String userId) async {
    try {
      final sessions = await _db.getStandaloneCompletedSessions(
        userId,
        limit: 10000,
        offset: 0,
      );
      if (sessions.isEmpty) {
        return const StandaloneStats(
          workoutsThisWeek: 0,
          streakDays: 0,
          totalDurationMinutes: 0,
          totalWorkouts: 0,
          totalSets: 0,
        );
      }

      int totalSets = 0;
      int totalDurationMinutes = 0;
      for (final s in sessions) {
        final sets = await _db.getPerformedSets(s.id);
        totalSets += sets.length;
        if (s.completedAt != null) {
          totalDurationMinutes += s.completedAt!
              .difference(s.startedAt)
              .inMinutes;
        }
      }

      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final workoutsThisWeek = sessions
          .where(
            (s) => s.completedAt != null && !s.completedAt!.isBefore(weekStart),
          )
          .length;

      int streakDays = 0;
      final completedDates =
          sessions
              .where((s) => s.completedAt != null)
              .map(
                (s) => DateTime(
                  s.completedAt!.year,
                  s.completedAt!.month,
                  s.completedAt!.day,
                ),
              )
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

      if (completedDates.isNotEmpty) {
        final today = DateTime(now.year, now.month, now.day);
        var checkDate = today;
        for (final date in completedDates) {
          if (date == checkDate) {
            streakDays++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else if (date.isBefore(checkDate)) {
            break;
          }
        }
      }

      return StandaloneStats(
        workoutsThisWeek: workoutsThisWeek,
        streakDays: streakDays,
        totalDurationMinutes: totalDurationMinutes,
        totalWorkouts: sessions.length,
        totalSets: totalSets,
        weekStart: weekStart,
      );
    } catch (e, st) {
      AppLogger.error(
        'Local stats read failed',
        tag: 'StandaloneRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<StandaloneExerciseStat?> _readLocalExerciseStat(
    String userId,
    String exerciseId,
  ) async {
    try {
      final sessions = await _db.getStandaloneCompletedSessions(
        userId,
        limit: 10000,
        offset: 0,
      );

      int? bestReps;
      double? bestWeight;
      int? bestSetNumber;
      DateTime? bestDate;

      for (final s in sessions) {
        final sets = await _db.getPerformedSets(s.id);
        for (final ps in sets) {
          // Resolve exerciseId via RoutineExercise -> exerciseId
          // PerformedSet.assignedProgramRoutineExerciseId = RoutineExercises.id
          final reId = ps.assignedProgramRoutineExerciseId;
          if (reId.isEmpty) continue;

          // Quick check: if we have exercise records, compare
          final re = await (_db.select(
            _db.routineExercises,
          )..where((tbl) => tbl.id.equals(reId))).getSingleOrNull();
          if (re == null || re.exerciseId != exerciseId) continue;

          if (bestDate == null || ps.createdAt.isAfter(bestDate)) {
            bestDate = ps.createdAt;
            bestReps = ps.repsCompleted;
            bestWeight = ps.weightKg;
            bestSetNumber = ps.setNumber;
          }
        }
      }

      if (bestDate == null) return null;

      return StandaloneExerciseStat(
        exerciseId: exerciseId,
        lastSet: StandaloneExerciseLastSet(
          reps: bestReps ?? 0,
          weight: bestWeight ?? 0,
          setNumber: bestSetNumber ?? 0,
          createdAt: bestDate,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Local exercise stat read failed',
        tag: 'StandaloneRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  // ============== HELPERS ==============

  Future<List<StandaloneSessionExercise>> _loadRoutineExercises(
    String programRoutineId,
  ) async {
    try {
      final pr = await (_db.select(
        _db.standaloneProgramRoutines,
      )..where((tbl) => tbl.id.equals(programRoutineId))).getSingleOrNull();
      if (pr == null) return [];

      final exercises = await _db.getRoutineExercises(pr.routineId);
      return exercises
          .map(
            (re) => StandaloneSessionExercise(
              id: re.id,
              exerciseId: re.exerciseId,
              exerciseName: '',
              sets: re.sets,
              repsMin: re.repsMin,
              repsMax: re.repsMax,
              restSeconds: re.restSeconds,
              orderInRoutine: re.orderInRoutine,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
