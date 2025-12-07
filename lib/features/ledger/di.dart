import '../../app/di.dart';
import '../../core/contracts/analytics_contract.dart';
import '../../core/network/http_client_contract.dart';
import '../../core/observability/performance_tracker.dart';
import 'data/database.dart';
import 'data/repositories.dart';
import 'domain/services.dart';
import 'services/balance_service_impl.dart';
import 'services/portfolio_valuation_service_impl.dart';
import 'services/price_update_service_impl.dart';
import 'services/transaction_service_impl.dart';

class LedgerModule {
  static Future<void> register(ServiceLocator locator) async {
    // Database
    final db = LedgerDatabase();
    locator.register<LedgerDatabase>(db);

    // Repositories
    final assetRepo = AssetRepositoryImpl(db);
    final accountRepo = AccountRepositoryImpl(db);
    final categoryRepo = CategoryRepositoryImpl(db);
    final transactionRepo = TransactionRepositoryImpl(db);
    final priceRepo = PriceRepositoryImpl(db);

    locator.register<AssetRepository>(assetRepo);
    locator.register<AccountRepository>(accountRepo);
    locator.register<CategoryRepository>(categoryRepo);
    locator.register<TransactionRepository>(transactionRepo);
    locator.register<PriceRepository>(priceRepo);

    // Services
    final balanceService = BalanceServiceImpl(
      assetRepo: assetRepo,
      accountRepo: accountRepo,
      priceRepo: priceRepo,
      transactionRepo: transactionRepo,
    );
    locator.register<BalanceService>(balanceService);

    final portfolioService = PortfolioValuationServiceImpl(
      balanceService: balanceService,
      priceRepo: priceRepo,
    );
    locator.register<PortfolioValuationService>(portfolioService);

    final transactionService = TransactionServiceImpl(
      db: db,
      transactionRepo: transactionRepo,
      assetRepo: assetRepo,
      accountRepo: accountRepo,
      analytics: locator.get<AnalyticsService>(),
      performance: PerformanceTracker(),
    );
    locator.register<TransactionService>(transactionService);

    final priceUpdateService = PriceUpdateServiceImpl(
      httpClient: locator.get<HttpClient>(),
      assetRepo: assetRepo,
      priceRepo: priceRepo,
      db: db,
      analytics: locator.get<AnalyticsService>(),
      performance: PerformanceTracker(),
    );
    locator.register<PriceUpdateService>(priceUpdateService);
  }
}
