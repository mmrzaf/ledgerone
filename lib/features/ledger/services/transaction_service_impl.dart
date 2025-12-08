import 'dart:math' as math;

import '../../../core/contracts/analytics_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/observability/performance_tracker.dart';
import '../data/database.dart';
import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

enum DomainErrorCategory {
  invalidAmount,
  sameAccountTransfer,
  sameAssetTrade,
  missingCategory,
  invalidFee,
}

extension on DomainErrorCategory {
  ErrorCategory get toErrorCategory {
    switch (this) {
      case DomainErrorCategory.invalidAmount:
        return ErrorCategory.badRequest;
      case DomainErrorCategory.sameAccountTransfer:
      case DomainErrorCategory.sameAssetTrade:
      case DomainErrorCategory.missingCategory:
      case DomainErrorCategory.invalidFee:
        return ErrorCategory.badRequest;
    }
  }
}

class TransactionServiceImpl implements TransactionService {
  final LedgerDatabase db;
  final TransactionRepository transactionRepo;
  final AssetRepository assetRepo;
  final AccountRepository accountRepo;
  final AnalyticsService analytics;
  final PerformanceTracker performance;

  TransactionServiceImpl({
    required this.db,
    required this.transactionRepo,
    required this.assetRepo,
    required this.accountRepo,
    required this.analytics,
    required this.performance,
  });

  double _roundAmount(double value, int decimals) {
    final multiplier = math.pow(10, decimals).toDouble();
    return (value * multiplier).round() / multiplier;
  }

  void _validateAmount(double amount) {
    if (amount.isNaN || amount.isInfinite || amount == 0.0) {
      throw AppError(
        category: DomainErrorCategory.invalidAmount.toErrorCategory,
        message: 'Amount must be a valid non-zero number',
      );
    }
  }

