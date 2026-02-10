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
  TextColumn get assignedProgramId => text().nullable()();
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
  IntColumn get routineExerciseId => integer().references(
    RoutineExercises,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get setNumber => integer()();
  IntColumn get repsCompleted => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get rpe => integer().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Database schema version - increment when changing tables
  @override
  int get schemaVersion => AppConstants.databaseVersion;

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

        // Add migration logic here as needed
        // Example:
        // if (from < 2) {
        //   await m.addColumn(users, users.newColumn);
        // }
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
          ..where((ws) => ws.userId.equals(userId) & ws.completedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get workout session by ID
  Future<WorkoutSession?> getWorkoutSessionById(int id) {
    return (select(
      workoutSessions,
    )..where((ws) => ws.id.equals(id))).getSingleOrNull();
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

  // ============== Performed Set Operations ==============

  /// Get performed sets for a workout session
  Future<List<PerformedSet>> getPerformedSets(int workoutSessionId) {
    return (select(performedSets)
          ..where((ps) => ps.workoutSessionId.equals(workoutSessionId))
          ..orderBy([
            (ps) => OrderingTerm.asc(ps.routineExerciseId),
            (ps) => OrderingTerm.asc(ps.setNumber),
          ]))
        .get();
  }

  /// Get performed sets for a specific exercise in a session
  Future<List<PerformedSet>> getPerformedSetsForExercise(
    int workoutSessionId,
    int routineExerciseId,
  ) {
    return (select(performedSets)
          ..where(
            (ps) =>
                ps.workoutSessionId.equals(workoutSessionId) &
                ps.routineExerciseId.equals(routineExerciseId),
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
    required int routineExerciseId,
    required int setNumber,
    required int repsCompleted,
    double? weightKg,
    int? rpe,
    String? notes,
  }) {
    return into(performedSets).insert(
      PerformedSetsCompanion.insert(
        workoutSessionId: workoutSessionId,
        routineExerciseId: routineExerciseId,
        setNumber: setNumber,
        repsCompleted: repsCompleted,
        weightKg: Value(weightKg),
        rpe: Value(rpe),
        notes: Value(notes),
        isCompleted: const Value(true),
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
