import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class BalanceServiceImpl implements BalanceService {
  final AssetRepository _assetRepo;
  final AccountRepository _accountRepo;
  final TransactionRepository _transactionRepo;

  BalanceServiceImpl({
    required AssetRepository assetRepo,
    required AccountRepository accountRepo,
    required TransactionRepository transactionRepo,
  }) : _assetRepo = assetRepo,
       _accountRepo = accountRepo,
       _transactionRepo = transactionRepo;

  @override
  Future<double> getBalance(String assetId, String accountId) async {
    final balances = await _transactionRepo.getBalancesByAccountAndAsset();

    final match = balances.firstWhere(
      (b) => b['asset_id'] == assetId && b['account_id'] == accountId,
      orElse: () => <String, dynamic>{},
    );

    return (match['balance'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<double> getTotalBalance(String assetId) async {
    final balances = await _transactionRepo.getBalancesByAsset();

    final match = balances.firstWhere(
      (b) => b['asset_id'] == assetId,
      orElse: () => <String, dynamic>{},
    );

    return (match['balance'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<List<AssetBalance>> getAccountBalances(String accountId) async {
    final assetMap = await _assetRepo.getAllAsMap();
    final account = await _accountRepo.getById(accountId);
    if (account == null) return [];

    final balances = await _transactionRepo.getBalancesForAccount(accountId);

    final result = <AssetBalance>[];
    for (final row in balances) {
      final assetId = row['asset_id'] as String;
      final balance = (row['balance'] as num).toDouble();

      final asset = assetMap[assetId];
      if (asset == null) continue;

      result.add(
        AssetBalance(
          assetId: assetId,
          accountId: accountId,
          balance: balance,
          asset: asset,
          account: account,
        ),
      );
    }

    return result;
  }

  @override
  Future<List<TotalAssetBalance>> getAllBalances({
    bool includeZero = false,
  }) async {
    final assetMap = await _assetRepo.getAllAsMap();
    final accountMap = await _accountRepo.getAllAsMap();

    final accountAssetBalances = await _transactionRepo
        .getBalancesByAccountAndAsset();

    final Map<String, List<Map<String, dynamic>>> byAsset = {};
    for (final row in accountAssetBalances) {
      final assetId = row['asset_id'] as String;
      byAsset.putIfAbsent(assetId, () => []);
      byAsset[assetId]!.add(row);
    }

    final result = <TotalAssetBalance>[];

    for (final entry in byAsset.entries) {
      final assetId = entry.key;
      final asset = assetMap[assetId];
      if (asset == null) continue;

      double totalBalance = 0.0;
      final accountBalances = <AssetBalance>[];

      for (final row in entry.value) {
        final accountId = row['account_id'] as String;
        final balance = (row['balance'] as num).toDouble();

        if (!includeZero && balance == 0.0) continue;

        totalBalance += balance;
        final account = accountMap[accountId];
        if (account != null) {
          accountBalances.add(
            AssetBalance(
              assetId: assetId,
              accountId: accountId,
              balance: balance,
              asset: asset,
              account: account,
            ),
          );
        }
      }

      if (!includeZero && totalBalance == 0.0) continue;

      result.add(
        TotalAssetBalance(
          asset: asset,
          totalBalance: totalBalance,
          accountBalances: accountBalances,
        ),
      );
    }

    // Sort by asset symbol
    result.sort((a, b) => a.asset.symbol.compareTo(b.asset.symbol));

    return result;
  }
}
