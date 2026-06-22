import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/cache/cache_service.dart';
import '../../../services/database/app_database.dart';
import '../../../services/outbox/outbox_service.dart';
import '../../../services/storage/secure_storage_service.dart';
import '../../home/data/models/today_status_model.dart';
import '../../subscription/data/models/subscription_model.dart';
import 'models/models.dart';

part 'workout_repository.g.dart';

class WorkoutRepository {
  WorkoutRepository({
    required AppDatabase database,
    required ApiClient apiClient,
    required OutboxService outbox,
    required CacheService cache,
    required SecureStorageService storage,
  }) : _db = database,
       _apiClient = apiClient,
       _outbox = outbox,
       _cache = cache,
       _storage = storage;

  final AppDatabase _db;
  final ApiClient _apiClient;
  final OutboxService _outbox;
  final CacheService _cache;
  final SecureStorageService _storage;

  // ============== Cache keys ==============

  static const _ckExercises = 'exercises';
  static const _ckRoutines = 'routines';
  static const _ckPrograms = 'assigned_programs';
  static const _ckTodayRoutine = 'today_routine';
  static const _ckWeeklyStats = 'unified_weekly_stats';
  static const _ckTodayStatus = 'today_status';
  static String _ckSessionHistory(String source) => 'unified_history_$source';
  static String _ckSessionDetail(String id) => 'session_detail:$id';

  // ============== Exercise Operations ==============

