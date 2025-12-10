import 'package:ledgerone/features/ledger/services/balance_valuation_service_impl.dart';

import '../../app/di.dart';
import '../../core/contracts/analytics_contract.dart';
import '../../core/data/database_contract.dart';
import '../../core/network/http_client_contract.dart';
import '../../core/observability/performance_tracker.dart';
import 'data/database.dart';
import 'data/repositories.dart';
import 'domain/services.dart';
import 'services/balance_service_impl.dart';
import 'services/money_summary_service_impl.dart';
import 'services/portfolio_valuation_service_impl.dart';
import 'services/price_update_service_impl.dart';
import 'services/transaction_service_impl.dart';

/// Ledger feature dependency injection module
class LedgerModule {
  /// Register all ledger dependencies in proper order:
  /// 1. Database
  /// 2. Repositories
  /// 3. Services
  static Future<void> register(ServiceLocator locator) async {
    await _registerDatabase(locator);
    _registerRepositories(locator);
    _registerServices(locator);
  }

  // ---------------------------------------------------------------------------
  // Layer 1: Database
  // ---------------------------------------------------------------------------

  static Future<void> _registerDatabase(ServiceLocator locator) async {
    final db = LedgerDatabase();

    // Warm up the database connection
    await db.database;

    // Register as both concrete and abstract types
    locator.register<LedgerDatabase>(db);
    locator.register<DatabaseService>(db);
  }

  // ---------------------------------------------------------------------------
  // Layer 2: Repositories
  // ---------------------------------------------------------------------------

  static void _registerRepositories(ServiceLocator locator) {
    final db = locator.get<LedgerDatabase>();

    // Asset Repository
    final assetRepo = AssetRepositoryImpl(db);
    locator.register<AssetRepository>(assetRepo);

    // Account Repository
    final accountRepo = AccountRepositoryImpl(db);
    locator.register<AccountRepository>(accountRepo);

    // Category Repository
    final categoryRepo = CategoryRepositoryImpl(db);
    locator.register<CategoryRepository>(categoryRepo);

    // Transaction Repository
    final transactionRepo = TransactionRepositoryImpl(db);
    locator.register<TransactionRepository>(transactionRepo);

    // Price Repository
    final priceRepo = PriceRepositoryImpl(db);
    locator.register<PriceRepository>(priceRepo);
  }
  // ---------------------------------------------------------------------------
  // Layer 3: Services
  // ---------------------------------------------------------------------------

  static void _registerServices(ServiceLocator locator) {
    // Shared dependencies
    final analytics = locator.get<AnalyticsService>();
    final performance = PerformanceTracker();

    // Balance Service – deals ONLY with amounts
    final balanceService = BalanceServiceImpl(
      assetRepo: locator.get<AssetRepository>(),
      accountRepo: locator.get<AccountRepository>(),
      transactionRepo: locator.get<TransactionRepository>(),
    );
    locator.register<BalanceService>(balanceService);

    // Balance Valuation Service – adds USD values to balances
    final balanceValuationService = BalanceValuationServiceImpl(
      priceRepo: locator.get<PriceRepository>(),
    );
    locator.register<BalanceValuationService>(balanceValuationService);

    // Portfolio Valuation Service – portfolio-level USD stats + stale check
    final portfolioService = PortfolioValuationServiceImpl(
      balanceService: balanceService,
      priceRepo: locator.get<PriceRepository>(),
    );
    locator.register<PortfolioValuationService>(portfolioService);

    // Money Summary Service – uses BalanceService only (no valuations)
    final moneySummaryService = MoneySummaryServiceImpl(
      balanceService: balanceService,
      transactionRepo: locator.get<TransactionRepository>(),
      categoryRepo: locator.get<CategoryRepository>(),
    );
    locator.register<MoneySummaryService>(moneySummaryService);

    // Transaction Service – db + repos + analytics
    final transactionService = TransactionServiceImpl(
      db: locator.get<LedgerDatabase>(),
      transactionRepo: locator.get<TransactionRepository>(),
      assetRepo: locator.get<AssetRepository>(),
      accountRepo: locator.get<AccountRepository>(),
      analytics: analytics,
      performance: performance,
    );
    locator.register<TransactionService>(transactionService);

    // Price Update Service – http + repos + analytics
    final priceUpdateService = PriceUpdateServiceImpl(
      httpClient: locator.get<HttpClient>(),
      assetRepo: locator.get<AssetRepository>(),
      priceRepo: locator.get<PriceRepository>(),
      db: locator.get<LedgerDatabase>(),
      analytics: analytics,
      performance: performance,
    );
    locator.register<PriceUpdateService>(priceUpdateService);
  }
}
