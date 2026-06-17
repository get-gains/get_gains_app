import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

part 'app_database.g.dart';

// ============== Table Definitions ==============

/// Example table - Users (local cache)
/// Add your tables here following this pattern
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get email => text().unique()();
  TextColumn get name => text()();
  TextColumn get avatarUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Sync tracking
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
}

/// Example table - Sync Queue
/// Tracks local changes that need to be synced to the server
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityTable => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

// ============== Workout Tables ==============

/// Exercises table - Exercise library
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get primaryMuscleGroup => text()();
  TextColumn get equipmentNeeded => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

/// Routines table - Workout routines
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  IntColumn get estimatedDurationMinutes => integer()();
  TextColumn get muscleGroupsTargeted =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

/// Routine Exercises table - Junction table for routine-exercise relationship
class RoutineExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get routineId =>
      integer().references(Routines, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get sets => integer()();
  IntColumn get repsMin => integer()();
  IntColumn get repsMax => integer()();
  IntColumn get restSeconds => integer()();
  IntColumn get orderInRoutine => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

/// Workout Sessions table - User workout sessions
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get assignedProgramRoutineId => text().nullable()();
  IntColumn get routineId => integer().nullable().references(
    Routines,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

/// Performed Sets table - Individual sets logged by user
class PerformedSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get workoutSessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();

  /// Server-side assigned_program_routine_exercise CUID.
  /// Stored directly — no local FK lookup required.
  TextColumn get assignedProgramRoutineExerciseId => text()();
  IntColumn get setNumber => integer()();
  IntColumn get repsCompleted => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get rpe => integer().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get recordedFramesKey => text().nullable()();
  RealColumn get overallScore => real().nullable()();
  TextColumn get exerciseNameSnapshot => text().nullable()();
  IntColumn get targetRepsMin => integer().nullable()();
  IntColumn get targetRepsMax => integer().nullable()();
  IntColumn get targetRestSeconds => integer().nullable()();
  RealColumn get targetWeightKg => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

// ============== Standalone Program Tables ==============

/// Standalone Programs table - User-owned training programs
class StandalonePrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

/// Standalone ProgramRoutines table - Day-slot junction linking
/// a routine to a standalone program on a specific day of the week.
class StandaloneProgramRoutines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get programId => integer().references(
    StandalonePrograms,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get routineId =>
      integer().references(Routines, #id, onDelete: KeyAction.cascade)();

  /// Day of week as a string (MONDAY, TUESDAY, ..., SUNDAY).
  TextColumn get dayOfWeek => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

/// Standalone Assigned Programs table - Tracks the user's
/// self-assigned (active/inactive) program.
class StandaloneAssignedPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get userId => text()();
  IntColumn get programId => integer().references(
    StandalonePrograms,
    #id,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

// ============== Gains Coins Tables ==============

/// Local cache of the user's coin balance.
class CoinBalances extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get currentBalance => integer().withDefault(const Constant(0))();
  IntColumn get lifetimeEarned => integer().withDefault(const Constant(0))();
  IntColumn get lifetimeSpent => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of coin transactions (earnings and spending).
class CoinTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get type => text()(); // SESSION_REWARD or SHOP_PURCHASE
  IntColumn get amount => integer()();
  IntColumn get balanceAfter => integer()();
  // Earning breakdown
  IntColumn get setCoins => integer().nullable()();
  RealColumn get accuracyMultiplier => real().nullable()();
  IntColumn get completionBonus => integer().nullable()();
  IntColumn get durationBonus => integer().nullable()();
  IntColumn get streakBonus => integer().nullable()();
  IntColumn get streakValue => integer().nullable()();
  IntColumn get setsCompleted => integer().nullable()();
  RealColumn get avgAccuracy => real().nullable()();
  IntColumn get sessionDurationMin => integer().nullable()();
  // References
  TextColumn get workoutSessionId => text().nullable()();
  TextColumn get cosmeticId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of the cosmetic shop catalog.
class CosmeticsTable extends Table {
  @override
  String get tableName => 'cosmetics';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get tier => integer()();
  IntColumn get coinCost => integer()();
  TextColumn get previewImageUrl => text()();
  TextColumn get unityAssetRef => text()();
  TextColumn get status => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of cosmetics owned by the user.
class UserCosmeticsTable extends Table {
  @override
  String get tableName => 'user_cosmetics';

  TextColumn get id => text()();
  TextColumn get cosmeticId => text()();
  DateTimeColumn get purchasedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of currently equipped cosmetics.
class EquippedCosmeticsTable extends Table {
  @override
  String get tableName => 'equipped_cosmetics';

  TextColumn get id => text()();
  TextColumn get cosmeticId => text()();
  DateTimeColumn get equippedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============== Cached Form Tables ==============

/// Generic key-value cache for API responses that have no dedicated table.
/// Keyed by a stable string (e.g. 'today_routine', 'unified_weekly_stats').
class CachedApiResponses extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get responseJson => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

/// Local cache of coach-assigned programs for offline-first access.
/// Stores the full serialized JSON of each AssignedProgramModel.
///
/// The `remoteId` maps to the server's `assigned_program.id` (CUID string).
/// The `routinesJson` stores the serialized list of routines (including
/// exercises) so we can hydrate the model without extra joins.
class AssignedPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Full serialized JSON of List<RoutineModel> — avoids complex join tables.
  TextColumn get routinesJson => text().withDefault(const Constant('[]'))();

  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Cached coach reference forms for offline comparison.
/// Stores the full API response JSON so forms can be loaded without network.
class CachedExerciseForms extends Table {
  TextColumn get exerciseId => text()();
  TextColumn get responseJson =>
      text()(); // Full JSON from GET /pose/download/exercise/:id
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {exerciseId};
}

// ============== Database Class ==============

/// Application Database
///
/// Central Drift database configuration.
/// Add all tables to the @DriftDatabase annotation.
///
/// After adding/modifying tables, run:
/// ```bash
/// dart run build_runner build --delete-conflicting-outputs
/// ```
@DriftDatabase(
  tables: [
    Users,
    SyncQueue,
    Exercises,
    Routines,
    RoutineExercises,
    WorkoutSessions,
    PerformedSets,
    StandalonePrograms,
    StandaloneProgramRoutines,
    StandaloneAssignedPrograms,
    CachedExerciseForms,
    CachedApiResponses,
    AssignedPrograms,
    // Gains Coins tables
    CoinBalances,
    CoinTransactions,
    CosmeticsTable,
    UserCosmeticsTable,
    EquippedCosmeticsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Database schema version - increment when changing tables
  @override
  int get schemaVersion => 11;

  /// Handle migrations when schema version changes
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        AppLogger.info('Creating database tables', tag: 'Database');
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        AppLogger.info(
          'Migrating database from v$from to v$to',
          tag: 'Database',
        );

        if (from < 2) {
          // v2: Add standalone program tables
          await m.createTable(standalonePrograms);
          await m.createTable(standaloneProgramRoutines);
          await m.createTable(standaloneAssignedPrograms);
        }
        if (from < 3) {
          // v3: Add cached exercise forms table for offline-first
          await m.createTable(cachedExerciseForms);
        }
        if (from < 4) {
          // v4: Add generic API response cache for offline-first
          await m.createTable(cachedApiResponses);
        }
        if (from < 5) {
          // v5: Add Gains Coins economy tables
          await m.createTable(coinBalances);
          await m.createTable(coinTransactions);
          await m.createTable(cosmeticsTable);
          await m.createTable(userCosmeticsTable);
          await m.createTable(equippedCosmeticsTable);
        }
        if (from < 6) {
          // v6: Replace dayNumber (int) with dayOfWeek (text) in standalone program routines
          // Drop and recreate the table (safe since it's a local cache)
          await m.drop(standaloneProgramRoutines);
          await m.createTable(standaloneProgramRoutines);
        }
        if (from < 7) {
          // v7: Remove deprecated `category` from cosmetics cache (aligns with server / generic slots).
          // Local-only tables — safe to drop; app re-syncs catalog + inventory from API.
          await m.drop(cosmeticsTable);
          await m.drop(equippedCosmeticsTable);
          await m.createTable(cosmeticsTable);
          await m.createTable(equippedCosmeticsTable);
          // v7: Add pose-related columns to performed sets
          await m.addColumn(performedSets, performedSets.recordedFramesKey);
          await m.addColumn(performedSets, performedSets.overallScore);
          // Drop stale pose_results sync-queue rows (endpoint removed)
          await customStatement(
            "DELETE FROM sync_queue WHERE entity_table = 'pose_results'",
          );
        }
        if (from < 8) {
          // v8: Add assigned programs cache table for program-first navigation
          await m.createTable(assignedPrograms);
        }
        if (from < 9) {
          // v9: Replace int FK routineExerciseId with text APRE CUID.
          // SQLite doesn't support DROP COLUMN on older versions, so we
          // recreate the table via the temp-table-copy pattern.
          await customStatement('''
            CREATE TABLE performed_sets_new (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              remote_id TEXT,
              workout_session_id INTEGER NOT NULL
                REFERENCES workout_sessions (id) ON DELETE CASCADE,
              assigned_program_routine_exercise_id TEXT NOT NULL DEFAULT '',
              set_number INTEGER NOT NULL,
              reps_completed INTEGER NOT NULL,
              weight_kg REAL,
              rpe INTEGER,
              notes TEXT,
              is_completed INTEGER NOT NULL DEFAULT 0,
              recorded_frames_key TEXT,
              overall_score REAL,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
              updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
              is_synced INTEGER NOT NULL DEFAULT 0
            )
          ''');

          // Copy data, resolving old int FK to remote CUID where possible.
          await customStatement('''
            INSERT INTO performed_sets_new (
              id, remote_id, workout_session_id,
              assigned_program_routine_exercise_id,
              set_number, reps_completed, weight_kg, rpe, notes,
              is_completed, recorded_frames_key, overall_score,
              created_at, updated_at, is_synced
            )
            SELECT
              ps.id, ps.remote_id, ps.workout_session_id,
              COALESCE(re.remote_id, CAST(ps.routine_exercise_id AS TEXT)),
              ps.set_number, ps.reps_completed, ps.weight_kg, ps.rpe, ps.notes,
              ps.is_completed, ps.recorded_frames_key, ps.overall_score,
              ps.created_at, ps.updated_at, ps.is_synced
            FROM performed_sets ps
            LEFT JOIN routine_exercises re ON re.id = ps.routine_exercise_id
          ''');

          await customStatement('DROP TABLE performed_sets');
          await customStatement(
            'ALTER TABLE performed_sets_new RENAME TO performed_sets',
          );

          // Clean up orphan sync-queue rows whose old routineExerciseId
          // couldn't be resolved to a CUID (would 400 on the server).
          await customStatement('''
            DELETE FROM sync_queue
            WHERE entity_table = 'performed_sets'
              AND json_extract(payload, '\$.routineExerciseId') IS NOT NULL
              AND NOT EXISTS (
                SELECT 1 FROM routine_exercises re
                WHERE re.id = CAST(
                  json_extract(payload, '\$.routineExerciseId') AS INTEGER
                )
                AND re.remote_id IS NOT NULL
              )
          ''');
        }
        if (from < 10) {
          // v10: Add snapshot columns to performed_sets for historical durability
          await m.addColumn(performedSets, performedSets.exerciseNameSnapshot);
          await m.addColumn(performedSets, performedSets.targetRepsMin);
          await m.addColumn(performedSets, performedSets.targetRepsMax);
          await m.addColumn(performedSets, performedSets.targetRestSeconds);
          await m.addColumn(performedSets, performedSets.targetWeightKg);
        }
        if (from < 11) {
          // v11: Rename WorkoutSessions.assigned_program_id → assigned_program_routine_id
          await customStatement(
            'ALTER TABLE workout_sessions '
            'RENAME COLUMN assigned_program_id TO assigned_program_routine_id',
          );
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');

        if (details.wasCreated) {
          AppLogger.info('Database created successfully', tag: 'Database');
        }
      },
    );
  }

  // ============== User Operations ==============

  /// Get all users
  Future<List<User>> getAllUsers() => select(users).get();

  /// Get user by ID
  Future<User?> getUserById(int id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  /// Get user by remote ID
  Future<User?> getUserByRemoteId(String remoteId) {
    return (select(
      users,
    )..where((u) => u.remoteId.equals(remoteId))).getSingleOrNull();
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) {
    return (select(
      users,
    )..where((u) => u.email.equals(email))).getSingleOrNull();
  }

  /// Insert or update user
  Future<int> upsertUser(UsersCompanion user) {
    return into(users).insertOnConflictUpdate(user);
  }

  /// Delete user
  Future<int> deleteUser(int id) {
    return (delete(users)..where((u) => u.id.equals(id))).go();
  }

  /// Get unsynced users
  Future<List<User>> getUnsyncedUsers() {
    return (select(users)..where((u) => u.isSynced.equals(false))).get();
  }

  /// Mark user as synced
  Future<void> markUserSynced(int id, String remoteId) {
    return (update(users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        remoteId: Value(remoteId),
        isSynced: const Value(true),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============== Sync Queue Operations ==============

  /// Add item to sync queue
  Future<int> addToSyncQueue(SyncQueueCompanion item) {
    return into(syncQueue).insert(item);
  }

  /// Get pending sync items
  Future<List<SyncQueueData>> getPendingSyncItems({int limit = 50}) {
    return (select(syncQueue)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Remove from sync queue
  Future<int> removeFromSyncQueue(int id) {
    return (delete(syncQueue)..where((s) => s.id.equals(id))).go();
  }

  /// Increment retry count
  Future<void> incrementRetryCount(int id) {
    return customStatement(
      'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  /// Clear sync queue
  Future<int> clearSyncQueue() {
    return delete(syncQueue).go();
  }

  // ============== Exercise Operations ==============

  /// Get all exercises
  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  /// Get exercise by ID
  Future<Exercise?> getExerciseById(int id) {
    return (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  /// Insert or update exercise
  Future<int> upsertExercise(ExercisesCompanion exercise) {
    return into(exercises).insertOnConflictUpdate(exercise);
  }

  /// Insert multiple exercises
  Future<void> insertExercises(List<ExercisesCompanion> exercisesList) async {
    await batch((batch) {
      batch.insertAll(
        exercises,
        exercisesList,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  // ============== Routine Operations ==============

  /// Get all routines
  Future<List<Routine>> getAllRoutines() => select(routines).get();

  /// Get routine by ID
  Future<Routine?> getRoutineById(int id) {
    return (select(routines)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  /// Get routine by remote ID
  Future<Routine?> getRoutineByRemoteId(String remoteId) {
    return (select(
      routines,
    )..where((r) => r.remoteId.equals(remoteId))).getSingleOrNull();
  }

  /// Insert or update routine
  Future<int> upsertRoutine(RoutinesCompanion routine) {
    return into(routines).insertOnConflictUpdate(routine);
  }

  /// Delete all routines (cascade deletes routine exercises)
  Future<int> deleteAllRoutines() {
    return delete(routines).go();
  }

  // ============== Routine Exercise Operations ==============

  /// Get routine exercises for a routine
  Future<List<RoutineExercise>> getRoutineExercises(int routineId) {
    return (select(routineExercises)
          ..where((re) => re.routineId.equals(routineId))
          ..orderBy([(re) => OrderingTerm.asc(re.orderInRoutine)]))
        .get();
  }

  /// Get routine exercise by ID
  Future<RoutineExercise?> getRoutineExerciseById(int id) {
    return (select(
      routineExercises,
    )..where((re) => re.id.equals(id))).getSingleOrNull();
  }

  /// Get routine exercise by remote ID
  Future<RoutineExercise?> getRoutineExerciseByRemoteId(String remoteId) async {
    final results =
        await (select(routineExercises)
              ..where((re) => re.remoteId.equals(remoteId))
              ..limit(1))
            .get();
    return results.isEmpty ? null : results.first;
  }

  /// Insert or update routine exercise
  Future<int> upsertRoutineExercise(RoutineExercisesCompanion routineExercise) {
    return into(routineExercises).insertOnConflictUpdate(routineExercise);
  }

  // ============== Workout Session Operations ==============

  /// Get all workout sessions for a user
  Future<List<WorkoutSession>> getWorkoutSessions(String userId) {
    return (select(workoutSessions)
          ..where((ws) => ws.userId.equals(userId))
          ..orderBy([(ws) => OrderingTerm.desc(ws.startedAt)]))
        .get();
  }

  /// Get active (in-progress) workout session
  Future<WorkoutSession?> getActiveWorkoutSession(String userId) {
    return (select(workoutSessions)
          ..where((ws) => ws.userId.equals(userId) & ws.completedAt.isNull())
          ..orderBy([(ws) => OrderingTerm.desc(ws.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get today's completed session for a specific routine
  Future<WorkoutSession?> getTodayCompletedSessionForRoutine(
    String userId,
    int routineId,
  ) {
    final todayStart = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    return (select(workoutSessions)
          ..where(
            (ws) =>
                ws.userId.equals(userId) &
                ws.routineId.equals(routineId) &
                ws.completedAt.isNotNull() &
                ws.completedAt.isBiggerOrEqualValue(todayStart),
          )
          ..orderBy([(ws) => OrderingTerm.desc(ws.completedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get completed workout sessions for a user (paginated)
  Future<List<WorkoutSession>> getCompletedSessions(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) {
    return (select(workoutSessions)
          ..where((ws) => ws.userId.equals(userId) & ws.completedAt.isNotNull())
          ..orderBy([(ws) => OrderingTerm.desc(ws.startedAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Get completed sessions for a user within a date range (by startedAt).
  Future<List<WorkoutSession>> getCompletedSessionsInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return (select(workoutSessions)
          ..where(
            (ws) =>
                ws.userId.equals(userId) &
                ws.completedAt.isNotNull() &
                ws.startedAt.isBiggerOrEqualValue(start) &
                ws.startedAt.isSmallerOrEqualValue(end),
          )
          ..orderBy([(ws) => OrderingTerm.asc(ws.startedAt)]))
        .get();
  }

  /// Count completed workout sessions for a user
  Future<int> countCompletedSessions(String userId) async {
    final countExp = countAll();
    final query = selectOnly(workoutSessions)
      ..addColumns([countExp])
      ..where(
        workoutSessions.userId.equals(userId) &
            workoutSessions.completedAt.isNotNull(),
      );
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Get workout session by ID
  Future<WorkoutSession?> getWorkoutSessionById(int id) {
    return (select(
      workoutSessions,
    )..where((ws) => ws.id.equals(id))).getSingleOrNull();
  }

  /// Get workout session by remote ID (server CUID)
  Future<WorkoutSession?> getWorkoutSessionByRemoteId(String remoteId) async {
    final results =
        await (select(workoutSessions)
              ..where((ws) => ws.remoteId.equals(remoteId))
              ..limit(1))
            .get();
    return results.isEmpty ? null : results.first;
  }

  /// Start a new workout session
  Future<int> startWorkoutSession(WorkoutSessionsCompanion session) {
    return into(workoutSessions).insert(session);
  }

  /// Update workout session
  Future<bool> updateWorkoutSession(int id, WorkoutSessionsCompanion session) {
    return (update(
      workoutSessions,
    )..where((ws) => ws.id.equals(id))).write(session).then((rows) => rows > 0);
  }

  /// Complete a workout session
  Future<bool> completeWorkoutSession(int id, {String? notes}) {
    return (update(workoutSessions)..where((ws) => ws.id.equals(id)))
        .write(
          WorkoutSessionsCompanion(
            completedAt: Value(DateTime.now()),
            notes: notes != null ? Value(notes) : const Value.absent(),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Delete workout session
  Future<int> deleteWorkoutSession(int id) {
    return (delete(workoutSessions)..where((ws) => ws.id.equals(id))).go();
  }

  /// Delete completed sessions older than [days] days (and their sets).
  /// Only deletes sessions that have been synced to the server.
  Future<int> deleteOldCompletedSessions({int days = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (delete(workoutSessions)..where(
          (ws) =>
              ws.completedAt.isNotNull() &
              ws.completedAt.isSmallerThanValue(cutoff) &
              ws.isSynced.equals(true),
        ))
        .go();
  }

  /// Update remoteId for a synced workout session
  Future<bool> updateWorkoutSessionRemoteId(int id, String remoteId) {
    return (update(workoutSessions)..where((ws) => ws.id.equals(id)))
        .write(
          WorkoutSessionsCompanion(
            remoteId: Value(remoteId),
            isSynced: const Value(true),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============== Performed Set Operations ==============

  /// Get performed sets for a workout session
  Future<List<PerformedSet>> getPerformedSets(int workoutSessionId) {
    return (select(performedSets)
          ..where((ps) => ps.workoutSessionId.equals(workoutSessionId))
          ..orderBy([
            (ps) => OrderingTerm.asc(ps.assignedProgramRoutineExerciseId),
            (ps) => OrderingTerm.asc(ps.setNumber),
          ]))
        .get();
  }

  /// Get performed sets for a specific exercise in a session
  Future<List<PerformedSet>> getPerformedSetsForExercise(
    int workoutSessionId,
    String assignedProgramRoutineExerciseId,
  ) {
    return (select(performedSets)
          ..where(
            (ps) =>
                ps.workoutSessionId.equals(workoutSessionId) &
                ps.assignedProgramRoutineExerciseId.equals(
                  assignedProgramRoutineExerciseId,
                ),
          )
          ..orderBy([(ps) => OrderingTerm.asc(ps.setNumber)]))
        .get();
  }

  /// Insert or update performed set
  Future<int> upsertPerformedSet(PerformedSetsCompanion performedSet) {
    return into(performedSets).insertOnConflictUpdate(performedSet);
  }

  /// Log a completed set
  Future<int> logSet({
    required int workoutSessionId,
    required String assignedProgramRoutineExerciseId,
    required int setNumber,
    required int repsCompleted,
    double? weightKg,
    int? rpe,
    String? recordedFramesKey,
    double? overallScore,
    String? notes,
    String? exerciseNameSnapshot,
    int? targetRepsMin,
    int? targetRepsMax,
    int? targetRestSeconds,
    double? targetWeightKg,
  }) {
    return into(performedSets).insert(
      PerformedSetsCompanion.insert(
        workoutSessionId: workoutSessionId,
        assignedProgramRoutineExerciseId: assignedProgramRoutineExerciseId,
        setNumber: setNumber,
        repsCompleted: repsCompleted,
        weightKg: Value(weightKg),
        rpe: Value(rpe),
        notes: Value(notes),
        recordedFramesKey: Value(recordedFramesKey),
        overallScore: Value(overallScore),
        isCompleted: const Value(true),
        exerciseNameSnapshot: Value(exerciseNameSnapshot),
        targetRepsMin: Value(targetRepsMin),
        targetRepsMax: Value(targetRepsMax),
        targetRestSeconds: Value(targetRestSeconds),
        targetWeightKg: Value(targetWeightKg),
      ),
    );
  }

  /// Update a performed set
  Future<bool> updatePerformedSet(int id, PerformedSetsCompanion performedSet) {
    return (update(performedSets)..where((ps) => ps.id.equals(id)))
        .write(performedSet)
        .then((rows) => rows > 0);
  }

  /// Delete performed set
  Future<int> deletePerformedSet(int id) {
    return (delete(performedSets)..where((ps) => ps.id.equals(id))).go();
  }

  /// Update remoteId for a synced performed set
  Future<bool> updatePerformedSetRemoteId(int id, String remoteId) {
    return (update(performedSets)..where((ps) => ps.id.equals(id)))
        .write(
          PerformedSetsCompanion(
            remoteId: Value(remoteId),
            isSynced: const Value(true),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Get completed sets count for a session
  Future<int> getCompletedSetsCount(int workoutSessionId) async {
    final result =
        await (select(performedSets)..where(
              (ps) =>
                  ps.workoutSessionId.equals(workoutSessionId) &
                  ps.isCompleted.equals(true),
            ))
            .get();
    return result.length;
  }

  // ============== Standalone Program Operations ==============

  /// Get all standalone programs for a user
  Future<List<StandaloneProgram>> getStandalonePrograms(String userId) {
    return (select(standalonePrograms)
          ..where((p) => p.userId.equals(userId))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .get();
  }

  /// Get standalone program by ID
  Future<StandaloneProgram?> getStandaloneProgramById(int id) {
    return (select(
      standalonePrograms,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Get standalone program by remote ID
  Future<StandaloneProgram?> getStandaloneProgramByRemoteId(String remoteId) {
    return (select(
      standalonePrograms,
    )..where((p) => p.remoteId.equals(remoteId))).getSingleOrNull();
  }

  /// Insert or update standalone program
  Future<int> upsertStandaloneProgram(StandaloneProgramsCompanion program) {
    return into(standalonePrograms).insertOnConflictUpdate(program);
  }

  /// Delete standalone program (cascade deletes program routines)
  Future<int> deleteStandaloneProgram(int id) {
    return (delete(standalonePrograms)..where((p) => p.id.equals(id))).go();
  }

  /// Delete all standalone programs for a user
  Future<int> deleteAllStandalonePrograms(String userId) {
    return (delete(
      standalonePrograms,
    )..where((p) => p.userId.equals(userId))).go();
  }

  // ============== Standalone ProgramRoutine Operations ==============

  /// Get program routines for a standalone program, ordered by day number
  Future<List<StandaloneProgramRoutine>> getStandaloneProgramRoutines(
    int programId,
  ) {
    return (select(standaloneProgramRoutines)
          ..where((pr) => pr.programId.equals(programId))
          ..orderBy([(pr) => OrderingTerm.asc(pr.dayOfWeek)]))
        .get();
  }

  /// Insert or update standalone program routine
  Future<int> upsertStandaloneProgramRoutine(
    StandaloneProgramRoutinesCompanion programRoutine,
  ) {
    return into(
      standaloneProgramRoutines,
    ).insertOnConflictUpdate(programRoutine);
  }

  /// Delete standalone program routine
  Future<int> deleteStandaloneProgramRoutine(int id) {
    return (delete(
      standaloneProgramRoutines,
    )..where((pr) => pr.id.equals(id))).go();
  }

  // ============== Standalone AssignedProgram Operations ==============

  /// Get the active standalone assigned program for a user
  Future<StandaloneAssignedProgram?> getActiveStandaloneAssignment(
    String userId,
  ) {
    return (select(standaloneAssignedPrograms)
          ..where((a) => a.userId.equals(userId) & a.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// Get all standalone assignments for a user
  Future<List<StandaloneAssignedProgram>> getStandaloneAssignments(
    String userId,
  ) {
    return (select(standaloneAssignedPrograms)
          ..where((a) => a.userId.equals(userId))
          ..orderBy([(a) => OrderingTerm.desc(a.startDate)]))
        .get();
  }

  /// Insert or update a standalone assigned program
  Future<int> upsertStandaloneAssignment(
    StandaloneAssignedProgramsCompanion assignment,
  ) {
    return into(standaloneAssignedPrograms).insertOnConflictUpdate(assignment);
  }

  /// Deactivate all standalone assignments for a user
  Future<int> deactivateAllStandaloneAssignments(String userId) {
    return (update(
      standaloneAssignedPrograms,
    )..where((a) => a.userId.equals(userId) & a.isActive.equals(true))).write(
      StandaloneAssignedProgramsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============== Cached Exercise Form Operations ==============

  /// Get a cached exercise form by exercise ID
  Future<CachedExerciseForm?> getCachedExerciseForm(String exerciseId) {
    return (select(
      cachedExerciseForms,
    )..where((c) => c.exerciseId.equals(exerciseId))).getSingleOrNull();
  }

  /// Insert or update a cached exercise form
  Future<void> upsertCachedExerciseForm({
    required String exerciseId,
    required String responseJson,
  }) {
    return into(cachedExerciseForms).insertOnConflictUpdate(
      CachedExerciseFormsCompanion.insert(
        exerciseId: exerciseId,
        responseJson: responseJson,
      ),
    );
  }

  /// Delete a cached exercise form
  Future<int> deleteCachedExerciseForm(String exerciseId) {
    return (delete(
      cachedExerciseForms,
    )..where((c) => c.exerciseId.equals(exerciseId))).go();
  }

  /// Delete all cached exercise forms
  Future<int> deleteAllCachedExerciseForms() {
    return delete(cachedExerciseForms).go();
  }

  // ============== Generic API Response Cache ==============

  /// Get a cached API response by key (returns null if not cached)
  Future<String?> getCachedApiResponse(String key) async {
    final row = await (select(
      cachedApiResponses,
    )..where((c) => c.cacheKey.equals(key))).getSingleOrNull();
    return row?.responseJson;
  }

  /// Insert or update a cached API response
  Future<void> upsertCachedApiResponse({
    required String key,
    required String responseJson,
  }) {
    return into(cachedApiResponses).insertOnConflictUpdate(
      CachedApiResponsesCompanion.insert(
        cacheKey: key,
        responseJson: responseJson,
      ),
    );
  }

  // ============== Assigned Programs Operations ==============

  /// Get all cached assigned programs
  Future<List<AssignedProgram>> getAssignedPrograms() =>
      select(assignedPrograms).get();

  /// Get an assigned program by remote ID
  Future<AssignedProgram?> getAssignedProgramByRemoteId(String remoteId) {
    return (select(
      assignedPrograms,
    )..where((ap) => ap.remoteId.equals(remoteId))).getSingleOrNull();
  }

  /// Upsert (insert or replace) an assigned program row
  Future<int> upsertAssignedProgram(AssignedProgramsCompanion program) {
    return into(assignedPrograms).insertOnConflictUpdate(program);
  }

  /// Replace all assigned programs in a single batch (full sync)
  Future<void> replaceAssignedPrograms(
    List<AssignedProgramsCompanion> programs,
  ) async {
    await transaction(() async {
      await delete(assignedPrograms).go();
      await batch((b) {
        b.insertAll(
          assignedPrograms,
          programs,
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  /// Delete all assigned programs (e.g. on logout)
  Future<int> deleteAllAssignedPrograms() => delete(assignedPrograms).go();

  // ============== Utility Methods ==============

  /// Clear all data (use with caution)
  Future<void> clearAllData() async {
    AppLogger.warning('Clearing all database data', tag: 'Database');
    await delete(syncQueue).go();
    await delete(users).go();
  }

  /// Get database file path
  static Future<String> getDatabasePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, AppConstants.databaseName);
  }

  /// Delete database file
  static Future<void> deleteDatabase() async {
    final path = await getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      AppLogger.warning('Database file deleted', tag: 'Database');
    }
  }
}

/// Opens a connection to the SQLite database
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    AppLogger.info('Database path: ${file.path}', tag: 'Database');
    return NativeDatabase.createInBackground(file);
  });
}

/// Provider for AppDatabase
///
/// keepAlive: true ensures the database connection persists
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase();

  // Close database when provider is disposed
  ref.onDispose(() {
    AppLogger.info('Closing database connection', tag: 'Database');
    database.close();
  });

  return database;
}
