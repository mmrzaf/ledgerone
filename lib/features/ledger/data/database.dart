import 'package:sqflite/sqflite.dart';

import '../../../core/data/sqlite_database_base.dart';

/// Ledger-specific database implementation
///
/// This class manages the schema and data for the LedgerOne feature,
/// including tables for:
/// - Assets (crypto, fiat, other)
/// - Accounts (exchanges, wallets, banks)
/// - Categories (income/expense classification)
/// - Transactions (logical events)
/// - Transaction Legs (balance deltas)
/// - Price Snapshots (historical prices)
class LedgerDatabase extends SqliteDatabaseBase {
  @override
  String get databaseName => 'ledgerone.db';

  @override
  int get databaseVersion => 2;

  @override
  Future<void> createSchema(Database db, int version) async {
    // Create tables
    await _createAssetsTable(db);
    await _createAccountsTable(db);
    await _createCategoriesTable(db);
    await _createTransactionsTable(db);
    await _createTransactionLegsTable(db);
    await _createPriceSnapshotsTable(db);

    // Create indexes for performance
    await _createIndexes(db);

    // Insert default data
    await _insertDefaultData(db);
  }

  // ============================================================
  // Table Creation
  // ============================================================

  Future<void> _createAssetsTable(Database db) async {
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
  }

  Future<void> _createAccountsTable(Database db) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createCategoriesTable(Database db) async {
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
  }

  Future<void> _createTransactionsTable(Database db) async {
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
  }

  Future<void> _createTransactionLegsTable(Database db) async {
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
  }

  Future<void> _createPriceSnapshotsTable(Database db) async {
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
  }

  // ============================================================
  // Indexes
  // ============================================================

  Future<void> _createIndexes(Database db) async {
    // Transaction legs indexes for balance queries
    await db.execute(
      'CREATE INDEX idx_legs_transaction ON transaction_legs(transaction_id)',
    );
    await db.execute(
      'CREATE INDEX idx_legs_account ON transaction_legs(account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_legs_asset ON transaction_legs(asset_id)',
    );

    // Price snapshots indexes
    await db.execute(
      'CREATE INDEX idx_prices_asset ON price_snapshots(asset_id)',
    );
    await db.execute(
      'CREATE INDEX idx_prices_timestamp ON price_snapshots(timestamp DESC)',
    );

    // Transaction timestamp index for queries
    await db.execute(
      'CREATE INDEX idx_transactions_timestamp ON transactions(timestamp DESC)',
    );
  }

  // ============================================================
  // Default Data
  // ============================================================

  Future<void> _insertDefaultData(Database db) async {
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
        'id': 'asset_btc',
        'symbol': 'BTC',
        'name': 'Bitcoin',
        'type': 'crypto',
        'decimals': 8,
        'price_source_config':
            '{ "method": "GET", "url": "https://api.coingecko.com/api/v3/simple/price", "query_params": { "ids": "bitcoin", "vs_currencies": "usd" }, "headers": {}, "response_path": "bitcoin.usd", "multiplier": 1.0 }',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'asset_eth',
        'symbol': 'ETH',
        'name': 'Ethereum',
        'type': 'crypto',
        'decimals': 8,
        'price_source_config':
            '{ "method": "GET", "url": "https://api.coingecko.com/api/v3/simple/price", "query_params": { "ids": "ethereum", "vs_currencies": "usd" }, "headers": {}, "response_path": "ethereum.usd", "multiplier": 1.0 }',
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
      // Income categories
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

      // Expense categories
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
      {
        'id': 'cat_utilities',
        'name': 'Utilities',
        'kind': 'expense',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'cat_entertainment',
        'name': 'Entertainment',
        'kind': 'expense',
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final category in categories) {
      await db.insert('categories', category);
    }
  }
}
