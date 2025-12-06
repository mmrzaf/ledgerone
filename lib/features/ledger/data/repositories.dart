import '../domain/models.dart';
import 'database.dart';

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
  Future<void> insert(Asset asset) async {
    final db = await _db.database;
    await db.insert('assets', asset.toJson());
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

class AccountRepositoryImpl implements AccountRepository {
  final LedgerDatabase _db;

  AccountRepositoryImpl(this._db);

  @override
  Future<List<Account>> getAll({bool includeArchived = false}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: includeArchived ? null : 'archived = 0',
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
  Future<void> insert(Account account) async {
    final db = await _db.database;
    await db.insert('accounts', account.toJson());
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
    await db.insert('categories', category.toJson());
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

class TransactionRepositoryImpl implements TransactionRepository {
  final LedgerDatabase _db;

  TransactionRepositoryImpl(this._db);

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
    // Legs will be deleted automatically due to CASCADE
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

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
}

class PriceRepositoryImpl implements PriceRepository {
  final LedgerDatabase _db;

  PriceRepositoryImpl(this._db);

  @override
  Future<List<PriceSnapshot>> getLatestPrices() async {
    final db = await _db.database;

    // Get latest price for each asset
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.* FROM price_snapshots p
      INNER JOIN (
        SELECT asset_id, MAX(timestamp) as max_timestamp
        FROM price_snapshots
        WHERE currency_code = 'USD'
        GROUP BY asset_id
      ) latest ON p.asset_id = latest.asset_id AND p.timestamp = latest.max_timestamp
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
}

class BalanceServiceImpl implements BalanceService {
  final LedgerDatabase _db;
  final AssetRepository _assetRepo;
  final AccountRepository _accountRepo;
  final PriceRepository _priceRepo;

  BalanceServiceImpl(
    this._db,
    this._assetRepo,
    this._accountRepo,
    this._priceRepo,
  );

  @override
  Future<double> getBalance(String assetId, String accountId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as balance
      FROM transaction_legs
      WHERE asset_id = ? AND account_id = ?
    ''',
      [assetId, accountId],
    );

    if (result.isEmpty || result.first['balance'] == null) {
      return 0.0;
    }
    return (result.first['balance'] as num).toDouble();
  }

  @override
  Future<double> getTotalBalance(String assetId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as balance
      FROM transaction_legs
      WHERE asset_id = ?
    ''',
      [assetId],
    );

    if (result.isEmpty || result.first['balance'] == null) {
      return 0.0;
    }
    return (result.first['balance'] as num).toDouble();
  }

  @override
  Future<List<AssetBalance>> getAccountBalances(String accountId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        l.asset_id,
        l.account_id,
        SUM(l.amount) as balance
      FROM transaction_legs l
      WHERE l.account_id = ?
      GROUP BY l.asset_id, l.account_id
      HAVING balance != 0
    ''',
      [accountId],
    );

    final balances = <AssetBalance>[];
    final account = await _accountRepo.getById(accountId);
    if (account == null) return balances;

    for (final row in result) {
      final asset = await _assetRepo.getById(row['asset_id'] as String);
      if (asset != null) {
        balances.add(
          AssetBalance(
            assetId: row['asset_id'] as String,
            accountId: row['account_id'] as String,
            balance: (row['balance'] as num).toDouble(),
            asset: asset,
            account: account,
          ),
        );
      }
    }

    return balances;
  }

  @override
  Future<List<TotalAssetBalance>> getAllBalances({
    bool includeZero = false,
  }) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT 
        l.asset_id,
        l.account_id,
        SUM(l.amount) as balance
      FROM transaction_legs l
      GROUP BY l.asset_id, l.account_id
      ${includeZero ? '' : 'HAVING balance != 0'}
    ''');

    // Group by asset
    final Map<String, List<Map<String, dynamic>>> byAsset = {};
    for (final row in result) {
      final assetId = row['asset_id'] as String;
      byAsset.putIfAbsent(assetId, () => []);
      byAsset[assetId]!.add(row);
    }

    final balances = <TotalAssetBalance>[];
    final latestPrices = await _priceRepo.getLatestPrices();
    final priceMap = {for (var p in latestPrices) p.assetId: p.price};

    for (final entry in byAsset.entries) {
      final assetId = entry.key;
      final asset = await _assetRepo.getById(assetId);
      if (asset == null) continue;

      double totalBalance = 0;
      final accountBalances = <AssetBalance>[];

      for (final row in entry.value) {
        final balance = (row['balance'] as num).toDouble();
        totalBalance += balance;

        final account = await _accountRepo.getById(row['account_id'] as String);
        if (account != null) {
          accountBalances.add(
            AssetBalance(
              assetId: assetId,
              accountId: row['account_id'] as String,
              balance: balance,
              asset: asset,
              account: account,
            ),
          );
        }
      }

      final usdValue = priceMap[assetId] != null
          ? totalBalance * priceMap[assetId]!
          : null;

      balances.add(
        TotalAssetBalance(
          asset: asset,
          totalBalance: totalBalance,
          usdValue: usdValue,
          accountBalances: accountBalances,
        ),
      );
    }

    return balances;
  }

  @override
  Future<Map<String, double>> getPortfolioValue() async {
    final balances = await getAllBalances();

    final portfolio = <String, double>{
      'crypto': 0.0,
      'fiat': 0.0,
      'other': 0.0,
      'total': 0.0,
    };

    for (final balance in balances) {
      if (balance.usdValue != null) {
        final type = balance.asset.type.name;
        portfolio[type] = (portfolio[type] ?? 0.0) + balance.usdValue!;
        portfolio['total'] = portfolio['total']! + balance.usdValue!;
      }
    }

    return portfolio;
  }
}
