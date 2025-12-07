import '../../../core/errors/app_error.dart';
import 'models.dart';

// Add domain-specific error categories
extension LedgerErrorCategories on ErrorCategory {
  static const ErrorCategory domainValidation = ErrorCategory.badRequest;
  static const ErrorCategory insufficientFunds = ErrorCategory.badRequest;
  static const ErrorCategory invalidTransactionStructure =
      ErrorCategory.badRequest;
}

abstract class BalanceService {
  Future<double> getBalance(String assetId, String accountId);
  Future<double> getTotalBalance(String assetId);
  Future<List<AssetBalance>> getAccountBalances(String accountId);
  Future<List<TotalAssetBalance>> getAllBalances({bool includeZero = false});
}

abstract class TransactionService {
  Future<Transaction> createIncome({
    required String accountId,
    required String assetId,
    required double amount,
    required String? categoryId,
    required String description,
    required DateTime timestamp,
  });

  Future<Transaction> createExpense({
    required String accountId,
    required String assetId,
    required double amount,
    required String categoryId,
    required String description,
    required DateTime timestamp,
  });

  Future<Transaction> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required String assetId,
    required double amount,
    required String description,
    required DateTime timestamp,
  });

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

  Future<Transaction> createAdjustment({
    required String accountId,
    required String assetId,
    required double amount,
    required String description,
    required DateTime timestamp,
  });

  Future<Transaction> updateTransaction({
    required String transactionId,
    required TransactionType type,
    required Map<String, dynamic> params,
  });

  Future<void> deleteTransaction(String transactionId);

  Future<Transaction?> getTransaction(String transactionId);
  Future<List<TransactionLeg>> getLegsForTransaction(String transactionId);
}

abstract class PortfolioValuationService {
  Future<PortfolioValuation> getPortfolioValue();
  Future<bool> isPriceDataStale();
  Future<DateTime?> getLastPriceUpdate();
}

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

abstract class PriceUpdateService {
  Future<BulkPriceUpdateResult> updateAllPrices();
  Future<PriceUpdateResult> updatePrice(Asset asset);
  Future<double> testPriceSource(PriceSourceConfig config);
}

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
