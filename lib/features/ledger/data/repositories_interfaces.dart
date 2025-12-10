import '../domain/models.dart';

/// Repository for Asset entities
abstract class AssetRepository {
  /// Get all assets, optionally including soft-deleted ones
  Future<List<Asset>> getAll({bool includeDeleted = false});

  /// Get a single asset by ID
  Future<Asset?> getById(String id);

  /// Get all assets as a map keyed by ID (for efficient lookups)
  Future<Map<String, Asset>> getAllAsMap();

  /// Insert a new asset (ID will be generated if empty)
  Future<void> insert(Asset asset);

  /// Update an existing asset
  Future<void> update(Asset asset);

  /// Delete an asset by ID
  Future<void> delete(String id);
}

/// Repository for Account entities
abstract class AccountRepository {
  /// Get all accounts
  Future<List<Account>> getAll();

  /// Get a single account by ID
  Future<Account?> getById(String id);

  /// Get all accounts as a map keyed by ID
  Future<Map<String, Account>> getAllAsMap();

  /// Insert a new account (ID will be generated if empty)
  Future<void> insert(Account account);

  /// Update an existing account
  Future<void> update(Account account);

  /// Delete an account by ID
  Future<void> delete(String id);
}

/// Repository for Category entities
abstract class CategoryRepository {
  /// Get all categories
  Future<List<Category>> getAll();

  /// Get a single category by ID
  Future<Category?> getById(String id);

  /// Insert a new category
  Future<void> insert(Category category);

  /// Update an existing category
  Future<void> update(Category category);

  /// Delete a category by ID
  Future<void> delete(String id);
}

/// Repository for Transaction and TransactionLeg entities
abstract class TransactionRepository {
  // -------------------------------------------------------------------------
  // Transaction CRUD
  // -------------------------------------------------------------------------

  /// Get all transactions with optional filtering
  Future<List<Transaction>> getAll({
    int? limit,
    DateTime? before,
    DateTime? after,
  });

  /// Get a single transaction by ID
  Future<Transaction?> getById(String id);

  /// Insert a transaction with its legs (atomic operation)
  Future<void> insert(Transaction transaction, List<TransactionLeg> legs);

  /// Update a transaction and replace its legs (atomic operation)
  Future<void> update(Transaction transaction, List<TransactionLeg> legs);

  /// Delete a transaction and its legs (atomic operation)
  Future<void> delete(String id);

  // -------------------------------------------------------------------------
  // Leg Queries
  // -------------------------------------------------------------------------

  /// Get all legs for a specific transaction
  Future<List<TransactionLeg>> getLegsForTransaction(String transactionId);

  /// Get all legs (for bulk operations)
  Future<List<TransactionLeg>> getAllLegs();

  // -------------------------------------------------------------------------
  // Balance Aggregations (SQL-optimized)
  // -------------------------------------------------------------------------

  /// Get balances grouped by account and asset
  /// Returns: [{'account_id': String, 'asset_id': String, 'balance': double}]
  Future<List<Map<String, dynamic>>> getBalancesByAccountAndAsset();

  /// Get balances grouped by asset (across all accounts)
  /// Returns: [{'asset_id': String, 'balance': double}]
  Future<List<Map<String, dynamic>>> getBalancesByAsset();

  /// Get balances for a specific account
  /// Returns: [{'asset_id': String, 'balance': double}]
  Future<List<Map<String, dynamic>>> getBalancesForAccount(String accountId);
}

/// Repository for PriceSnapshot entities
abstract class PriceRepository {
  /// Get the latest price snapshot for each asset
  Future<List<PriceSnapshot>> getLatestPrices();

  /// Get the latest price for a specific asset
  Future<PriceSnapshot?> getLatestPrice(
    String assetId, {
    String currency = 'USD',
  });

  /// Insert a new price snapshot
  Future<void> insert(PriceSnapshot snapshot);

  /// Get price history for an asset
  Future<List<PriceSnapshot>> getHistory(
    String assetId, {
    String currency = 'USD',
    int? limit,
  });

  /// Get the timestamp of the most recent price update
  Future<DateTime?> getLatestPriceTimestamp();
}
