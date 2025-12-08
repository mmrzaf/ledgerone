import 'package:sqflite/sqflite.dart';

/// Core database service interface
///
/// This contract defines the common interface for all database implementations
/// in the app. It provides access to the underlying database and utility methods.
abstract interface class DatabaseService {
  /// Get the underlying database instance
  ///
  /// This may initialize the database on first call.
  Future<Database> get database;

  /// Close the database connection
  ///
  /// This should be called when the database is no longer needed,
  /// typically during app shutdown or testing cleanup.
  Future<void> close();

  /// Generate a unique identifier
  ///
  /// Returns a UUID v4 string suitable for use as a primary key.
  String generateId();
}
