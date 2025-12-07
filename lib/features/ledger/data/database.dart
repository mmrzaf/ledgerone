import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:uuid/uuid.dart';

class LedgerDatabase {
  static const String _dbName = 'ledgerone.db';
  static const int _dbVersion = 2;
  static const _uuid = Uuid();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        decimals INTEGER NOT NULL,
        price_source_config TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        kind TEXT NOT NULL,
        parent_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_legs (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        asset_id TEXT NOT NULL,
        amount REAL NOT NULL,
        role TEXT NOT NULL,
        category_id TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (asset_id) REFERENCES assets (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE price_snapshots (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        price REAL NOT NULL,
        timestamp TEXT NOT NULL,
        source TEXT,
        FOREIGN KEY (asset_id) REFERENCES assets (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE account_balances (
        account_id TEXT NOT NULL,
        asset_id TEXT NOT NULL,
        balance REAL NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (account_id, asset_id),
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (asset_id) REFERENCES assets (id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_legs_transaction ON transaction_legs(transaction_id)',
    );
    await db.execute(
      'CREATE INDEX idx_legs_account ON transaction_legs(account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_legs_asset ON transaction_legs(asset_id)',
    );
    await db.execute(
      'CREATE INDEX idx_prices_asset ON price_snapshots(asset_id)',
    );
    await db.execute(
      'CREATE INDEX idx_prices_timestamp ON price_snapshots(timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_timestamp ON transactions(timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_balances_account ON account_balances(account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_balances_asset ON account_balances(asset_id)',
    );

    await _insertDefaultAssets(db);
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultAssets(Database db) async {
    final now = DateTime.now().toIso8601String();

    final assets = [
      {
        'id': 'usd',
        'symbol': 'USD',
        'name': 'US Dollar',
        'type': 'fiat',
        'decimals': 2,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'eur',
        'symbol': 'EUR',
        'name': 'Euro',
        'type': 'fiat',
        'decimals': 2,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'btc',
        'symbol': 'BTC',
        'name': 'Bitcoin',
        'type': 'crypto',
        'decimals': 8,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'eth',
        'symbol': 'ETH',
        'name': 'Ethereum',
        'type': 'crypto',
        'decimals': 18,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final asset in assets) {
      await db.insert('assets', asset);
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();

    final categories = [
      {
        'id': 'cat_salary',
        'name': 'Salary',
        'kind': 'income',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'cat_investment',
        'name': 'Investment',
        'kind': 'income',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'cat_groceries',
        'name': 'Groceries',
        'kind': 'expense',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'cat_rent',
        'name': 'Rent',
        'kind': 'expense',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'cat_transport',
        'name': 'Transport',
        'kind': 'expense',
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final category in categories) {
      await db.insert('categories', category);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE account_balances (
          account_id TEXT NOT NULL,
          asset_id TEXT NOT NULL,
          balance REAL NOT NULL,
          updated_at TEXT NOT NULL,
          PRIMARY KEY (account_id, asset_id),
          FOREIGN KEY (account_id) REFERENCES accounts (id),
          FOREIGN KEY (asset_id) REFERENCES assets (id)
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_balances_account ON account_balances(account_id)',
      );
      await db.execute(
        'CREATE INDEX idx_balances_asset ON account_balances(asset_id)',
      );

      await _rebuildBalances(db);
    }
  }

  Future<void> _rebuildBalances(Database db) async {
    await db.delete('account_balances');

    final legs = await db.query('transaction_legs');
    final balances = <String, double>{};

    for (final leg in legs) {
      final accountId = leg['account_id'] as String;
      final assetId = leg['asset_id'] as String;
      final amount = (leg['amount'] as num).toDouble();
      final key = '$accountId:$assetId';

      balances[key] = (balances[key] ?? 0.0) + amount;
    }

    final now = DateTime.now().toIso8601String();
    for (final entry in balances.entries) {
      final parts = entry.key.split(':');
      await db.insert('account_balances', {
        'account_id': parts[0],
        'asset_id': parts[1],
        'balance': entry.value,
        'updated_at': now,
      });
    }
  }

  Future<void> updateBalancesForTransaction(
      DatabaseExecutor txn,
    List<Map<String, dynamic>> legs,
  ) async {
    final now = DateTime.now().toIso8601String();
    final updates = <String, double>{};

    for (final leg in legs) {
      final accountId = leg['account_id'] as String;
      final assetId = leg['asset_id'] as String;
      final amount = (leg['amount'] as num).toDouble();
      final key = '$accountId:$assetId';

      updates[key] = (updates[key] ?? 0.0) + amount;
    }

    for (final entry in updates.entries) {
      final parts = entry.key.split(':');
      final accountId = parts[0];
      final assetId = parts[1];

      final existing = await txn.query(
        'account_balances',
        where: 'account_id = ? AND asset_id = ?',
        whereArgs: [accountId, assetId],
        limit: 1,
      );

      if (existing.isEmpty) {
        await txn.insert('account_balances', {
          'account_id': accountId,
          'asset_id': assetId,
          'balance': entry.value,
          'updated_at': now,
        });
      } else {
        final currentBalance = (existing.first['balance'] as num).toDouble();
        final newBalance = currentBalance + entry.value;

        await txn.update(
          'account_balances',
          {'balance': newBalance, 'updated_at': now},
          where: 'account_id = ? AND asset_id = ?',
          whereArgs: [accountId, assetId],
        );
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  String generateId() => _uuid.v4();
}