  Future<Result<List<ExerciseModel>, AppError>> getExercises() async {
    try {
      final cached = await _cache.getRaw(_ckExercises);
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final list = (data['exercises'] as List)
            .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Success(list);
      }
      final exercises = await _db.getAllExercises();
      return Success(
        exercises
            .map((e) => ExerciseModel(
                  id: e.id,
                  name: e.name,
                  description: e.description,
                  primaryMuscleGroup: _parseMuscleGroup(e.primaryMuscleGroup),
                  equipmentNeeded: _parseJsonList(e.equipmentNeeded),
                  updatedAt: e.updatedAt,
                ))
            .toList(),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch exercises', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load exercises: $e'));
    }
  }

  Future<Result<List<ExerciseModel>, AppError>> syncExercises() async {
    AppLogger.debug('Syncing exercises from server', tag: 'WorkoutRepo');
    final result = await _apiClient.get<Map<String, dynamic>>(ApiConstants.exercises);
    if (result is Success<Map<String, dynamic>, AppError>) {
      try {
        final data = result.value;
        await _cache.put(
          _ckExercises,
          jsonEncode(data),
          version: DateTime.now().toIso8601String(),
        );
        final list = (data['exercises'] as List)
            .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList();
        AppLogger.info('Synced ${list.length} exercises', tag: 'WorkoutRepo');
        return Success(list);
      } catch (e) {
        AppLogger.error('Failed to parse exercises', tag: 'WorkoutRepo', error: e);
        return Failure(DatabaseError(message: 'Failed to parse exercises: $e'));
      }
    }
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  // ============== Routine Operations ==============

  Future<Result<List<RoutineModel>, AppError>> syncRoutines() async {
    AppLogger.debug('Syncing routines from server', tag: 'WorkoutRepo');
    final result = await _apiClient.get<Map<String, dynamic>>(ApiConstants.routines);
    if (result is Success<Map<String, dynamic>, AppError>) {
      try {
        final data = result.value;
        await _cache.put(
          _ckRoutines,
          jsonEncode(data),
          version: DateTime.now().toIso8601String(),
        );
        final list = (data['routines'] as List)
            .map((r) => RoutineModel.fromJson(r as Map<String, dynamic>))
            .toList();
        AppLogger.info('Synced ${list.length} routines', tag: 'WorkoutRepo');
        return Success(list);
      } catch (e) {
        AppLogger.error('Failed to parse routines', tag: 'WorkoutRepo', error: e);
        return Failure(DatabaseError(message: 'Failed to parse routines: $e'));
      }
    }
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<List<RoutineModel>, AppError>> getRoutines() async {
    try {
      final cached = await _cache.getRaw(_ckRoutines);
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final list = (data['routines'] as List)
            .map((r) => RoutineModel.fromJson(r as Map<String, dynamic>))
            .toList();
        return Success(list);
      }
      final routines = await _db.getAllRoutines();
      final models = <RoutineModel>[];
      for (final r in routines) {
        final exercises = await _db.getRoutineExercises(r.id);
        models.add(RoutineModel(
          id: r.id,
          name: r.name,
          description: r.description,
          estimatedDurationMinutes: r.estimatedDurationMinutes,
          muscleGroupsTargeted: _parseMuscleGroups(r.muscleGroupsTargeted),
          exercises: exercises
              .map((re) => RoutineExerciseModel(
                    id: re.id,
                    exerciseId: re.exerciseId,
                    sets: re.sets,
                    repsMin: re.repsMin,
                    repsMax: re.repsMax,
                    restSeconds: re.restSeconds,
                    orderInRoutine: re.orderInRoutine,
                    notes: re.notes,
                  ))
              .toList(),
          updatedAt: r.updatedAt,
        ));
      }
      return Success(models);
    } catch (e) {
      AppLogger.error('Failed to fetch routines', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load routines: $e'));
    }
  }

  Future<Result<RoutineModel?, AppError>> getRoutineById(String id) async {
    try {
      final routinesResult = await getRoutines();
      if (routinesResult is Success<List<RoutineModel>, AppError>) {
        for (final r in routinesResult.value) {
          if (r.id == id) return Success(r);
          for (final e in r.exercises) {
            if (e.id == id) return Success(r);
          }
        }
      }
      final routine = await _db.getRoutineById(id);
      if (routine == null) return const Success(null);
      final exercises = await _db.getRoutineExercises(id);
      return Success(RoutineModel(
        id: routine.id,
        name: routine.name,
        description: routine.description,
        estimatedDurationMinutes: routine.estimatedDurationMinutes,
        muscleGroupsTargeted: _parseMuscleGroups(routine.muscleGroupsTargeted),
        exercises: exercises
            .map((re) => RoutineExerciseModel(
                  id: re.id,
                  exerciseId: re.exerciseId,
                  sets: re.sets,
                  repsMin: re.repsMin,
                  repsMax: re.repsMax,
                  restSeconds: re.restSeconds,
                  orderInRoutine: re.orderInRoutine,
                  notes: re.notes,
                ))
            .toList(),
        updatedAt: routine.updatedAt,
      ));
    } catch (e) {
      AppLogger.error('Failed to fetch routine', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load routine: $e'));
    }
  }

  Future<Result<RoutineModel?, AppError>> getRoutineByModelId(
    String modelId,
  ) async {
    try {
      final programsResult = await getPrograms();
      if (programsResult is Success<List<AssignedProgramModel>, AppError>) {
        for (final p in programsResult.value) {
          for (final r in p.routines) {
            if (r.id == modelId) return Success(r);
          }
        }
      }
      final routinesResult = await getRoutines();
      if (routinesResult is Success<List<RoutineModel>, AppError>) {
        for (final r in routinesResult.value) {
          if (r.id == modelId) return Success(r);
        }
      }
      return const Success(null);
    } catch (e) {
      AppLogger.error('Failed to fetch routine', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load routine: $e'));
    }
  }

  // ============== Program Operations ==============

  Future<Result<List<AssignedProgramModel>, AppError>> syncPrograms() async {
    AppLogger.debug('Syncing programs from server', tag: 'WorkoutRepo');
    final result = await _apiClient.get<Map<String, dynamic>>(ApiConstants.workoutPrograms);
    if (result is Success<Map<String, dynamic>, AppError>) {
      try {
        final data = result.value;
        await _cache.put(
          _ckPrograms,
          jsonEncode(data),
          version: DateTime.now().toIso8601String(),
        );
        final list = (data['programs'] as List)
            .map((p) => AssignedProgramModel.fromJson(p as Map<String, dynamic>))
            .toList();
        AppLogger.info('Synced ${list.length} programs', tag: 'WorkoutRepo');
        return Success(list);
      } catch (e) {
        AppLogger.error('Failed to parse programs', tag: 'WorkoutRepo', error: e);
        return Failure(DatabaseError(message: 'Failed to parse programs: $e'));
      }
    }
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<List<AssignedProgramModel>, AppError>> getPrograms() async {
    try {
      final cached = await _cache.getRaw(_ckPrograms);
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final list = (data['programs'] as List)
            .map((p) => AssignedProgramModel.fromJson(p as Map<String, dynamic>))
            .toList();
        return Success(list);
      }
      return const Success([]);
    } catch (e) {
      AppLogger.error('Failed to load programs from cache', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load programs: $e'));
    }
  }

  // ============== Workout Session Operations ==============

  Future<Result<WorkoutSessionModel?, AppError>> getActiveSession(
    String userId,
  ) async {
    try {
      final session = await _db.getActiveWorkoutSession(userId);
      if (session == null) return const Success(null);
      final sets = await _db.getPerformedSets(session.id);
      return Success(_mapWorkoutSession(session, sets));
    } catch (e) {
      AppLogger.error('Failed to get active session', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to get session: $e'));
    }
  }

  Future<Result<WorkoutSessionModel, AppError>> startWorkoutSession({
    required String userId,
    String? routineModelId,
    String? assignedProgramId,
  }) async {
    try {
      AppLogger.info('Starting workout session', tag: 'WorkoutRepo');
      final id = _outbox.newId();
      final now = DateTime.now();

      await _db.insertWorkoutSession(
        WorkoutSessionsCompanion.insert(
          id: id,
          userId: userId,
          assignedProgramRoutineId: Value(routineModelId),
          startedAt: now,
          createdAt: now,
        ),
      );

      await _outbox.enqueue(
        entityType: 'workout_session',
        operation: 'create',
        payload: jsonEncode({
          'id': id,
          'assignedProgramRoutineId': routineModelId,
        }),
      );

      final session = await _db.getWorkoutSessionById(id);
      if (session == null) {
        return const Failure(DatabaseError(message: 'Failed to create session'));
      }
      AppLogger.info('Workout session started: $id', tag: 'WorkoutRepo');
      return Success(_mapWorkoutSession(session, []));
    } catch (e) {
      AppLogger.error('Failed to start session', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to start session: $e'));
    }
  }

  Future<Result<WorkoutSessionModel?, AppError>> getWorkoutSession(
    String sessionId,
  ) async {
    try {
      final session = await _db.getWorkoutSessionById(sessionId);
      if (session == null) return const Success(null);
      final sets = await _db.getPerformedSets(session.id);
      return Success(_mapWorkoutSession(session, sets));
    } catch (e) {
      AppLogger.error('Failed to get session', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to get session: $e'));
    }
  }

  Future<Result<WorkoutSessionModel, AppError>> completeWorkoutSession({
    required String sessionId,
    String? notes,
  }) async {
    try {
      AppLogger.info('Completing workout session: $sessionId', tag: 'WorkoutRepo');
      await _db.completeWorkoutSession(sessionId, notes: notes);

      await _outbox.enqueue(
        entityType: 'workout_session',
        operation: 'complete',
        payload: jsonEncode({
          'sessionId': sessionId,
          'notes': notes,
          'completedAt': DateTime.now().toIso8601String(),
        }),
      );

      final session = await _db.getWorkoutSessionById(sessionId);
      final sets = await _db.getPerformedSets(sessionId);
      AppLogger.info('Workout session completed', tag: 'WorkoutRepo');
      return Success(_mapWorkoutSession(session!, sets));
    } catch (e) {
      AppLogger.error('Failed to complete session', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to complete session: $e'));
    }
  }

  Future<Result<WorkoutSessionModel?, AppError>> getTodayCompletedSession({
    required String userId,
    required String routineModelId,
  }) async {
    try {
      final session = await _db.getTodayCompletedSessionForRoutine(
        userId,
        routineModelId,
      );
      if (session == null) return const Success(null);
      final sets = await _db.getPerformedSets(session.id);
      return Success(_mapWorkoutSession(session, sets));
    } catch (e) {
      AppLogger.error('Failed to get today completed session', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to get today session: $e'));
    }
  }

  Future<Result<List<WorkoutSessionModel>, AppError>> getWorkoutHistory(
    String userId,
  ) async {
    try {
      final sessions = await _db.getWorkoutSessions(userId);
      final models = <WorkoutSessionModel>[];
      for (final s in sessions) {
        final sets = await _db.getPerformedSets(s.id);
        models.add(_mapWorkoutSession(s, sets));
      }
      return Success(models);
    } catch (e) {
      AppLogger.error('Failed to get history', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load history: $e'));
    }
  }

  Future<Result<WorkoutHistoryResponse, AppError>> getLocalSessionHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final sessions = await _db.getCompletedSessions(userId, limit: limit, offset: offset);
      final total = await _db.countCompletedSessions(userId);
      final summaries = <WorkoutSessionSummary>[];
      for (final s in sessions) {
        final sets = await _db.getPerformedSets(s.id);
        summaries.add(WorkoutSessionSummary(
          id: s.id,
          userId: s.userId,
          assignedProgramId: s.assignedProgramRoutineId,
          startedAt: s.startedAt,
          completedAt: s.completedAt,
          notes: s.notes,
          totalSets: sets.length,
        ));
      }
      return Success(WorkoutHistoryResponse(
        sessions: summaries,
        pagination: WorkoutHistoryPagination(
          total: total,
          limit: limit,
          offset: offset,
          hasMore: offset + sessions.length < total,
        ),
      ));
    } catch (e) {
      AppLogger.error('Failed to get local history', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load history: $e'));
    }
  }

  Future<Result<List<WorkoutSessionSummary>, AppError>> getLocalSessionsForMonth(
    String userId,
    DateTime month,
  ) async {
    try {
      final firstDay = DateTime(month.year, month.month, 1, 0, 0, 0);
      final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
      final sessions = await _db.getCompletedSessionsInRange(userId, firstDay, lastDay);
      final summaries = <WorkoutSessionSummary>[];
      for (final s in sessions) {
        final sets = await _db.getPerformedSets(s.id);
        summaries.add(WorkoutSessionSummary(
          id: s.id,
          userId: s.userId,
          assignedProgramId: s.assignedProgramRoutineId,
          startedAt: s.startedAt,
          completedAt: s.completedAt,
          notes: s.notes,
          totalSets: sets.length,
        ));
      }
      return Success(summaries);
    } catch (e) {
      AppLogger.error('Failed to get local sessions for month', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load calendar data: $e'));
    }
  }

  Future<Result<List<WorkoutSessionSummary>, AppError>> getServerSessionsForMonth(
    DateTime month,
  ) async {
    try {
      final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final result = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.sessionCalendar,
        queryParameters: {'month': monthStr},
      );
      return result.when(
        success: (data) {
          final sessionsList = (data['sessions'] as List? ?? []);
          final summaries = <WorkoutSessionSummary>[];
          for (final json in sessionsList) {
            final s = json as Map<String, dynamic>;
            final startedAtStr = s['startedAt'] as String?;
            if (startedAtStr == null) continue;
            final completedAtStr = s['completedAt'] as String?;
            summaries.add(WorkoutSessionSummary(
              id: s['id'] as String,
              userId: '',
              startedAt: DateTime.parse(startedAtStr),
              completedAt: completedAtStr != null ? DateTime.parse(completedAtStr) : null,
              totalSets: (s['totalSets'] as num?)?.toInt() ?? 0,
              routineName: s['routineName'] as String?,
              source: s['source'] as String?,
            ));
          }
          AppLogger.info('Fetched ${summaries.length} sessions from server calendar', tag: 'WorkoutRepo');
          return Success(summaries);
        },
        failure: (error) {
          AppLogger.warning('Server calendar fetch failed: ${error.message}', tag: 'WorkoutRepo');
          return Failure(error);
        },
      );
    } catch (e) {
      AppLogger.error('Failed to fetch server calendar sessions', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load server calendar data: $e'));
    }
  }

  // ============== Performed Set Operations ==============

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
    String? exerciseNameSnapshot,
    int? targetRepsMin,
    int? targetRepsMax,
    int? targetRestSeconds,
    double? targetWeightKg,
  }) async {
    try {
      final id = _outbox.newId();
      final now = DateTime.now();

      await _db.logSet(
        id: id,
        workoutSessionId: workoutSessionModelId,
        assignedProgramRoutineExerciseId: routineExerciseModelId,
        setNumber: setNumber,
        repsCompleted: repsCompleted,
        weightKg: weightKg,
        rpe: rpe,
        notes: notes,
        recordedFramesKey: recordedFramesKey,
        overallScore: overallScore,
        exerciseNameSnapshot: exerciseNameSnapshot,
        targetRepsMin: targetRepsMin,
        targetRepsMax: targetRepsMax,
        targetRestSeconds: targetRestSeconds,
        targetWeightKg: targetWeightKg,
      );

      await _outbox.enqueue(
        entityType: 'set_log',
        operation: 'create',
        payload: jsonEncode({
          'id': id,
          'workoutSessionId': workoutSessionModelId,
          'assignedProgramRoutineExerciseId': routineExerciseModelId,
          'setNumber': setNumber,
          'repsCompleted': repsCompleted,
          'weightKg': weightKg,
          'rpe': rpe,
          'notes': notes,
          if (recordedFramesKey != null) 'recordedFramesKey': recordedFramesKey,
          if (overallScore != null) 'overallScore': overallScore,
        }),
      );

      return Success(PerformedSetModel(
        id: id,
        workoutSessionId: workoutSessionModelId,
        assignedProgramRoutineExerciseId: routineExerciseModelId,
        setNumber: setNumber,
        repsCompleted: repsCompleted,
        weightKg: weightKg,
        rpe: rpe,
        notes: notes,
        isCompleted: true,
        exerciseNameSnapshot: exerciseNameSnapshot,
        targetRepsMin: targetRepsMin,
        targetRepsMax: targetRepsMax,
        targetRestSeconds: targetRestSeconds,
        targetWeightKg: targetWeightKg,
        createdAt: now,
      ));
    } catch (e) {
      AppLogger.error('Failed to log set', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to log set: $e'));
    }
  }

  Future<Result<PerformedSetModel, AppError>> updateSet({
    required String setId,
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
          repsCompleted: repsCompleted != null ? Value(repsCompleted) : const Value.absent(),
          weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
          rpe: rpe != null ? Value(rpe) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
          isCompleted: isCompleted != null ? Value(isCompleted) : const Value.absent(),
        ),
      );

      await _outbox.enqueue(
        entityType: 'set_log',
        operation: 'update',
        payload: jsonEncode({
          'id': setId,
          if (repsCompleted != null) 'repsCompleted': repsCompleted,
          if (weightKg != null) 'weightKg': weightKg,
          if (rpe != null) 'rpe': rpe,
          if (notes != null) 'notes': notes,
          if (isCompleted != null) 'isCompleted': isCompleted,
        }),
      );

      return Success(PerformedSetModel(
        id: setId,
        workoutSessionId: '',
        assignedProgramRoutineExerciseId: '',
        setNumber: 0,
        repsCompleted: repsCompleted ?? 0,
        weightKg: weightKg,
        rpe: rpe,
        notes: notes,
        isCompleted: isCompleted ?? false,
      ));
    } catch (e) {
      AppLogger.error('Failed to update set', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to update set: $e'));
    }
  }

  Future<Result<void, AppError>> deleteSet(String setId) async {
    try {
      await _db.deletePerformedSet(setId);
      return const Success(null);
    } catch (e) {
      AppLogger.error('Failed to delete set', tag: 'WorkoutRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to delete set: $e'));
    }
  }

  Future<Result<List<PerformedSetModel>, AppError>> getSetsForExercise({
    required String workoutSessionId,
    required String assignedProgramRoutineExerciseId,
  }) async {
    try {
      final sets = await _db.getPerformedSetsForExercise(
        workoutSessionId,
        assignedProgramRoutineExerciseId,
      );
      return Success(
        sets
            .map((s) => PerformedSetModel(
                  id: s.id,
                  workoutSessionId: s.workoutSessionId,
                  assignedProgramRoutineExerciseId: s.assignedProgramRoutineExerciseId,
                  setNumber: s.setNumber,
                  repsCompleted: s.repsCompleted,
                  weightKg: s.weightKg,
                  rpe: s.rpe,
                  notes: s.notes,
                  isCompleted: s.isCompleted,
                  exerciseNameSnapshot: s.exerciseNameSnapshot,
                  targetRepsMin: s.targetRepsMin,
                  targetRepsMax: s.targetRepsMax,
                  targetRestSeconds: s.targetRestSeconds,
                  targetWeightKg: s.targetWeightKg,
                  createdAt: s.createdAt,
                ))
            .toList(),
      );
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

  WorkoutSessionModel _mapWorkoutSession(
    WorkoutSession session,
    List<PerformedSet> sets,
  ) {
    return WorkoutSessionModel(
      id: session.id,
      userId: session.userId,
      assignedProgramRoutineId: session.assignedProgramRoutineId,
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      notes: session.notes,
      performedSets: sets
          .map((s) => PerformedSetModel(
                id: s.id,
                workoutSessionId: s.workoutSessionId,
                assignedProgramRoutineExerciseId: s.assignedProgramRoutineExerciseId,
                setNumber: s.setNumber,
                repsCompleted: s.repsCompleted,
                weightKg: s.weightKg,
                rpe: s.rpe,
                notes: s.notes,
                isCompleted: s.isCompleted,
                exerciseNameSnapshot: s.exerciseNameSnapshot,
                targetRepsMin: s.targetRepsMin,
                targetRepsMax: s.targetRepsMax,
                targetRestSeconds: s.targetRestSeconds,
                targetWeightKg: s.targetWeightKg,
                createdAt: s.createdAt,
              ))
          .toList(),
      createdAt: session.createdAt,
    );
  }

  // ============== Today Routine + Status ==============

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
        _cache.put(_ckTodayRoutine, jsonEncode(data), version: DateTime.now().toIso8601String());
        return Success(model);
      } catch (e) {
        AppLogger.error('Failed to parse today routine', tag: 'WorkoutRepo', error: e);
        return Failure(UnknownError(message: 'Failed to parse today routine: $e', originalError: e));
      }
    }
    AppLogger.warning('Server unavailable — trying cached today routine', tag: 'WorkoutRepo');
    try {
      final cached = await _cache.getRaw(_ckTodayRoutine);
      if (cached != null) {
        final model = TodayRoutineModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        AppLogger.info('Loaded today routine from cache', tag: 'WorkoutRepo');
        return Success(model);
      }
    } catch (e) {
      AppLogger.error('Failed to load cached today routine', tag: 'WorkoutRepo', error: e);
    }
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<TodayStatusModel, AppError>> getTodayStatus() async {
    AppLogger.debug('Fetching today status', tag: 'WorkoutRepo');
    final result = await _apiClient.get<Map<String, dynamic>>(ApiConstants.todayStatus);
    if (result is Success<Map<String, dynamic>, AppError>) {
      try {
        final model = TodayStatusModel.fromJson(result.value);
        AppLogger.info(
          'Today status: isCoach=${model.isCoach} subscribed=${model.isSubscribed} hasSubscribedCoach=${model.hasCoach}',
          tag: 'WorkoutRepo',
        );
        _cache.put(_ckTodayStatus, jsonEncode(result.value), version: DateTime.now().toIso8601String());
        return Success(model);
      } catch (e) {
        AppLogger.error('Failed to parse today status', tag: 'WorkoutRepo', error: e);
        return Failure(UnknownError(message: 'Failed to parse today status: $e', originalError: e));
      }
    }
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    if (_shouldFallbackToLegacyTodayStatus(failure.error)) {
      AppLogger.warning('GET /today unavailable (404), using legacy today endpoints fallback', tag: 'WorkoutRepo');
      final legacyStatus = await _buildLegacyTodayStatus();
      if (legacyStatus != null) {
        AppLogger.info('Loaded today status via legacy fallback', tag: 'WorkoutRepo');
        return Success(legacyStatus);
      }
    }
    AppLogger.warning('Server today status unavailable — trying offline derivation', tag: 'WorkoutRepo');
    final offlineStatus = await _buildTodayStatusOffline();
    if (offlineStatus != null) {
      AppLogger.info('Loaded today status via offline derivation', tag: 'WorkoutRepo');
      return Success(offlineStatus);
    }
    AppLogger.error('Failed to fetch today status', tag: 'WorkoutRepo', error: failure.error);
    return Failure(failure.error);
  }

  bool _shouldFallbackToLegacyTodayStatus(AppError error) {
    return error is NetworkError && error.statusCode == 404;
  }

  Future<TodayStatusModel?> _buildLegacyTodayStatus() async {
    try {
      bool isSubscribed = false;
      TodaySubscriptionInfo? subscription;
      final subscriptionResult = await _apiClient.get<Map<String, dynamic>>(ApiConstants.subscriptionStatus);
      if (subscriptionResult is Success<Map<String, dynamic>, AppError>) {
        final data = subscriptionResult.value;
        isSubscribed = _asBool(data['isSubscribed']) ?? false;
        subscription = _parseLegacySubscriptionInfo(data['subscription']);
      }
      bool hasCoach = false;
      final subscribedCoachesResult = await _apiClient.get<Map<String, dynamic>>(ApiConstants.subscribedCoaches);
      if (subscribedCoachesResult is Success<Map<String, dynamic>, AppError>) {
        final data = subscribedCoachesResult.value;
        final coaches = data['coaches'];
        hasCoach = coaches is List && coaches.isNotEmpty;
      }
      TodayWorkoutDetails? coachToday;
      if (isSubscribed) {
        final coachTodayResult = await _apiClient.get<Map<String, dynamic>>(ApiConstants.todayWorkout);
        if (coachTodayResult is Success<Map<String, dynamic>, AppError>) {
          coachToday = _parseLegacyTodayDetails(coachTodayResult.value);
          hasCoach = hasCoach || coachToday != null;
        }
      }
      return TodayStatusModel(
        isSubscribed: isSubscribed,
        hasCoach: hasCoach,
        subscription: subscription,
        coachToday: coachToday,
        standalone: const StandaloneStatus(),
      );
    } catch (e) {
      AppLogger.error('Legacy today fallback failed', tag: 'WorkoutRepo', error: e);
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
    final tierLevel = _asInt(sub['tierLevel']) ?? _asInt(plan?['tierLevel']) ?? 0;
    if (id == null || status == null || currentPeriodEnd == null) return null;
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
    final isRestDay = _asBool(payload['isRestDay']) ?? _asBool(payload['is_rest_day']) ?? false;
    final todayNode = payload['today'];
    if (todayNode == null) {
      return isRestDay ? const TodayWorkoutDetails(isRestDay: true) : null;
    }
    final todayMap = _asMap(todayNode);
    if (todayMap != null) return _toTodayWorkoutDetails(todayMap, isRestDay: isRestDay);
    if (todayNode is List && todayNode.isNotEmpty) {
      final first = _asMap(todayNode.first);
      if (first != null) return _toTodayWorkoutDetails(first, isRestDay: isRestDay);
    }
    return isRestDay ? const TodayWorkoutDetails(isRestDay: true) : null;
  }

  TodayWorkoutDetails _toTodayWorkoutDetails(Map<String, dynamic> data, {required bool isRestDay}) {
    final routine = _asMap(data['routine']);
    final dayOfWeek = _asString(data['dayOfWeek']) ??
        _extractFirstDayName(data['daysOfWeek']) ??
        _extractFirstDayName(data['days_of_week']);
    final exerciseCount = _asInt(data['exerciseCount']) ??
        _asInt(data['exercise_count']) ??
        (routine?['exercises'] is List ? (routine!['exercises'] as List).length : null) ??
        (data['assigned_program_routine_exercises'] is List
            ? (data['assigned_program_routine_exercises'] as List).length
            : null) ??
        0;
    final estimatedMinutes = _asInt(data['estimatedMinutes']) ??
        _asInt(data['estimated_duration_minutes']) ??
        _asInt(routine?['estimatedDurationMinutes']) ??
        _asInt(routine?['estimated_duration_minutes']) ??
        0;
    return TodayWorkoutDetails(
      isRestDay: isRestDay,
      programRoutineId: _asString(data['programRoutineId']) ??
          _asString(data['assignedProgramRoutineId']) ??
          _asString(data['id']),
      dayOfWeek: dayOfWeek,
      dayNumber: _asInt(data['dayNumber']),
      programName: _asString(data['programName']) ?? _asString(data['program_name']),
      routineName: _asString(data['routineName']) ?? _asString(routine?['name']),
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
    if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
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

  // ============== Today Status Offline Derivation ==============

  Future<TodayStatusModel?> _buildTodayStatusOffline() async {
    try {
      // 1. Check cached subscription status
      bool isSubscribed = false;
      TodaySubscriptionInfo? subscription;
      final subCache = await _cache.getRaw('subscription_status');
      if (subCache != null) {
        final subData = jsonDecode(subCache) as Map<String, dynamic>;
        isSubscribed = _asBool(subData['isSubscribed']) ?? false;
        final rawSub = _asMap(subData['subscription']);
        if (rawSub != null) {
          final id = _asString(rawSub['id']);
          final status = _parseSubscriptionStatus(rawSub['status']);
          final currentPeriodEnd = _parseDateTime(rawSub['currentPeriodEnd']);
          final plan = _asMap(rawSub['plan']);
          final tierLevel = _asInt(rawSub['tierLevel']) ?? _asInt(plan?['tierLevel']) ?? 0;
          if (id != null && status != null && currentPeriodEnd != null) {
            subscription = TodaySubscriptionInfo(
              id: id,
              status: status,
              tierLevel: tierLevel,
              currentPeriodEnd: currentPeriodEnd,
            );
          }
        }
      }

      // 2. Check cached assigned programs for today's workout
      bool hasCoach = false;
      TodayWorkoutDetails? coachToday;
      final programsCache = await _cache.getRaw(_ckPrograms);
      if (programsCache != null) {
        final programsData = jsonDecode(programsCache) as Map<String, dynamic>;
        final programsList = programsData['programs'] as List?;
        if (programsList != null && programsList.isNotEmpty) {
          hasCoach = true;

          final todayDayName = _getTodayDayName();
          final userId = await _storage.getUserId();

          for (final p in programsList) {
            final program = _asMap(p);
            if (program == null) continue;
            if (!(_asBool(program['isActive']) ?? true)) continue;

            final routines = program['routines'];
            if (routines is! List || routines.isEmpty) continue;

            for (final r in routines) {
              final routine = _asMap(r);
              if (routine == null) continue;

              final daysOfWeek = routine['daysOfWeek'];
              final List<String> days = daysOfWeek is List
                  ? daysOfWeek.map((d) => d.toString().toUpperCase()).toList()
                  : <String>[];

              if (!days.contains(todayDayName)) continue;

              final programRoutineId = _asString(routine['id']);
              final routineName = _asString(routine['name']);
              final exercises = routine['exercises'] is List ? routine['exercises'] as List : <dynamic>[];
              final estimatedMinutes = _asInt(routine['estimatedDurationMinutes']) ??
                  _asInt(routine['estimated_duration_minutes']) ?? 0;

              // Check if completed today
              bool completedToday = false;
              if (programRoutineId != null && userId != null) {
                final completed = await _db.getTodayCompletedSessionForRoutine(
                  userId,
                  programRoutineId,
                );
                completedToday = completed != null;
              }

              coachToday = TodayWorkoutDetails(
                isRestDay: false,
                programRoutineId: programRoutineId,
                dayOfWeek: todayDayName,
                programName: _asString(program['name']),
                routineName: routineName,
                exerciseCount: exercises.length,
                estimatedMinutes: estimatedMinutes,
                completedToday: completedToday,
              );
              break; // Found today's routine
            }
            if (coachToday != null) break;
          }
        }
      }

      if (coachToday == null && !hasCoach) {
        // Check cached today status for standalone info
        final todayCache = await _cache.getRaw(_ckTodayStatus);
        if (todayCache != null) {
          final todayData = jsonDecode(todayCache) as Map<String, dynamic>;
          final standalone = todayData['standalone'] as Map<String, dynamic>?;
          if (standalone != null) {
            return TodayStatusModel(
              isSubscribed: isSubscribed,
              hasCoach: hasCoach,
              subscription: subscription,
              standalone: StandaloneStatus.fromJson(standalone),
            );
          }
        }
        return TodayStatusModel(
          isSubscribed: isSubscribed,
          hasCoach: hasCoach,
          subscription: subscription,
        );
      }

      return TodayStatusModel(
        isSubscribed: isSubscribed,
        hasCoach: hasCoach,
        subscription: subscription,
        coachToday: coachToday,
      );
    } catch (e, st) {
      AppLogger.error('Offline today status derivation failed', tag: 'WorkoutRepo', error: e, stackTrace: st);
      return null;
    }
  }

  String _getTodayDayName() {
    const days = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
      'FRIDAY', 'SATURDAY', 'SUNDAY',
    ];
    return days[DateTime.now().weekday - 1];
  }

  // ============== Stats Operations ==============

  Future<Result<WeeklyStatsModel, AppError>> getWeeklyStats({DateTime? weekOf}) async {
    AppLogger.debug('Fetching weekly stats from server', tag: 'WorkoutRepo');
    final queryParams = <String, dynamic>{
      if (weekOf != null) 'weekOf': '${weekOf.toUtc().toIso8601String().split('.')[0]}Z',
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
            'Weekly stats: ${model.workoutsCompleted} workouts, ${model.totalMinutes}min, ${model.streakDays} streak',
            tag: 'WorkoutRepo',
          );
          return Success(model);
        } catch (e) {
          AppLogger.error('Failed to parse weekly stats', tag: 'WorkoutRepo', error: e);
          return Failure(UnknownError(message: 'Failed to parse weekly stats: $e', originalError: e));
        }
      },
      failure: (error) {
        AppLogger.error('Failed to fetch weekly stats', tag: 'WorkoutRepo', error: error);
        return Failure(error);
      },
    );
  }

  Future<Result<UnifiedWeeklyStats, AppError>> getUnifiedWeeklyStats({DateTime? weekOf}) async {
    AppLogger.debug('Fetching unified weekly stats from server', tag: 'WorkoutRepo');
    final queryParams = <String, dynamic>{
      if (weekOf != null) 'weekOf': '${weekOf.toUtc().toIso8601String().split('.')[0]}Z',
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
          'Unified weekly stats: ${model.workoutsCompleted} workouts, ${model.totalMinutes}min, ${model.streakDays} streak, ${model.sources.length} sources',
          tag: 'WorkoutRepo',
        );
        _cache.put(_ckWeeklyStats, jsonEncode(data), version: DateTime.now().toIso8601String());
        return Success(model);
      } catch (e) {
        AppLogger.error('Failed to parse unified weekly stats', tag: 'WorkoutRepo', error: e);
        return Failure(UnknownError(message: 'Failed to parse unified weekly stats: $e', originalError: e));
      }
    }
    AppLogger.warning('Server unavailable — trying cached weekly stats', tag: 'WorkoutRepo');
    try {
      final cached = await _cache.getRaw(_ckWeeklyStats);
      if (cached != null) {
        final model = UnifiedWeeklyStats.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        AppLogger.info('Loaded weekly stats from cache', tag: 'WorkoutRepo');
        return Success(model);
      }
    } catch (e) {
      AppLogger.error('Failed to load cached weekly stats', tag: 'WorkoutRepo', error: e);
    }
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  Future<Result<MonthlyInsight, AppError>> getMonthlyInsight(String month) async {
    AppLogger.debug('Fetching monthly insight: $month', tag: 'WorkoutRepo');
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.monthlyInsight,
      queryParameters: {'month': month},
    );
    return result.when(
      success: (data) {
        try {
          final model = MonthlyInsight.fromJson(data);
          AppLogger.info(
            'Monthly insight: ${model.volumeDisplay}, trend=${model.trendDisplay}, ${model.exerciseImprovements.length} improvements',
            tag: 'WorkoutRepo',
          );
          return Success(model);
        } catch (e) {
          AppLogger.error('Failed to parse monthly insight', tag: 'WorkoutRepo', error: e);
          return Failure(UnknownError(message: 'Failed to parse monthly insight: $e', originalError: e));
        }
      },
      failure: (error) {
        AppLogger.error('Failed to fetch monthly insight', tag: 'WorkoutRepo', error: error);
        return Failure(error);
      },
    );
  }

  // ============== Session History (Server) ==============

  Future<Result<WorkoutHistoryResponse, AppError>> getSessionHistory({
    int limit = 20,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.debug('Fetching session history: limit=$limit, offset=$offset', tag: 'WorkoutRepo');
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (startDate != null) 'startDate': '${startDate.toUtc().toIso8601String().split('.')[0]}Z',
      if (endDate != null) 'endDate': '${endDate.toUtc().toIso8601String().split('.')[0]}Z',
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
            'Fetched ${response.sessions.length} sessions (total: ${response.pagination.total})',
            tag: 'WorkoutRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error('Failed to parse session history', tag: 'WorkoutRepo', error: e);
          return Failure(UnknownError(message: 'Failed to parse session history: $e', originalError: e));
        }
      },
      failure: (error) {
        AppLogger.error('Failed to fetch session history', tag: 'WorkoutRepo', error: error);
        return Failure(error);
      },
    );
  }

  // ============== Session Detail (Server + Cache) ==============

  Future<Result<UnifiedSessionDetail?, AppError>> getSessionDetail(
    String sessionId,
  ) async {
    try {
      // 1. Try cache first
      final cachedRaw = await _cache.getRaw(_ckSessionDetail(sessionId));
      if (cachedRaw != null) {
        final json = jsonDecode(cachedRaw) as Map<String, dynamic>;
        final sessionJson = json['session'] as Map<String, dynamic>?;
        if (sessionJson != null) {
          return Success(UnifiedSessionDetail.fromJson(sessionJson));
        }
      }

      // 2. Fetch from server
      final result = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.sessionDetail(sessionId),
      );

      return result.when(
        success: (data) {
          _cache.putJson(
            _ckSessionDetail(sessionId),
            data,
            version: DateTime.now().toIso8601String(),
          );
          final sessionJson = data['session'] as Map<String, dynamic>?;
          if (sessionJson == null) return const Success(null);
          return Success(UnifiedSessionDetail.fromJson(sessionJson));
        },
        failure: (error) => Failure(error),
      );
    } catch (e) {
      return Failure(UnknownError(message: e.toString()));
    }
  }

  // ============== Unified Session History (Server + Cache) ==============

  Future<Result<UnifiedSessionHistoryResponse, AppError>> getUnifiedSessionHistory({
    String source = 'all',
    int limit = 20,
    int offset = 0,
  }) async {
    AppLogger.debug(
      'Fetching unified session history: source=$source, limit=$limit, offset=$offset',
      tag: 'WorkoutRepo',
    );
    final queryParams = <String, dynamic>{
      'source': source,
      'limit': limit,
      'offset': offset,
    };
    final cacheKey = _ckSessionHistory(source);
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.unifiedSessionHistory,
      queryParameters: queryParams,
    );
    if (result is Success<Map<String, dynamic>, AppError>) {
      final data = result.value;
      try {
        final response = UnifiedSessionHistoryResponse.fromJson(data);
        AppLogger.info(
          'Fetched ${response.sessions.length} unified sessions (total: ${response.pagination.total}, source: $source)',
          tag: 'WorkoutRepo',
        );
        if (offset == 0) {
          _cache.put(cacheKey, jsonEncode(data), version: DateTime.now().toIso8601String());
        }
        return Success(response);
      } catch (e) {
        AppLogger.error('Failed to parse unified session history', tag: 'WorkoutRepo', error: e);
        return Failure(UnknownError(message: 'Failed to parse unified session history: $e', originalError: e));
      }
    }
    final failure = result as Failure<Map<String, dynamic>, AppError>;
    if (offset == 0) {
      return _loadCachedUnifiedHistory(cacheKey, failure.error);
    }
    return Failure(failure.error);
  }

  Future<Result<UnifiedSessionHistoryResponse, AppError>> _loadCachedUnifiedHistory(
    String cacheKey,
    AppError originalError,
  ) async {
    try {
      final cached = await _cache.getRaw(cacheKey);
      if (cached != null) {
        AppLogger.info('Loaded cached unified history ($cacheKey)', tag: 'WorkoutRepo');
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final response = UnifiedSessionHistoryResponse.fromJson(data);
        return Success(response);
      }
    } catch (e) {
      AppLogger.warning('Failed to read cached unified history: $e', tag: 'WorkoutRepo');
    }
    return Failure(originalError);
  }
}

@Riverpod(keepAlive: true)
WorkoutRepository workoutRepository(Ref ref) {
  return WorkoutRepository(
    database: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
    outbox: ref.watch(outboxServiceProvider),
    cache: ref.watch(cacheServiceProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
}