  @override
  Future<Transaction> createIncome({
    required String accountId,
    required String assetId,
    required double amount,
    required String? categoryId,
    required String description,
    required DateTime timestamp,
  }) async {
    performance.start('transaction_create_income');

    try {
      _validateAmount(amount);

      final asset = await assetRepo.getById(assetId);
      if (asset == null) {
        throw const AppError(
          category: ErrorCategory.notFound,
          message: 'Asset not found',
        );
      }

      final account = await accountRepo.getById(accountId);
      if (account == null) {
        throw const AppError(
          category: ErrorCategory.notFound,
          message: 'Account not found',
        );
      }

      final roundedAmount = _roundAmount(amount, asset.decimals);

      final transaction = Transaction(
        id: db.generateId(),
        timestamp: timestamp,
        type: TransactionType.income,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final legs = [
        TransactionLeg(
          id: db.generateId(),
          transactionId: transaction.id,
          accountId: accountId,
          assetId: assetId,
          amount: roundedAmount,
          role: LegRole.main,
          categoryId: categoryId,
        ),
      ];

      await transactionRepo.insert(transaction, legs);

      await analytics.logEvent(
        'transaction_created',
        parameters: {
          'type': 'income',
          'asset_id': assetId,
          'amount': roundedAmount,
        },
      );

      final metric = performance.stop('transaction_create_income');
      if (metric != null) {
        await analytics.logEvent(
          'transaction_saved',
          parameters: {'type': 'income', 'duration_ms': metric.durationMs},
        );
      }

      return transaction;
    } catch (e) {
      performance.stop('transaction_create_income');
      await analytics.logEvent(
        'transaction_failed',
        parameters: {'type': 'income', 'error': e.toString()},
      );
      rethrow;
    }
  }

  @override
  Future<Transaction> createExpense({
    required String accountId,
    required String assetId,
    required double amount,
    required String categoryId,
    required String description,
    required DateTime timestamp,
  }) async {
    performance.start('transaction_create_expense');

    try {
      _validateAmount(amount);

      final asset = await assetRepo.getById(assetId);
      if (asset == null) {
        throw const AppError(
          category: ErrorCategory.notFound,
          message: 'Asset not found',
        );
      }

      final roundedAmount = _roundAmount(amount, asset.decimals);

      final transaction = Transaction(
        id: db.generateId(),
        timestamp: timestamp,
        type: TransactionType.expense,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final legs = [
        TransactionLeg(
          id: db.generateId(),
          transactionId: transaction.id,
          accountId: accountId,
          assetId: assetId,
          amount: -roundedAmount,
          role: LegRole.main,
          categoryId: categoryId,
        ),
      ];

      await transactionRepo.insert(transaction, legs);

      await analytics.logEvent(
        'transaction_created',
        parameters: {
          'type': 'expense',
          'asset_id': assetId,
          'amount': roundedAmount,
        },
      );

      final metric = performance.stop('transaction_create_expense');
      if (metric != null) {
        await analytics.logEvent(
          'transaction_saved',
          parameters: {'type': 'expense', 'duration_ms': metric.durationMs},
        );
      }

      return transaction;
    } catch (e) {
      performance.stop('transaction_create_expense');
      await analytics.logEvent(
        'transaction_failed',
        parameters: {'type': 'expense', 'error': e.toString()},
      );
      rethrow;
    }
  }

  @override
  Future<Transaction> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required String assetId,
    required double amount,
    required String description,
    required DateTime timestamp,
  }) async {
    performance.start('transaction_create_transfer');

    try {
      _validateAmount(amount);

      if (fromAccountId == toAccountId) {
        throw AppError(
          category: DomainErrorCategory.sameAccountTransfer.toErrorCategory,
          message: 'Cannot transfer to the same account',
        );
      }

      final asset = await assetRepo.getById(assetId);
      if (asset == null) {
        throw const AppError(
          category: ErrorCategory.notFound,
          message: 'Asset not found',
        );
      }

      final roundedAmount = _roundAmount(amount, asset.decimals);

      final transaction = Transaction(
        id: db.generateId(),
        timestamp: timestamp,
        type: TransactionType.transfer,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final legs = [
        TransactionLeg(
          id: db.generateId(),
          transactionId: transaction.id,
          accountId: fromAccountId,
          assetId: assetId,
          amount: -roundedAmount,
          role: LegRole.main,
        ),
        TransactionLeg(
          id: db.generateId(),
          transactionId: transaction.id,
          accountId: toAccountId,
          assetId: assetId,
          amount: roundedAmount,
          role: LegRole.main,
        ),
      ];

      await transactionRepo.insert(transaction, legs);

      await analytics.logEvent(
        'transaction_created',
        parameters: {
          'type': 'transfer',
          'asset_id': assetId,
          'amount': roundedAmount,
        },
      );

      performance.stop('transaction_create_transfer');
      return transaction;
    } catch (e) {
      performance.stop('transaction_create_transfer');
      await analytics.logEvent(
        'transaction_failed',
        parameters: {'type': 'transfer', 'error': e.toString()},
      );
      rethrow;
    }
  }

  @override
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
  }) async {
    performance.start('transaction_create_trade');

    try {
      _validateAmount(fromAmount);
      _validateAmount(toAmount);

      if (fromAssetId == toAssetId) {
        throw AppError(
          category: DomainErrorCategory.sameAssetTrade.toErrorCategory,
          message: 'Cannot trade the same asset',
        );
      }

      if (feeAmount != null) {
        _validateAmount(feeAmount);
      }

      final fromAsset = await assetRepo.getById(fromAssetId);
      final toAsset = await assetRepo.getById(toAssetId);
      if (fromAsset == null || toAsset == null) {
        throw const AppError(
          category: ErrorCategory.notFound,
          message: 'Asset not found',
        );
      }

      final roundedFromAmount = _roundAmount(fromAmount, fromAsset.decimals);
      final roundedToAmount = _roundAmount(toAmount, toAsset.decimals);

      final transaction = Transaction(
        id: db.generateId(),
        timestamp: timestamp,
        type: TransactionType.trade,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final legs = <TransactionLeg>[
        TransactionLeg(
          id: db.generateId(),
          transactionId: transaction.id,
          accountId: accountId,
          assetId: fromAssetId,
          amount: -roundedFromAmount,
          role: LegRole.main,
        ),
        TransactionLeg(
          id: db.generateId(),
          transactionId: transaction.id,
          accountId: accountId,
          assetId: toAssetId,
          amount: roundedToAmount,
          role: LegRole.main,
        ),
      ];

      if (feeAssetId != null && feeAmount != null) {
        final feeAsset = await assetRepo.getById(feeAssetId);
        if (feeAsset != null) {
          final roundedFeeAmount = _roundAmount(feeAmount, feeAsset.decimals);
          legs.add(
            TransactionLeg(
              id: db.generateId(),
              transactionId: transaction.id,
              accountId: accountId,
              assetId: feeAssetId,
              amount: -roundedFeeAmount,
              role: LegRole.fee,
            ),
          );
        }
      }

      await transactionRepo.insert(transaction, legs);

      await analytics.logEvent(
        'transaction_created',
        parameters: {
          'type': 'trade',
          'from_asset': fromAssetId,
          'to_asset': toAssetId,
        },
      );

      performance.stop('transaction_create_trade');
      return transaction;
    } catch (e) {
      performance.stop('transaction_create_trade');
      await analytics.logEvent(
        'transaction_failed',
        parameters: {'type': 'trade', 'error': e.toString()},
      );
      rethrow;
    }
  }

  @override
  Future<Transaction> createAdjustment({
    required String accountId,
    required String assetId,
    required double amount,
    required String description,
    required DateTime timestamp,
  }) async {
    final asset = await assetRepo.getById(assetId);
    if (asset == null) {
      throw const AppError(
        category: ErrorCategory.notFound,
        message: 'Asset not found',
      );
    }

    final roundedAmount = _roundAmount(amount, asset.decimals);

    final transaction = Transaction(
      id: db.generateId(),
      timestamp: timestamp,
      type: TransactionType.adjustment,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final legs = [
      TransactionLeg(
        id: db.generateId(),
        transactionId: transaction.id,
        accountId: accountId,
        assetId: assetId,
        amount: roundedAmount,
        role: LegRole.main,
      ),
    ];

    await transactionRepo.insert(transaction, legs);
    return transaction;
  }

  @override
  Future<Transaction> updateTransaction({
    required String transactionId,
    required TransactionType type,
    required Map<String, dynamic> params,
  }) async {
    throw UnimplementedError('Update not yet implemented');
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await transactionRepo.delete(transactionId);
    await analytics.logEvent(
      'transaction_deleted',
      parameters: {'transaction_id': transactionId},
    );
  }

  @override
  Future<Transaction?> getTransaction(String transactionId) async {
    return await transactionRepo.getById(transactionId);
  }

  @override
  Future<List<TransactionLeg>> getLegsForTransaction(
    String transactionId,
  ) async {
    return await transactionRepo.getLegsForTransaction(transactionId);
  }
}
