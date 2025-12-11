import 'package:flutter/foundation.dart';
import 'package:ledgerone/core/observability/app_logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'database_contract.dart';

/// Base implementation for SQLite databases
///
/// This class provides common SQLite database functionality including:
/// - Connection management with lazy initialization
/// - Database path resolution
/// - Version management
/// - ID generation
///
/// Subclasses must implement:
/// - [databaseName] - The name of the database file
/// - [databaseVersion] - The schema version number
/// - [createSchema] - The schema creation logic
abstract class SqliteDatabaseBase implements DatabaseService {
  static const _uuid = Uuid();

  Database? _database;

  /// The name of the database file (e.g., 'myapp.db')
  @protected
  String get databaseName;

  /// The current schema version
  ///
  /// Increment this when making schema changes to trigger migrations.
  @protected
  int get databaseVersion;

  /// Create the database schema
  ///
  /// This method is called when:
  /// - The database is created for the first time ([version] == 1)
  /// - The database is upgraded ([version] > 1)
  ///
  /// Subclasses should create all tables, indexes, and default data here.
  @protected
  Future<void> createSchema(Database db, int version);

  /// Optional: Handle database upgrades
  ///
  /// Override this to provide custom migration logic.
  /// The default implementation just recreates the schema.
  @protected
  Future<void> upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Default: drop and recreate (not production-ready)
    // Override in subclass for proper migrations
    AppLogger.debug(
      'Database upgrade: v$oldVersion -> v$newVersion (recreating schema)',
      tag: 'Database',
    );
    await createSchema(db, newVersion);
  }

  @override
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);

    AppLogger.debug('Opening database at: $path', tag: 'Opening');

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: createSchema,
      onUpgrade: upgradeSchema,
    );
  }

  @override
  Future<void> close() async {
    if (_database == null) return;

    final db = _database!;
    await db.close();
    _database = null;

    AppLogger.debug('Database closed: $databaseName', tag: 'Database');
  }

  @override
  String generateId() => _uuid.v4();

  /// Check if database is open
  @protected
  bool get isOpen => _database != null && _database!.isOpen;
}
