import 'dart:convert';

import 'package:ledgerone/core/observability/app_logger.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/backup_contract.dart';
import '../data/database.dart';

/// JSON-based backup service for LedgerOne.
///
/// Format (version 1):
/// {
///   "format": "ledgerone_backup",
///   "version": 1,
///   "exported_at": "2025-01-01T12:00:00Z",
///   "entities": {
///     "assets": [ ... raw DB rows ... ],
///     "accounts": [ ... ],
///     "categories": [ ... ],
///     "transactions": [ ... ],
///     "transaction_legs": [ ... ],
///     "price_snapshots": [ ... ]
///   }
/// }
class JsonBackupService implements BackupService {
  final LedgerDatabase _db;
  final AnalyticsService? _analytics;

  static const int _schemaVersion = 1;

  JsonBackupService({required LedgerDatabase db, AnalyticsService? analytics})
    : _db = db,
      _analytics = analytics;

  @override
  Future<String> exportToJson() async {
    final db = await _db.database;

    // Read all tables
    final assets = await db.query('assets');
    final accounts = await db.query('accounts');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final legs = await db.query('transaction_legs');
    final priceSnapshots = await db.query('price_snapshots');

    final now = DateTime.now().toUtc().toIso8601String();

    final payload = <String, dynamic>{
      'format': 'ledgerone_backup',
      'version': _schemaVersion,
      'exported_at': now,
      'entities': {
        'assets': assets,
        'accounts': accounts,
        'categories': categories,
        'transactions': transactions,
        'transaction_legs': legs,
        'price_snapshots': priceSnapshots,
      },
    };

    final json = jsonEncode(payload);

    // Fire-and-forget analytics
    await _analytics?.logEvent(
      'backup_export_completed',
      parameters: {
        'version': _schemaVersion,
        'assets': assets.length,
        'accounts': accounts.length,
        'categories': categories.length,
        'transactions': transactions.length,
        'legs': legs.length,
        'price_snapshots': priceSnapshots.length,
      },
    );

    AppLogger.info(
      'Backup: exported ${assets.length} assets, '
      '${accounts.length} accounts, '
      '${categories.length} categories, '
      '${transactions.length} transactions, '
      '${legs.length} legs, '
      '${priceSnapshots.length} price snapshots',
      tag: 'Backup',
    );

    return json;
  }

  @override
  Future<void> restoreFromJson(String json, {bool clearExisting = true}) async {
    final decoded = jsonDecode(json);

    if (decoded is! Map<String, dynamic>) {
      throw ArgumentError('Invalid backup: root is not a JSON object');
    }

    if (decoded['format'] != 'ledgerone_backup') {
      throw ArgumentError('Invalid backup: unsupported format marker');
    }

    final version = decoded['version'] as int? ?? 0;
    if (version != _schemaVersion) {
      // You can add migrations later if you want to accept older versions.
      throw ArgumentError(
        'Unsupported backup version: $version (expected $_schemaVersion)',
      );
    }

    final entities = decoded['entities'];
    if (entities is! Map<String, dynamic>) {
      throw ArgumentError('Invalid backup: missing "entities" section');
    }

    List<Map<String, dynamic>> readList(String key) {
      final raw = entities[key];
      if (raw is! List) return const [];
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    }

    final assets = readList('assets');
    final accounts = readList('accounts');
    final categories = readList('categories');
    final transactions = readList('transactions');
    final legs = readList('transaction_legs');
    final priceSnapshots = readList('price_snapshots');

    final db = await _db.database;

    await db.transaction((txn) async {
      // Ensure we don't end up with a half-applied backup because of FK errors.
      await txn.execute('PRAGMA foreign_keys = OFF');

      try {
        if (clearExisting) {
          // Children first, then parents – keep FK constraints happy.
          await txn.delete('transaction_legs');
          await txn.delete('price_snapshots');
          await txn.delete('transactions');
          await txn.delete('accounts');
          await txn.delete('categories');
          await txn.delete('assets');
        }

        // Parents first on insert.
        for (final row in assets) {
          await txn.insert(
            'assets',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final row in accounts) {
          await txn.insert(
            'accounts',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final row in categories) {
          await txn.insert(
            'categories',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final row in transactions) {
          await txn.insert(
            'transactions',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final row in priceSnapshots) {
          await txn.insert(
            'price_snapshots',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final row in legs) {
          await txn.insert(
            'transaction_legs',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } finally {
        await txn.execute('PRAGMA foreign_keys = ON');
      }
    });

    await _analytics?.logEvent(
      'backup_restore_completed',
      parameters: {
        'version': _schemaVersion,
        'assets': assets.length,
        'accounts': accounts.length,
        'categories': categories.length,
        'transactions': transactions.length,
        'legs': legs.length,
        'price_snapshots': priceSnapshots.length,
        'clear_existing': clearExisting,
      },
    );

    AppLogger.info(
      'Backup: restore completed '
      '(${assets.length} assets, ${accounts.length} accounts, '
      '${categories.length} categories, ${transactions.length} transactions, '
      '${legs.length} legs, ${priceSnapshots.length} price snapshots)',
      tag: 'Backup',
    );
  }
}
