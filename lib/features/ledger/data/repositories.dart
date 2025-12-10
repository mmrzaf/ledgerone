import '../domain/models.dart';
import 'database.dart';
import 'repositories_interfaces.dart';

export 'repositories_interfaces.dart';

// =============================================================================
// Asset Repository
// =============================================================================

class AssetRepositoryImpl implements AssetRepository {
  final LedgerDatabase _db;

  AssetRepositoryImpl(this._db);

  @override
  Future<List<Asset>> getAll({bool includeDeleted = false}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assets',
      orderBy: 'symbol ASC',
    );
    return maps.map((map) => Asset.fromJson(map)).toList();
  }

  @override
  Future<Asset?> getById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Asset.fromJson(maps.first);
  }

  @override
  Future<Map<String, Asset>> getAllAsMap() async {
    final assets = await getAll();
    return {for (final asset in assets) asset.id: asset};
  }

  @override
  Future<void> insert(Asset asset) async {
    final db = await _db.database;
    final assetToInsert = asset.id.isEmpty
        ? asset.copyWith(id: _db.generateId())
        : asset;
    await db.insert('assets', assetToInsert.toJson());
  }

  @override
  Future<void> update(Asset asset) async {
    final db = await _db.database;
    await db.update(
      'assets',
      asset.toJson(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }
}

// =============================================================================
// Account Repository
// =============================================================================

class AccountRepositoryImpl implements AccountRepository {
  final LedgerDatabase _db;

  AccountRepositoryImpl(this._db);

  @override
  Future<List<Account>> getAll() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      orderBy: 'name ASC',
    );
    return maps.map((map) => Account.fromJson(map)).toList();
  }

  @override
  Future<Account?> getById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Account.fromJson(maps.first);
  }

  @override
  Future<Map<String, Account>> getAllAsMap() async {
    final accounts = await getAll();
    return {for (final account in accounts) account.id: account};
  }

  @override
  Future<void> insert(Account account) async {
    final db = await _db.database;
    final accountToInsert = account.id.isEmpty
        ? account.copyWith(id: _db.generateId())
        : account;
    await db.insert('accounts', accountToInsert.toJson());
  }

  @override
  Future<void> update(Account account) async {
    final db = await _db.database;
    await db.update(
      'accounts',
      account.toJson(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }
}

// =============================================================================
// Category Repository
// =============================================================================

class CategoryRepositoryImpl implements CategoryRepository {
  final LedgerDatabase _db;

  CategoryRepositoryImpl(this._db);

  @override
  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'name ASC',
    );
    return maps.map((map) => Category.fromJson(map)).toList();
  }

  @override
  Future<Category?> getById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Category.fromJson(maps.first);
  }

  @override
  Future<void> insert(Category category) async {
    final db = await _db.database;
    final categoryToInsert = category.id.isEmpty
        ? category.copyWith(id: _db.generateId())
        : category;
    await db.insert('categories', categoryToInsert.toJson());
  }

  @override
  Future<void> update(Category category) async {
    final db = await _db.database;
    await db.update(
      'categories',
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

// =============================================================================
// Transaction Repository
// =============================================================================

class TransactionRepositoryImpl implements TransactionRepository {
  final LedgerDatabase _db;

  TransactionRepositoryImpl(this._db);

  // ---------------------------------------------------------------------------
  // Transaction CRUD
  // ---------------------------------------------------------------------------

  @override
  Future<List<Transaction>> getAll({
    int? limit,
    DateTime? before,
    DateTime? after,
  }) async {
    final db = await _db.database;

    String? where;
    List<dynamic>? whereArgs;

    if (before != null && after != null) {
      where = 'timestamp BETWEEN ? AND ?';
      whereArgs = [after.toIso8601String(), before.toIso8601String()];
    } else if (before != null) {
      where = 'timestamp <= ?';
      whereArgs = [before.toIso8601String()];
    } else if (after != null) {
      where = 'timestamp >= ?';
      whereArgs = [after.toIso8601String()];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => Transaction.fromJson(map)).toList();
  }

  @override
  Future<Transaction?> getById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Transaction.fromJson(maps.first);
  }

  @override
  Future<void> insert(
    Transaction transaction,
    List<TransactionLeg> legs,
  ) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      await txn.insert('transactions', transaction.toJson());
      for (final leg in legs) {
        await txn.insert('transaction_legs', leg.toJson());
      }
    });
  }

  @override
  Future<void> update(
    Transaction transaction,
    List<TransactionLeg> legs,
  ) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      // Update transaction
      await txn.update(
        'transactions',
        transaction.toJson(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      // Delete old legs and insert new ones
      await txn.delete(
        'transaction_legs',
        where: 'transaction_id = ?',
        whereArgs: [transaction.id],
      );

      for (final leg in legs) {
        await txn.insert('transaction_legs', leg.toJson());
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      // Delete legs first (foreign key constraint)
      await txn.delete(
        'transaction_legs',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      // Delete transaction
      await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ---------------------------------------------------------------------------
  // Leg Queries
  // ---------------------------------------------------------------------------

  @override
  Future<List<TransactionLeg>> getLegsForTransaction(
    String transactionId,
  ) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_legs',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return maps.map((map) => TransactionLeg.fromJson(map)).toList();
  }

  @override
  Future<List<TransactionLeg>> getAllLegs() async {
    final db = await _db.database;
    final maps = await db.query('transaction_legs');
    return maps.map((m) => TransactionLeg.fromJson(m)).toList();
  }

  // ---------------------------------------------------------------------------
  // Balance Aggregations
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getBalancesByAccountAndAsset() async {
    final db = await _db.database;

    final results = await db.rawQuery('''
      SELECT
        account_id,
        asset_id,
        SUM(amount) as balance
      FROM transaction_legs
      GROUP BY account_id, asset_id
      HAVING ABS(SUM(amount)) > 0.00000001
    ''');

    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getBalancesByAsset() async {
    final db = await _db.database;

    final results = await db.rawQuery('''
      SELECT
        asset_id,
        SUM(amount) as balance
      FROM transaction_legs
      GROUP BY asset_id
      HAVING ABS(SUM(amount)) > 0.00000001
    ''');

    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getBalancesForAccount(
    String accountId,
  ) async {
    final db = await _db.database;

    final results = await db.rawQuery(
      '''
      SELECT
        asset_id,
        SUM(amount) as balance
      FROM transaction_legs
      WHERE account_id = ?
      GROUP BY asset_id
      HAVING ABS(SUM(amount)) > 0.00000001
    ''',
      [accountId],
    );

    return results;
  }
}

// =============================================================================
// Price Repository
// =============================================================================

class PriceRepositoryImpl implements PriceRepository {
  final LedgerDatabase _db;

  PriceRepositoryImpl(this._db);

  @override
  Future<List<PriceSnapshot>> getLatestPrices() async {
    final db = await _db.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.* FROM price_snapshots p
      INNER JOIN (
        SELECT asset_id, MAX(timestamp) as max_timestamp
        FROM price_snapshots
        WHERE currency_code = 'USD'
        GROUP BY asset_id
      ) latest ON p.asset_id = latest.asset_id
              AND p.timestamp = latest.max_timestamp
    ''');

    return maps.map((map) => PriceSnapshot.fromJson(map)).toList();
  }

  @override
  Future<PriceSnapshot?> getLatestPrice(
    String assetId, {
    String currency = 'USD',
  }) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'price_snapshots',
      where: 'asset_id = ? AND currency_code = ?',
      whereArgs: [assetId, currency],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PriceSnapshot.fromJson(maps.first);
  }

  @override
  Future<void> insert(PriceSnapshot snapshot) async {
    final db = await _db.database;
    await db.insert('price_snapshots', snapshot.toJson());
  }

  @override
  Future<List<PriceSnapshot>> getHistory(
    String assetId, {
    String currency = 'USD',
    int? limit,
  }) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'price_snapshots',
      where: 'asset_id = ? AND currency_code = ?',
      whereArgs: [assetId, currency],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => PriceSnapshot.fromJson(map)).toList();
  }

  @override
  Future<DateTime?> getLatestPriceTimestamp() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT MAX(timestamp) as latest FROM price_snapshots
    ''');

    if (result.isEmpty || result.first['latest'] == null) {
      return null;
    }

    return DateTime.parse(result.first['latest'] as String);
  }
}
