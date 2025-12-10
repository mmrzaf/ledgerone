import '../../../core/errors/app_error.dart';
import 'models.dart';

// =============================================================================
// Balance Service
// =============================================================================

/// Service for computing balances from transaction data
abstract class BalanceService {
  /// Get balance for a specific asset in a specific account
  Future<double> getBalance(String assetId, String accountId);

  /// Get total balance for an asset across all accounts
  Future<double> getTotalBalance(String assetId);

  /// Get all asset balances for a specific account
  Future<List<AssetBalance>> getAccountBalances(String accountId);

  /// Get all balances grouped by asset with account breakdown
  Future<List<TotalAssetBalance>> getAllBalances({bool includeZero = false});
}

// =============================================================================
// Transaction Service
// =============================================================================

/// Service for creating and managing transactions
abstract class TransactionService {
  /// Create an income transaction
  Future<Transaction> createIncome({
    required String accountId,
    required String assetId,
    required double amount,
    required String? categoryId,
    required String description,
    required DateTime timestamp,
  });

  /// Create an expense transaction
  Future<Transaction> createExpense({
    required String accountId,
    required String assetId,
    required double amount,
    required String categoryId,
    required String description,
    required DateTime timestamp,
  });

  /// Create a transfer between accounts
  Future<Transaction> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required String assetId,
    required double amount,
    required String description,
    required DateTime timestamp,
  });

  /// Create a trade (asset swap)
  Future<Transaction> createTrade({
    required String accountId,
    required String fromAssetId,
    required double fromAmount,
    required String toAssetId,
    required double toAmount,
    String? feeAssetId,
    double? feeAmount,
    required String description,
    required DateTime timestamp,
  });

  /// Create an adjustment (balance correction)
  Future<Transaction> createAdjustment({
    required String accountId,
    required String assetId,
    required double amount,
    required String description,
    required DateTime timestamp,
  });

  /// Update an existing transaction
  Future<Transaction> updateTransaction({
    required String transactionId,
    required TransactionType type,
    required Map<String, dynamic> params,
  });

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId);

  /// Get a transaction by ID
  Future<Transaction?> getTransaction(String transactionId);

  /// Get all legs for a transaction
  Future<List<TransactionLeg>> getLegsForTransaction(String transactionId);
}

// =============================================================================
// Portfolio Valuation Service
// =============================================================================

/// Service for computing portfolio values in USD
abstract class PortfolioValuationService {
  /// Get the current portfolio valuation
  Future<PortfolioValuation> getPortfolioValue();

  /// Check if price data is stale (older than threshold)
  Future<bool> isPriceDataStale();

  /// Get the timestamp of the last price update
  Future<DateTime?> getLastPriceUpdate();
}

/// Portfolio valuation result
class PortfolioValuation {
  final double totalValue;
  final double cryptoValue;
  final double fiatValue;
  final double otherValue;
  final DateTime? lastPriceUpdate;
  final bool isPriceDataStale;

  const PortfolioValuation({
    required this.totalValue,
    required this.cryptoValue,
    required this.fiatValue,
    required this.otherValue,
    this.lastPriceUpdate,
    required this.isPriceDataStale,
  });
}

// =============================================================================
// Price Update Service
// =============================================================================

/// Service for fetching and updating asset prices
abstract class PriceUpdateService {
  /// Update prices for all configured assets
  Future<BulkPriceUpdateResult> updateAllPrices();

  /// Update price for a single asset
  Future<PriceUpdateResult> updatePrice(Asset asset);

  /// Test a price source configuration
  Future<double> testPriceSource(PriceSourceConfig config);
}

/// Result of a single price update
class PriceUpdateResult {
  final Asset asset;
  final bool success;
  final double? price;
  final AppError? error;
  final DateTime timestamp;

  const PriceUpdateResult({
    required this.asset,
    required this.success,
    this.price,
    this.error,
    required this.timestamp,
  });
}

/// Result of a bulk price update
class BulkPriceUpdateResult {
  final List<PriceUpdateResult> results;
  final int successCount;
  final int failureCount;
  final DateTime startedAt;
  final DateTime completedAt;

  const BulkPriceUpdateResult({
    required this.results,
    required this.successCount,
    required this.failureCount,
    required this.startedAt,
    required this.completedAt,
  });

  Duration get duration => completedAt.difference(startedAt);
}

// =============================================================================
// Money Summary Service
// =============================================================================

/// Time periods for money summaries
enum MoneyPeriod { thisMonth, lastMonth, allTime }

/// Service for fiat money summaries and reports
abstract class MoneySummaryService {
  /// Get a summary for the specified period
  Future<MoneySummary> getSummary(MoneyPeriod period);
}

/// Money summary result
class MoneySummary {
  final List<TotalAssetBalance> fiatBalances;
  final List<Transaction> recentTransactions;
  final Map<String, double> categoryTotals;
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;
  final MoneyPeriod period;

  const MoneySummary({
    required this.fiatBalances,
    required this.recentTransactions,
    required this.categoryTotals,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    required this.period,
  });

  double get totalBalance {
    return fiatBalances.fold<double>(
      0,
      (sum, balance) => sum + balance.totalBalance,
    );
  }
}

abstract class BalanceValuationService {
  /// Add USD valuations to a list of balances
  Future<List<ValuatedAssetBalance>> valuate(List<TotalAssetBalance> balances);

  /// Get the latest price for an asset
  Future<PriceSnapshot?> getLatestPrice(String assetId);
}
