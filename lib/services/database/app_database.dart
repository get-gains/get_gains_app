import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

part 'app_database.g.dart';

// ============== Primitive 1: Outbox ==============

class OutboxEntries extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get operation => text()();
  TextColumn get parentOutboxId => text().nullable()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============== Primitive 2: Cache ==============

class CachedAssets extends Table {
  TextColumn get key => text()();
  TextColumn get version => text()();
  TextColumn get content => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

// ============== Workout Tables ==============

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get primaryMuscleGroup => text()();
  TextColumn get equipmentNeeded => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  IntColumn get estimatedDurationMinutes => integer()();
  TextColumn get muscleGroupsTargeted =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineExercises extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get sets => integer()();
  IntColumn get repsMin => integer()();
  IntColumn get repsMax => integer()();
  IntColumn get restSeconds => integer()();
  IntColumn get orderInRoutine => integer()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get assignedProgramRoutineId => text().nullable()();
  TextColumn get standaloneProgramRoutineId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PerformedSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutSessionId => text()();
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
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============== Standalone Program Tables ==============

class StandalonePrograms extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class StandaloneProgramRoutines extends Table {
  TextColumn get id => text()();
  TextColumn get programId => text()();
  TextColumn get routineId => text()();
  TextColumn get dayOfWeek => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class StandaloneAssignedPrograms extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get programId => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============== Gains Coins Tables ==============

class CoinBalances extends Table {
  TextColumn get id => text()();
  IntColumn get currentBalance => integer().withDefault(const Constant(0))();
  IntColumn get lifetimeEarned => integer().withDefault(const Constant(0))();
  IntColumn get lifetimeSpent => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CoinTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  IntColumn get balanceAfter => integer()();
  IntColumn get setCoins => integer().nullable()();
  RealColumn get accuracyMultiplier => real().nullable()();
  IntColumn get completionBonus => integer().nullable()();
  IntColumn get durationBonus => integer().nullable()();
  IntColumn get streakBonus => integer().nullable()();
  IntColumn get streakValue => integer().nullable()();
  IntColumn get setsCompleted => integer().nullable()();
  RealColumn get avgAccuracy => real().nullable()();
  IntColumn get sessionDurationMin => integer().nullable()();
  TextColumn get workoutSessionId => text().nullable()();
  TextColumn get cosmeticId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

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

class UserCosmeticsTable extends Table {
  @override
  String get tableName => 'user_cosmetics';
  TextColumn get id => text()();
  TextColumn get cosmeticId => text()();
  DateTimeColumn get purchasedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class EquippedCosmeticsTable extends Table {
  @override
  String get tableName => 'equipped_cosmetics';
  TextColumn get id => text()();
  TextColumn get cosmeticId => text()();
  DateTimeColumn get equippedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============== Database Class ==============

@DriftDatabase(
  tables: [
    OutboxEntries,
    CachedAssets,
    Exercises,
    Routines,
    RoutineExercises,
    WorkoutSessions,
    PerformedSets,
    StandalonePrograms,
    StandaloneProgramRoutines,
    StandaloneAssignedPrograms,
    CoinBalances,
    CoinTransactions,
    CosmeticsTable,
    UserCosmeticsTable,
    EquippedCosmeticsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        AppLogger.info('Creating database tables (v2)', tag: 'Database');
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        await m.createAll();
        if (from < 2) {
          await customStatement(
            'ALTER TABLE standalone_program_routines ADD COLUMN order_in_program INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        if (details.wasCreated) {
          AppLogger.info('Database created successfully', tag: 'Database');
        }
      },
    );
  }

  // ============== Outbox Operations ==============

  Future<int> insertOutboxEntry(OutboxEntriesCompanion entry) {
    return into(outboxEntries).insert(entry);
  }

  Future<List<OutboxEntry>> getPendingOutboxEntries({int limit = 50}) {
    return (select(outboxEntries)
          ..where((o) => o.status.equals('pending'))
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<OutboxEntry?> getOutboxEntryById(String id) {
    return (select(outboxEntries)..where((o) => o.id.equals(id)))
        .getSingleOrNull();
  }

  Future<bool> updateOutboxStatus(
    String id, {
    required String status,
    String? lastError,
    DateTime? syncedAt,
  }) {
    return (update(outboxEntries)..where((o) => o.id.equals(id)))
        .write(
          OutboxEntriesCompanion(
            status: Value(status),
            lastError: Value(lastError),
            syncedAt: Value(syncedAt),
            retryCount: status == 'failed'
                ? const Value.absent()
                : const Value.absent(),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<void> incrementRetryCount(String id) {
    return customStatement(
      'UPDATE outbox_entries SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> deleteSyncedOutboxEntries() {
    return customStatement(
      'DELETE FROM outbox_entries WHERE status = ?',
      ['synced'],
    );
  }

  // ============== Cache Operations ==============

  Future<CachedAsset?> getCachedAsset(String key) {
    return (select(cachedAssets)..where((c) => c.key.equals(key)))
        .getSingleOrNull();
  }

  Future<void> putCachedAsset({
    required String key,
    required String version,
    required String content,
  }) {
    return into(cachedAssets).insertOnConflictUpdate(
      CachedAssetsCompanion.insert(
        key: key,
        version: version,
        content: content,
        fetchedAt: DateTime.now(),
      ),
    );
  }

  Future<void> deleteCachedAsset(String key) {
    return (delete(cachedAssets)..where((c) => c.key.equals(key))).go();
  }

  // ============== Exercise Operations ==============

  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Future<Exercise?> getExerciseById(String id) {
    return (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Future<int> upsertExercise(ExercisesCompanion exercise) {
    return into(exercises).insertOnConflictUpdate(exercise);
  }

  Future<void> replaceAllExercises(List<ExercisesCompanion> exercisesList) async {
    await transaction(() async {
      await delete(exercises).go();
      await batch((b) {
        b.insertAll(exercises, exercisesList, mode: InsertMode.insertOrReplace);
      });
    });
  }

  // ============== Routine Operations ==============

  Future<List<Routine>> getAllRoutines() => select(routines).get();

  Future<Routine?> getRoutineById(String id) {
    return (select(routines)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  Future<int> upsertRoutine(RoutinesCompanion routine) {
    return into(routines).insertOnConflictUpdate(routine);
  }

  Future<void> replaceAllRoutines(List<RoutinesCompanion> routinesList) async {
    await transaction(() async {
      await delete(routines).go();
      await batch((b) {
        b.insertAll(routines, routinesList, mode: InsertMode.insertOrReplace);
      });
    });
  }

  // ============== Routine Exercise Operations ==============

  Future<List<RoutineExercise>> getRoutineExercises(String routineId) {
    return (select(routineExercises)
          ..where((re) => re.routineId.equals(routineId))
          ..orderBy([(re) => OrderingTerm.asc(re.orderInRoutine)]))
        .get();
  }

  Future<int> upsertRoutineExercise(RoutineExercisesCompanion re) {
    return into(routineExercises).insertOnConflictUpdate(re);
  }

  Future<int> updateRoutineExerciseById(
    String id, {
    int? sets,
    int? repsMin,
    int? repsMax,
    int? restSeconds,
    int? orderInRoutine,
  }) {
    return (update(routineExercises)..where((re) => re.id.equals(id))).write(
      RoutineExercisesCompanion(
        sets: sets != null ? Value(sets) : const Value.absent(),
        repsMin: repsMin != null ? Value(repsMin) : const Value.absent(),
        repsMax: repsMax != null ? Value(repsMax) : const Value.absent(),
        restSeconds: restSeconds != null ? Value(restSeconds) : const Value.absent(),
        orderInRoutine: orderInRoutine != null ? Value(orderInRoutine) : const Value.absent(),
      ),
    );
  }

  Future<int> deleteRoutineExerciseById(String id) {
    return (delete(routineExercises)..where((re) => re.id.equals(id))).go();
  }
  Future<void> replaceAllRoutineExercises(
    List<RoutineExercisesCompanion> list,
  ) async {
    await transaction(() async {
      await delete(routineExercises).go();
      await batch((b) {
        b.insertAll(
          routineExercises,
          list,
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  // ============== Workout Session Operations ==============

  Future<List<WorkoutSession>> getWorkoutSessions(String userId) {
    return (select(workoutSessions)
          ..where((ws) => ws.userId.equals(userId))
          ..orderBy([(ws) => OrderingTerm.desc(ws.startedAt)]))
        .get();
  }

  Future<WorkoutSession?> getActiveWorkoutSession(String userId) {
    return (select(workoutSessions)
          ..where((ws) => ws.userId.equals(userId) & ws.completedAt.isNull())
          ..orderBy([(ws) => OrderingTerm.desc(ws.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<WorkoutSession?> getWorkoutSessionById(String id) {
    return (select(workoutSessions)..where((ws) => ws.id.equals(id)))
        .getSingleOrNull();
  }

  Future<WorkoutSession?> getTodayCompletedSessionForRoutine(
    String userId,
    String assignedProgramRoutineId,
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
                ws.assignedProgramRoutineId.equals(assignedProgramRoutineId) &
                ws.completedAt.isNotNull() &
                ws.completedAt.isBiggerOrEqualValue(todayStart),
          )
          ..orderBy([(ws) => OrderingTerm.desc(ws.completedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

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

  Future<int> insertWorkoutSession(WorkoutSessionsCompanion session) {
    return into(workoutSessions).insert(session);
  }

  Future<bool> completeWorkoutSession(String id, {String? notes}) {
    return (update(workoutSessions)..where((ws) => ws.id.equals(id)))
        .write(
          WorkoutSessionsCompanion(
            completedAt: Value(DateTime.now()),
            notes: notes != null ? Value(notes) : const Value.absent(),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<int> deleteWorkoutSession(String id) {
    return (delete(workoutSessions)..where((ws) => ws.id.equals(id))).go();
  }

  Future<WorkoutSession?> getActiveStandaloneSession(String userId) {
    return (select(workoutSessions)
          ..where(
            (ws) =>
                ws.userId.equals(userId) &
                ws.standaloneProgramRoutineId.isNotNull() &
                ws.completedAt.isNull(),
          )
          ..orderBy([(ws) => OrderingTerm.desc(ws.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<WorkoutSession>> getStandaloneCompletedSessions(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) {
    return (select(workoutSessions)
          ..where(
            (ws) =>
                ws.userId.equals(userId) &
                ws.standaloneProgramRoutineId.isNotNull() &
                ws.completedAt.isNotNull(),
          )
          ..orderBy([(ws) => OrderingTerm.desc(ws.completedAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  // ============== Performed Set Operations ==============

  Future<List<PerformedSet>> getPerformedSets(String workoutSessionId) {
    return (select(performedSets)
          ..where((ps) => ps.workoutSessionId.equals(workoutSessionId))
          ..orderBy([
            (ps) => OrderingTerm.asc(ps.assignedProgramRoutineExerciseId),
            (ps) => OrderingTerm.asc(ps.setNumber),
          ]))
        .get();
  }

  Future<List<PerformedSet>> getPerformedSetsForExercise(
    String workoutSessionId,
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

  Future<int> upsertPerformedSet(PerformedSetsCompanion performedSet) {
    return into(performedSets).insertOnConflictUpdate(performedSet);
  }

  Future<int> logSet({
    required String id,
    required String workoutSessionId,
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
        id: id,
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
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<bool> updatePerformedSet(String id, PerformedSetsCompanion set) {
    return (update(performedSets)..where((ps) => ps.id.equals(id)))
        .write(set)
        .then((rows) => rows > 0);
  }

  Future<int> deletePerformedSet(String id) {
    return (delete(performedSets)..where((ps) => ps.id.equals(id))).go();
  }

  // ============== Standalone Program Operations ==============

  Future<List<StandaloneProgram>> getStandalonePrograms(String userId) {
    return (select(standalonePrograms)
          ..where((p) => p.userId.equals(userId))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .get();
  }

  Future<StandaloneProgram?> getStandaloneProgramById(String id) {
    return (select(standalonePrograms)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> upsertStandaloneProgram(StandaloneProgramsCompanion program) {
    return into(standalonePrograms).insertOnConflictUpdate(program);
  }

  Future<int> deleteStandaloneProgram(String id) {
    return (delete(standalonePrograms)..where((p) => p.id.equals(id))).go();
  }

  Future<int> deleteAllStandalonePrograms(String userId) {
    return (delete(standalonePrograms)..where((p) => p.userId.equals(userId)))
        .go();
  }

  // ============== Standalone ProgramRoutine Operations ==============

  Future<List<StandaloneProgramRoutine>> getStandaloneProgramRoutines(
    String programId,
  ) {
    return (select(standaloneProgramRoutines)
          ..where((pr) => pr.programId.equals(programId))
          ..orderBy([(pr) => OrderingTerm.asc(pr.dayOfWeek)]))
        .get();
  }

  Future<int> upsertStandaloneProgramRoutine(
    StandaloneProgramRoutinesCompanion programRoutine,
  ) {
    return into(standaloneProgramRoutines).insertOnConflictUpdate(programRoutine);
  }

  Future<int> deleteStandaloneProgramRoutine(String id) {
    return (delete(standaloneProgramRoutines)..where((pr) => pr.id.equals(id)))
        .go();
  }

  Future<bool> updateStandaloneProgramRoutineOrder(
    String id,
    int orderInProgram,
  ) {
    return customStatement(
      'UPDATE standalone_program_routines SET order_in_program = ? WHERE id = ?',
      [orderInProgram, id],
    ).then((_) => true);
  }

  Future<int> getStandaloneProgramRoutineOrder(String id) async {
    final result = await customSelect(
      'SELECT order_in_program FROM standalone_program_routines WHERE id = ?',
      variables: [Variable.withString(id)],
      readsFrom: {standaloneProgramRoutines},
    ).getSingleOrNull();
    return result?.readInt('order_in_program') ?? 0;
  }

  // ============== Standalone AssignedProgram Operations ==============

  Future<StandaloneAssignedProgram?> getActiveStandaloneAssignment(
    String userId,
  ) {
    return (select(standaloneAssignedPrograms)
          ..where((a) => a.userId.equals(userId) & a.isActive.equals(true)))
        .getSingleOrNull();
  }

  Future<List<StandaloneAssignedProgram>> getStandaloneAssignments(
    String userId,
  ) {
    return (select(standaloneAssignedPrograms)
          ..where((a) => a.userId.equals(userId))
          ..orderBy([(a) => OrderingTerm.desc(a.startDate)]))
        .get();
  }

  Future<int> upsertStandaloneAssignment(
    StandaloneAssignedProgramsCompanion assignment,
  ) {
    return into(standaloneAssignedPrograms).insertOnConflictUpdate(assignment);
  }

  Future<int> deactivateAllStandaloneAssignments(String userId) {
    return (update(standaloneAssignedPrograms)
          ..where(
            (a) => a.userId.equals(userId) & a.isActive.equals(true),
          ))
        .write(
          StandaloneAssignedProgramsCompanion(
            isActive: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  // ============== Coin Operations ==============

  Future<CoinBalance?> getCachedBalance() {
    return (select(coinBalances)..limit(1)).getSingleOrNull();
  }

  Future<void> upsertCoinBalance(CoinBalancesCompanion balance) {
    return into(coinBalances).insertOnConflictUpdate(balance);
  }

  Future<List<CoinTransaction>> getCachedTransactions() {
    return (select(coinTransactions)
          ..orderBy([(ct) => OrderingTerm.desc(ct.createdAt)]))
        .get();
  }

  Future<void> upsertCoinTransaction(CoinTransactionsCompanion txn) {
    return into(coinTransactions).insertOnConflictUpdate(txn);
  }

  Future<void> clearCoinTransactions() {
    return delete(coinTransactions).go();
  }

  // ============== Cosmetic Operations ==============

  Future<void> upsertCosmetic(CosmeticsTableCompanion cosmetic) {
    return into(cosmeticsTable).insertOnConflictUpdate(cosmetic);
  }

  Future<List<CosmeticsTableData>> getCosmetics() {
    return (select(cosmeticsTable)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  Future<void> upsertUserCosmetic(UserCosmeticsTableCompanion uc) {
    return into(userCosmeticsTable).insertOnConflictUpdate(uc);
  }

  Future<List<UserCosmeticsTableData>> getUserCosmetics() {
    return select(userCosmeticsTable).get();
  }

  Future<void> upsertEquipped(EquippedCosmeticsTableCompanion ec) {
    return into(equippedCosmeticsTable).insertOnConflictUpdate(ec);
  }

  Future<List<EquippedCosmeticsTableData>> getEquipped() {
    return select(equippedCosmeticsTable).get();
  }

  // ============== Utility Methods ==============

  Future<void> clearAllData() async {
    AppLogger.warning('Clearing all database data', tag: 'Database');

    // Drift generates individual table names for delete.
    // We drop everything except the schema version tracking.
    final stmts = [
      'DELETE FROM outbox_entries',
      'DELETE FROM cached_assets',
      'DELETE FROM exercises',
      'DELETE FROM routines',
      'DELETE FROM routine_exercises',
      'DELETE FROM workout_sessions',
      'DELETE FROM performed_sets',
      'DELETE FROM standalone_programs',
      'DELETE FROM standalone_program_routines',
      'DELETE FROM standalone_assigned_programs',
      'DELETE FROM coin_balances',
      'DELETE FROM coin_transactions',
      'DELETE FROM cosmetics',
      'DELETE FROM user_cosmetics',
      'DELETE FROM equipped_cosmetics',
    ];
    for (final stmt in stmts) {
      await customStatement(stmt);
    }
  }

  static Future<String> getDatabasePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, AppConstants.databaseName);
  }

  static Future<void> deleteDatabase() async {
    final path = await getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      AppLogger.warning('Database file deleted', tag: 'Database');
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    AppLogger.info('Database path: ${file.path}', tag: 'Database');
    return NativeDatabase.createInBackground(file);
  });
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase();

  ref.onDispose(() {
    AppLogger.info('Closing database connection', tag: 'Database');
    database.close();
  });

  return database;
}
