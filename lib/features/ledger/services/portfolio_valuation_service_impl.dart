import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class PortfolioValuationServiceImpl implements PortfolioValuationService {
  final BalanceService balanceService;
  final PriceRepository priceRepo;

  static const Duration staleThreshold = Duration(hours: 24);

  PortfolioValuationServiceImpl({
    required this.balanceService,
    required this.priceRepo,
  });

  @override
  Future<PortfolioValuation> getPortfolioValue() async {
    final balances = await balanceService.getAllBalances();
    final lastUpdate = await getLastPriceUpdate();
    final isStale = await isPriceDataStale();

    double totalValue = 0.0;
    double cryptoValue = 0.0;
    double fiatValue = 0.0;
    double otherValue = 0.0;

    for (final balance in balances) {
      if (balance.usdValue != null) {
        final value = balance.usdValue!;
        totalValue += value;

        switch (balance.asset.type) {
          case AssetType.crypto:
            cryptoValue += value;
            break;
          case AssetType.fiat:
            fiatValue += value;
            break;
          case AssetType.other:
            otherValue += value;
            break;
        }
      }
    }

    return PortfolioValuation(
      totalValue: totalValue,
      cryptoValue: cryptoValue,
      fiatValue: fiatValue,
      otherValue: otherValue,
      lastPriceUpdate: lastUpdate,
      isPriceDataStale: isStale,
    );
  }

  @override
  Future<bool> isPriceDataStale() async {
    final lastUpdate = await getLastPriceUpdate();
    if (lastUpdate == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference > staleThreshold;
  }

  @override
  Future<DateTime?> getLastPriceUpdate() async {
    return await priceRepo.getLatestPriceTimestamp();
  }
}
