import '../../../core/errors/app_error.dart';

/// Domain-specific error categories for ledger operations
enum DomainErrorCategory {
  /// Amount validation errors
  invalidAmount,

  /// Insufficient funds for operation
  insufficientFunds,

  /// Transfer to same account
  sameAccountTransfer,

  /// Trade same asset
  sameAssetTrade,

  /// Missing required category
  missingCategory,

  /// Invalid fee configuration
  invalidFee,

  /// Asset not found
  assetNotFound,

  /// Account not found
  accountNotFound,

  /// Transaction not found
  transactionNotFound,
}

/// Extension to map domain errors to UI error categories
extension DomainErrorMapping on DomainErrorCategory {
  ErrorCategory toErrorCategory() {
    switch (this) {
      case DomainErrorCategory.invalidAmount:
      case DomainErrorCategory.sameAccountTransfer:
      case DomainErrorCategory.sameAssetTrade:
      case DomainErrorCategory.missingCategory:
      case DomainErrorCategory.invalidFee:
      case DomainErrorCategory.insufficientFunds:
        return ErrorCategory.badRequest;

      case DomainErrorCategory.assetNotFound:
      case DomainErrorCategory.accountNotFound:
      case DomainErrorCategory.transactionNotFound:
        return ErrorCategory.notFound;
    }
  }

  String get userMessageKey {
    switch (this) {
      case DomainErrorCategory.invalidAmount:
        return 'ledger.error.invalid_amount';
      case DomainErrorCategory.insufficientFunds:
        return 'ledger.error.insufficient_funds';
      case DomainErrorCategory.sameAccountTransfer:
        return 'ledger.error.same_account_transfer';
      case DomainErrorCategory.sameAssetTrade:
        return 'ledger.error.same_asset_trade';
      case DomainErrorCategory.missingCategory:
        return 'ledger.error.missing_category';
      case DomainErrorCategory.invalidFee:
        return 'ledger.error.invalid_fee';
      case DomainErrorCategory.assetNotFound:
        return 'ledger.error.asset_not_found';
      case DomainErrorCategory.accountNotFound:
        return 'ledger.error.account_not_found';
      case DomainErrorCategory.transactionNotFound:
        return 'ledger.error.transaction_not_found';
    }
  }
}

/// Helper to create domain errors
class DomainError {
  /// Create an AppError from a domain error category
  static AppError create(
    DomainErrorCategory category,
    String message, {
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      category: category.toErrorCategory(),
      message: message,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
}
