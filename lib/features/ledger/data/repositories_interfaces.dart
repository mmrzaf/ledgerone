import '../domain/models.dart';

abstract class AssetRepository {
  Future<List<Asset>> getAll({bool includeDeleted = false});
  Future<Asset?> getById(String id);
  Future<Map<String, Asset>> getAllAsMap();
  Future<void> insert(Asset asset);
  Future<void> update(Asset asset);
  Future<void> delete(String id);
}

abstract class AccountRepository {
  Future<List<Account>> getAll();
  Future<Account?> getById(String id);
  Future<Map<String, Account>> getAllAsMap();
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
  Future<DateTime?> getLatestPriceTimestamp();
}
