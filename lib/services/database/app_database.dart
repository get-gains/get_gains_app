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
@DriftDatabase(tables: [Users, SyncQueue])
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
