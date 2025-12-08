import 'package:ledgerone/features/ledger/services/money_summary_service_impl.dart';

import '../../app/di.dart'; // ServiceLocator
import '../../core/contracts/analytics_contract.dart';
import '../../core/data/database_contract.dart';
import '../../core/network/http_client_contract.dart';
import '../../core/observability/performance_tracker.dart';
import 'data/database.dart';
import 'data/repositories.dart';
import 'domain/services.dart';
import 'services/balance_service_impl.dart';
import 'services/portfolio_valuation_service_impl.dart';
import 'services/price_update_service_impl.dart';
import 'services/transaction_service_impl.dart';

/// Dependency injection module for the Ledger feature
///
/// This module registers all ledger-specific dependencies in three layers:
/// 1. Database - Data persistence
/// 2. Repositories - Data access layer
/// 3. Services - Business logic layer
class LedgerModule {
  /// Register all ledger dependencies
  static Future<void> register(ServiceLocator locator) async {
    // Layer 1: Database
    await _registerDatabase(locator);

    // Layer 2: Repositories
    _registerRepositories(locator);

    // Layer 3: Services
    _registerServices(locator);
  }

  /// Register the ledger database
  ///
  /// The database is registered both as:
  /// - LedgerDatabase (concrete type for feature-specific use)
  /// - DatabaseService (interface for generic use)
  static Future<void> _registerDatabase(ServiceLocator locator) async {
    final db = LedgerDatabase();

    // Warm up the database connection
    await db.database;

    locator.register<LedgerDatabase>(db);
    locator.register<DatabaseService>(db);
  }

  /// Register all data repositories
  ///
  /// Repositories provide clean access to persisted data.
  /// Each repository is registered both as its concrete type
  /// and its interface for maximum flexibility.
  static void _registerRepositories(ServiceLocator locator) {
    final db = locator.get<LedgerDatabase>();

    // Asset repository
    final assetRepo = AssetRepositoryImpl(db);
    locator.register<AssetRepository>(assetRepo);
    locator.register<AssetRepositoryImpl>(assetRepo);

    // Account repository
    final accountRepo = AccountRepositoryImpl(db);
    locator.register<AccountRepository>(accountRepo);
    locator.register<AccountRepositoryImpl>(accountRepo);

    // Category repository
    final categoryRepo = CategoryRepositoryImpl(db);
    locator.register<CategoryRepository>(categoryRepo);
    locator.register<CategoryRepositoryImpl>(categoryRepo);

    // Transaction repository
    final transactionRepo = TransactionRepositoryImpl(db);
    locator.register<TransactionRepository>(transactionRepo);
    locator.register<TransactionRepositoryImpl>(transactionRepo);

    // Price repository
    final priceRepo = PriceRepositoryImpl(db);
    locator.register<PriceRepository>(priceRepo);
    locator.register<PriceRepositoryImpl>(priceRepo);
  }

  static void _registerServices(ServiceLocator locator) {
    // Balance Service
    final balanceService = BalanceServiceImpl(
      assetRepo: locator.get<AssetRepository>(),
      accountRepo: locator.get<AccountRepository>(),
      priceRepo: locator.get<PriceRepository>(),
      transactionRepo: locator.get<TransactionRepository>(),
    );
    locator.register<BalanceService>(balanceService);

    // Portfolio Valuation Service
    final portfolioService = PortfolioValuationServiceImpl(
      balanceService: balanceService,
      priceRepo: locator.get<PriceRepository>(),
    );
    locator.register<PortfolioValuationService>(portfolioService);

    // Money Summary Service
    final moneySummaryService = MoneySummaryServiceImpl(
      balanceService: balanceService,
      transactionRepo: locator.get<TransactionRepository>(),
      categoryRepo: locator.get<CategoryRepository>(),
    );
    locator.register<MoneySummaryService>(moneySummaryService);

    // Transaction Service
    final transactionService = TransactionServiceImpl(
      db: locator.get<LedgerDatabase>(),
      transactionRepo: locator.get<TransactionRepository>(),
      assetRepo: locator.get<AssetRepository>(),
      accountRepo: locator.get<AccountRepository>(),
      analytics: locator.get<AnalyticsService>(),
      performance: PerformanceTracker(),
    );
    locator.register<TransactionService>(transactionService);

    // Price Update Service
    final priceUpdateService = PriceUpdateServiceImpl(
      httpClient: locator.get<HttpClient>(),
      assetRepo: locator.get<AssetRepository>(),
      priceRepo: locator.get<PriceRepository>(),
      db: locator.get<LedgerDatabase>(),
      analytics: locator.get<AnalyticsService>(),
      performance: PerformanceTracker(),
    );
    locator.register<PriceUpdateService>(priceUpdateService);
  }
}
