import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:uuid/uuid.dart';
import '../domain/models.dart';

class LedgerDatabase {
  static const String _dbName = 'ledgerone.db';
  static const int _dbVersion = 1;
  static final _uuid = const Uuid();
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
    // Assets table
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

    // Accounts table
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

    // Categories table
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

    // Transactions table
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

    // Transaction legs table
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

    // Price snapshots table
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

    // Indexes for performance
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

    // Insert default assets (USD, EUR, BTC, ETH)
    await _insertDefaultAssets(db);

    // Insert default categories
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
    // Handle migrations here when schema changes
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  String generateId() => _uuid.v4();
}

// Repository interfaces
abstract class AssetRepository {
  Future<List<Asset>> getAll({bool includeDeleted = false});
  Future<Asset?> getById(String id);
  Future<void> insert(Asset asset);
  Future<void> update(Asset asset);
  Future<void> delete(String id);
}

abstract class AccountRepository {
  Future<List<Account>> getAll({bool includeArchived = false});
  Future<Account?> getById(String id);
  Future<void> insert(Account account);
  Future<void> update(Account account);
  Future<void> delete(String id);
}

abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<Category?> getById(String id);
  Future<void> insert(Category category);
  Future<void> update(Category category);
  Future<void> delete(String id);
}

abstract class TransactionRepository {
  Future<List<Transaction>> getAll({
    int? limit,
    DateTime? before,
    DateTime? after,
  });
  Future<Transaction?> getById(String id);
  Future<void> insert(Transaction transaction, List<TransactionLeg> legs);
  Future<void> update(Transaction transaction, List<TransactionLeg> legs);
  Future<void> delete(String id);
  Future<List<TransactionLeg>> getLegsForTransaction(String transactionId);
}

abstract class PriceRepository {
  Future<List<PriceSnapshot>> getLatestPrices();
  Future<PriceSnapshot?> getLatestPrice(
    String assetId, {
    String currency = 'USD',
  });
  Future<void> insert(PriceSnapshot snapshot);
  Future<List<PriceSnapshot>> getHistory(
    String assetId, {
    String currency = 'USD',
    int? limit,
  });
}

// Balance calculation interface
abstract class BalanceService {
  Future<double> getBalance(String assetId, String accountId);
  Future<double> getTotalBalance(String assetId);
  Future<List<AssetBalance>> getAccountBalances(String accountId);
  Future<List<TotalAssetBalance>> getAllBalances({bool includeZero = false});
  Future<Map<String, double>>
  getPortfolioValue(); // Returns {asset_type: usd_value}
}
