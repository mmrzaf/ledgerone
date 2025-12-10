import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class PortfolioValuationServiceImpl implements PortfolioValuationService {
  final BalanceService _balanceService;
  final PriceRepository _priceRepo;

  static const Duration staleThreshold = Duration(hours: 24);

  PortfolioValuationServiceImpl({
    required BalanceService balanceService,
    required PriceRepository priceRepo,
  }) : _balanceService = balanceService,
       _priceRepo = priceRepo;

  @override
  Future<PortfolioValuation> getPortfolioValue() async {
    final balances = await _balanceService.getAllBalances();
    final lastUpdate = await getLastPriceUpdate();
    final isStale = await isPriceDataStale();

    double totalValue = 0.0;
    double cryptoValue = 0.0;
    double fiatValue = 0.0;

    // We still use priceRepo here – this *is* the portfolio valuation layer
    final latestPrices = await _priceRepo.getLatestPrices();
    final priceMap = {for (final p in latestPrices) p.assetId: p.price};

    for (final balance in balances) {
      final asset = balance.asset;
      final price = priceMap[asset.id];

      if (price == null) continue;

      final value = balance.totalBalance * price;
      totalValue += value;

      if (asset.type == AssetType.crypto) {
        cryptoValue += value;
      } else if (asset.type == AssetType.fiat) {
        fiatValue += value;
      }
    }

    return PortfolioValuation(
      totalValue: totalValue,
      cryptoValue: cryptoValue,
      fiatValue: fiatValue,
      lastPriceUpdate: lastUpdate,
      // TODO check what is other value
      otherValue: 0,
      isPriceDataStale: isStale,
    );
  }

  @override
  Future<bool> isPriceDataStale() async {
    final lastUpdate = await getLastPriceUpdate();
    if (lastUpdate == null) return true;
    final age = DateTime.now().difference(lastUpdate);
    return age > staleThreshold;
  }

  @override
  Future<DateTime?> getLastPriceUpdate() async {
    return _priceRepo.getLatestPriceTimestamp();
  }
}
