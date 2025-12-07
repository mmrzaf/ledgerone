import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class BalanceServiceImpl implements BalanceService {
  final AssetRepository assetRepo;
  final AccountRepository accountRepo;
  final PriceRepository priceRepo;
  final TransactionRepository transactionRepo;

  BalanceServiceImpl({
    required this.assetRepo,
    required this.accountRepo,
    required this.priceRepo,
    required this.transactionRepo,
  });

  @override
  Future<double> getBalance(String assetId, String accountId) async {
    final legs = await transactionRepo.getAll();
    double balance = 0.0;

    for (final tx in legs) {
      final txLegs = await transactionRepo.getLegsForTransaction(tx.id);
      for (final leg in txLegs) {
        if (leg.assetId == assetId && leg.accountId == accountId) {
          balance += leg.amount;
        }
      }
    }

    return balance;
  }

  @override
  Future<double> getTotalBalance(String assetId) async {
    final legs = await transactionRepo.getAll();
    double balance = 0.0;

    for (final tx in legs) {
      final txLegs = await transactionRepo.getLegsForTransaction(tx.id);
      for (final leg in txLegs) {
        if (leg.assetId == assetId) {
          balance += leg.amount;
        }
      }
    }

    return balance;
  }

  @override
  Future<List<AssetBalance>> getAccountBalances(String accountId) async {
    final assetMap = await assetRepo.getAllAsMap();
    final accountMap = await accountRepo.getAllAsMap();

    final account = accountMap[accountId];
    if (account == null) return [];

    final balanceMap = <String, double>{};
    final legs = await transactionRepo.getAll();

    for (final tx in legs) {
      final txLegs = await transactionRepo.getLegsForTransaction(tx.id);
      for (final leg in txLegs) {
        if (leg.accountId == accountId) {
          balanceMap[leg.assetId] =
              (balanceMap[leg.assetId] ?? 0.0) + leg.amount;
        }
      }
    }

    final result = <AssetBalance>[];
    for (final entry in balanceMap.entries) {
      if (entry.value != 0.0) {
        final asset = assetMap[entry.key];
        if (asset != null) {
          result.add(
            AssetBalance(
              assetId: entry.key,
              accountId: accountId,
              balance: entry.value,
              asset: asset,
              account: account,
            ),
          );
        }
      }
    }

    return result;
  }

  @override
  Future<List<TotalAssetBalance>> getAllBalances({
    bool includeZero = false,
  }) async {
    final assetMap = await assetRepo.getAllAsMap();
    final accountMap = await accountRepo.getAllAsMap();
    final latestPrices = await priceRepo.getLatestPrices();
    final priceMap = {for (var p in latestPrices) p.assetId: p.price};

    final balanceMap = <String, Map<String, double>>{};
    final legs = await transactionRepo.getAll();

    for (final tx in legs) {
      final txLegs = await transactionRepo.getLegsForTransaction(tx.id);
      for (final leg in txLegs) {
        balanceMap.putIfAbsent(leg.assetId, () => {});
        final current = balanceMap[leg.assetId]![leg.accountId] ?? 0.0;
        balanceMap[leg.assetId]![leg.accountId] = current + leg.amount;
      }
    }

    final result = <TotalAssetBalance>[];
    for (final assetEntry in balanceMap.entries) {
      final assetId = assetEntry.key;
      final asset = assetMap[assetId];
      if (asset == null) continue;

      double totalBalance = 0.0;
      final accountBalances = <AssetBalance>[];

      for (final accountEntry in assetEntry.value.entries) {
        final balance = accountEntry.value;
        if (!includeZero && balance == 0.0) continue;

        totalBalance += balance;
        final account = accountMap[accountEntry.key];
        if (account != null) {
          accountBalances.add(
            AssetBalance(
              assetId: assetId,
              accountId: accountEntry.key,
              balance: balance,
              asset: asset,
              account: account,
            ),
          );
        }
      }

      if (!includeZero && totalBalance == 0.0) continue;

      final usdValue = priceMap[assetId] != null
          ? totalBalance * priceMap[assetId]!
          : null;

      result.add(
        TotalAssetBalance(
          asset: asset,
          totalBalance: totalBalance,
          usdValue: usdValue,
          accountBalances: accountBalances,
        ),
      );
    }

    return result;
  }
}
