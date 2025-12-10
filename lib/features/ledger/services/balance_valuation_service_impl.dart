import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class BalanceValuationServiceImpl implements BalanceValuationService {
  final PriceRepository _priceRepo;

  BalanceValuationServiceImpl({required PriceRepository priceRepo})
    : _priceRepo = priceRepo;

  @override
  Future<List<ValuatedAssetBalance>> valuate(
    List<TotalAssetBalance> balances,
  ) async {
    final latestPrices = await _priceRepo.getLatestPrices();
    final priceMap = <String, PriceSnapshot>{};
    for (final snapshot in latestPrices) {
      priceMap[snapshot.assetId] = snapshot;
    }

    return balances.map((balance) {
      final snapshot = priceMap[balance.asset.id];
      final usdValue = snapshot != null
          ? balance.totalBalance * snapshot.price
          : null;

      return ValuatedAssetBalance(
        balance: balance,
        usdValue: usdValue,
        priceSnapshot: snapshot,
      );
    }).toList();
  }

  @override
  Future<PriceSnapshot?> getLatestPrice(String assetId) async {
    return _priceRepo.getLatestPrice(assetId);
  }
}
