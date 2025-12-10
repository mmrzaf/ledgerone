import 'dart:math' as math;

import '../../../core/contracts/analytics_contract.dart';
import '../../../core/observability/performance_tracker.dart';
import '../data/database.dart';
import '../data/repositories_interfaces.dart';
import '../domain/errors.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class TransactionServiceImpl implements TransactionService {
  final LedgerDatabase _db;
  final TransactionRepository _transactionRepo;
  final AssetRepository _assetRepo;
  final AccountRepository _accountRepo;
  final AnalyticsService _analytics;
  final PerformanceTracker _performance;

  TransactionServiceImpl({
    required LedgerDatabase db,
    required TransactionRepository transactionRepo,
    required AssetRepository assetRepo,
    required AccountRepository accountRepo,
    required AnalyticsService analytics,
    required PerformanceTracker performance,
  }) : _db = db,
       _transactionRepo = transactionRepo,
       _assetRepo = assetRepo,
       _accountRepo = accountRepo,
       _analytics = analytics,
       _performance = performance;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  double _roundAmount(double value, int decimals) {
    final multiplier = math.pow(10, decimals).toDouble();
    return (value * multiplier).round() / multiplier;
  }

  void _validateAmount(double amount) {
    if (amount.isNaN || amount.isInfinite || amount == 0.0) {
      throw DomainError.create(
        DomainErrorCategory.invalidAmount,
        'Amount must be a valid non-zero number',
      );
    }
  }

  Future<Asset> _getAssetOrThrow(String assetId) async {
    final asset = await _assetRepo.getById(assetId);
    if (asset == null) {
      throw DomainError.create(
        DomainErrorCategory.assetNotFound,
        'Asset not found: $assetId',
      );
    }
    return asset;
  }

  Future<Account> _getAccountOrThrow(String accountId) async {
    final account = await _accountRepo.getById(accountId);
    if (account == null) {
      throw DomainError.create(
        DomainErrorCategory.accountNotFound,
        'Account not found: $accountId',
      );
    }
    return account;
  }

  // ---------------------------------------------------------------------------
  // Create Operations
  // ---------------------------------------------------------------------------

  @override
  Future<Transaction> createIncome({
    required String accountId,
    required String assetId,
    required double amount,
    required String? categoryId,
    required String description,
    required DateTime timestamp,
  }) async {
    _performance.start('transaction_create_income');

    try {
      _validateAmount(amount);

      final asset = await _getAssetOrThrow(assetId);
      await _getAccountOrThrow(accountId);

      final roundedAmount = _roundAmount(amount, asset.decimals);
      final now = DateTime.now();

      final transaction = Transaction(
        id: _db.generateId(),
        timestamp: timestamp,
        type: TransactionType.income,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      final legs = [
        TransactionLeg(
          id: _db.generateId(),
          transactionId: transaction.id,
          accountId: accountId,
          assetId: assetId,
          amount: roundedAmount,
          role: LegRole.main,
          categoryId: categoryId,
        ),
      ];

      await _transactionRepo.insert(transaction, legs);

      await _analytics.logEvent(
        'transaction_created',
        parameters: {
          'type': 'income',
          'asset_id': assetId,
          'amount': roundedAmount,
        },
      );

      _performance.stop('transaction_create_income');
      return transaction;
    } catch (e) {
      _performance.stop('transaction_create_income');
      await _analytics.logEvent(
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
    _performance.start('transaction_create_expense');

    try {
      _validateAmount(amount);

      final asset = await _getAssetOrThrow(assetId);
      await _getAccountOrThrow(accountId);

      final roundedAmount = _roundAmount(amount, asset.decimals);
      final now = DateTime.now();

      final transaction = Transaction(
        id: _db.generateId(),
        timestamp: timestamp,
        type: TransactionType.expense,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      final legs = [
        TransactionLeg(
          id: _db.generateId(),
          transactionId: transaction.id,
          accountId: accountId,
          assetId: assetId,
          amount: -roundedAmount, // Negative for expense
          role: LegRole.main,
          categoryId: categoryId,
        ),
      ];

      await _transactionRepo.insert(transaction, legs);

      await _analytics.logEvent(
        'transaction_created',
        parameters: {
          'type': 'expense',
          'asset_id': assetId,
          'amount': roundedAmount,
        },
      );

      _performance.stop('transaction_create_expense');
      return transaction;
    } catch (e) {
      _performance.stop('transaction_create_expense');
      await _analytics.logEvent(
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
    _performance.start('transaction_create_transfer');

    try {
      _validateAmount(amount);

      if (fromAccountId == toAccountId) {
        throw DomainError.create(
          DomainErrorCategory.sameAccountTransfer,
          'Cannot transfer to the same account',
        );
      }

      final asset = await _getAssetOrThrow(assetId);
      await _getAccountOrThrow(fromAccountId);
      await _getAccountOrThrow(toAccountId);

      final roundedAmount = _roundAmount(amount, asset.decimals);
      final now = DateTime.now();

      final transaction = Transaction(
        id: _db.generateId(),
        timestamp: timestamp,
        type: TransactionType.transfer,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      final legs = [
        TransactionLeg(
          id: _db.generateId(),
          transactionId: transaction.id,
          accountId: fromAccountId,
          assetId: assetId,
          amount: -roundedAmount, // Negative for source
          role: LegRole.main,
        ),
        TransactionLeg(
          id: _db.generateId(),
          transactionId: transaction.id,
          accountId: toAccountId,
          assetId: assetId,
          amount: roundedAmount, // Positive for destination
          role: LegRole.main,
        ),
      ];

      await _transactionRepo.insert(transaction, legs);

      await _analytics.logEvent(
        'transaction_created',
        parameters: {
          'type': 'transfer',
          'asset_id': assetId,
          'amount': roundedAmount,
        },
      );

      _performance.stop('transaction_create_transfer');
      return transaction;
    } catch (e) {
      _performance.stop('transaction_create_transfer');
      await _analytics.logEvent(
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
    _performance.start('transaction_create_trade');

    try {
      _validateAmount(fromAmount);
      _validateAmount(toAmount);

      if (fromAssetId == toAssetId) {
        throw DomainError.create(
          DomainErrorCategory.sameAssetTrade,
          'Cannot trade the same asset',
        );
      }

      if (feeAmount != null && feeAmount != 0.0) {
        _validateAmount(feeAmount);
      }

      final fromAsset = await _getAssetOrThrow(fromAssetId);
      final toAsset = await _getAssetOrThrow(toAssetId);
      await _getAccountOrThrow(accountId);

      final roundedFromAmount = _roundAmount(fromAmount, fromAsset.decimals);
      final roundedToAmount = _roundAmount(toAmount, toAsset.decimals);
      final now = DateTime.now();

      final transaction = Transaction(
        id: _db.generateId(),
        timestamp: timestamp,
        type: TransactionType.trade,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      final legs = <TransactionLeg>[
        TransactionLeg(
          id: _db.generateId(),
          transactionId: transaction.id,
          accountId: accountId,
          assetId: fromAssetId,
          amount: -roundedFromAmount, // Negative for what you give
          role: LegRole.main,
        ),
        TransactionLeg(
          id: _db.generateId(),
          transactionId: transaction.id,
          accountId: accountId,
          assetId: toAssetId,
          amount: roundedToAmount, // Positive for what you receive
          role: LegRole.main,
        ),
      ];

      // Add fee leg if present
      if (feeAssetId != null && feeAmount != null && feeAmount != 0.0) {
        final feeAsset = await _getAssetOrThrow(feeAssetId);
        final roundedFeeAmount = _roundAmount(feeAmount, feeAsset.decimals);
        legs.add(
          TransactionLeg(
            id: _db.generateId(),
            transactionId: transaction.id,
            accountId: accountId,
            assetId: feeAssetId,
            amount: -roundedFeeAmount, // Negative for fee
            role: LegRole.fee,
          ),
        );
      }

      await _transactionRepo.insert(transaction, legs);

      await _analytics.logEvent(
        'transaction_created',
        parameters: {
          'type': 'trade',
          'from_asset': fromAssetId,
          'to_asset': toAssetId,
        },
      );

      _performance.stop('transaction_create_trade');
      return transaction;
    } catch (e) {
      _performance.stop('transaction_create_trade');
      await _analytics.logEvent(
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
    _performance.start('transaction_create_adjustment');

    try {
      // Amount can be positive or negative for adjustments
      if (amount.isNaN || amount.isInfinite || amount == 0.0) {
        throw DomainError.create(
          DomainErrorCategory.invalidAmount,
          'Amount must be a valid non-zero number',
        );
      }

      final asset = await _getAssetOrThrow(assetId);
      await _getAccountOrThrow(accountId);

      final roundedAmount = _roundAmount(amount, asset.decimals);
      final now = DateTime.now();

      final transaction = Transaction(
        id: _db.generateId(),
        timestamp: timestamp,
        type: TransactionType.adjustment,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      final legs = [
        TransactionLeg(
          id: _db.generateId(),
          transactionId: transaction.id,
          accountId: accountId,
          assetId: assetId,
          amount: roundedAmount, // Can be positive or negative
          role: LegRole.main,
        ),
      ];

      await _transactionRepo.insert(transaction, legs);

      await _analytics.logEvent(
        'transaction_created',
        parameters: {
          'type': 'adjustment',
          'asset_id': assetId,
          'amount': roundedAmount,
        },
      );

      _performance.stop('transaction_create_adjustment');
      return transaction;
    } catch (e) {
      _performance.stop('transaction_create_adjustment');
      await _analytics.logEvent(
        'transaction_failed',
        parameters: {'type': 'adjustment', 'error': e.toString()},
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Update Operation
  // ---------------------------------------------------------------------------

  @override
  Future<Transaction> updateTransaction({
    required String transactionId,
    required TransactionType type,
    required Map<String, dynamic> params,
  }) async {
    _performance.start('transaction_update');

    try {
      final existingTx = await _transactionRepo.getById(transactionId);
      if (existingTx == null) {
        throw DomainError.create(
          DomainErrorCategory.transactionNotFound,
          'Transaction not found: $transactionId',
        );
      }

      final description = params['description'] as String;
      final timestamp = params['timestamp'] as DateTime;
      final now = DateTime.now();

      final updatedTx = existingTx.copyWith(
        timestamp: timestamp,
        type: type,
        description: description,
        updatedAt: now,
      );

      final newLegs = await _buildLegsForType(transactionId, type, params);
      _validateLegs(type, newLegs, params);

      await _transactionRepo.update(updatedTx, newLegs);

      await _analytics.logEvent(
        'transaction_updated',
        parameters: {'type': type.name, 'transaction_id': transactionId},
      );

      _performance.stop('transaction_update');
      return updatedTx;
    } catch (e) {
      _performance.stop('transaction_update');
      await _analytics.logEvent(
        'transaction_failed',
        parameters: {'type': type.name, 'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<List<TransactionLeg>> _buildLegsForType(
    String transactionId,
    TransactionType type,
    Map<String, dynamic> params,
  ) async {
    switch (type) {
      case TransactionType.income:
        return _buildIncomeLegs(transactionId, params);
      case TransactionType.expense:
        return _buildExpenseLegs(transactionId, params);
      case TransactionType.transfer:
        return _buildTransferLegs(transactionId, params);
      case TransactionType.trade:
        return _buildTradeLegs(transactionId, params);
      case TransactionType.adjustment:
        return _buildAdjustmentLegs(transactionId, params);
    }
  }

  Future<List<TransactionLeg>> _buildIncomeLegs(
    String transactionId,
    Map<String, dynamic> params,
  ) async {
    final accountId = params['accountId'] as String;
    final assetId = params['assetId'] as String;
    final amount = params['amount'] as double;
    final categoryId = params['categoryId'] as String?;

    _validateAmount(amount);
    final asset = await _getAssetOrThrow(assetId);
    final roundedAmount = _roundAmount(amount, asset.decimals);

    return [
      TransactionLeg(
        id: _db.generateId(),
        transactionId: transactionId,
        accountId: accountId,
        assetId: assetId,
        amount: roundedAmount,
        role: LegRole.main,
        categoryId: categoryId,
      ),
    ];
  }

  Future<List<TransactionLeg>> _buildExpenseLegs(
    String transactionId,
    Map<String, dynamic> params,
  ) async {
    final accountId = params['accountId'] as String;
    final assetId = params['assetId'] as String;
    final amount = params['amount'] as double;
    final categoryId = params['categoryId'] as String?;

    if (categoryId == null) {
      throw DomainError.create(
        DomainErrorCategory.missingCategory,
        'Category is required for expense transactions',
      );
    }

    _validateAmount(amount);
    final asset = await _getAssetOrThrow(assetId);
    final roundedAmount = _roundAmount(amount, asset.decimals);

    return [
      TransactionLeg(
        id: _db.generateId(),
        transactionId: transactionId,
        accountId: accountId,
        assetId: assetId,
        amount: -roundedAmount,
        role: LegRole.main,
        categoryId: categoryId,
      ),
    ];
  }

  Future<List<TransactionLeg>> _buildTransferLegs(
    String transactionId,
    Map<String, dynamic> params,
  ) async {
    final fromAccountId = params['fromAccountId'] as String;
    final toAccountId = params['toAccountId'] as String;
    final assetId = params['assetId'] as String;
    final amount = params['amount'] as double;

    if (fromAccountId == toAccountId) {
      throw DomainError.create(
        DomainErrorCategory.sameAccountTransfer,
        'Cannot transfer to the same account',
      );
    }

    _validateAmount(amount);
    final asset = await _getAssetOrThrow(assetId);
    final roundedAmount = _roundAmount(amount, asset.decimals);

    return [
      TransactionLeg(
        id: _db.generateId(),
        transactionId: transactionId,
        accountId: fromAccountId,
        assetId: assetId,
        amount: -roundedAmount,
        role: LegRole.main,
      ),
      TransactionLeg(
        id: _db.generateId(),
        transactionId: transactionId,
        accountId: toAccountId,
        assetId: assetId,
        amount: roundedAmount,
        role: LegRole.main,
      ),
    ];
  }

  Future<List<TransactionLeg>> _buildTradeLegs(
    String transactionId,
    Map<String, dynamic> params,
  ) async {
    final accountId = params['accountId'] as String;
    final fromAssetId = params['fromAssetId'] as String;
    final fromAmount = params['fromAmount'] as double;
    final toAssetId = params['toAssetId'] as String;
    final toAmount = params['toAmount'] as double;
    final feeAssetId = params['feeAssetId'] as String?;
    final feeAmount = params['feeAmount'] as double?;

    if (fromAssetId == toAssetId) {
      throw DomainError.create(
        DomainErrorCategory.sameAssetTrade,
        'Cannot trade the same asset',
      );
    }

    _validateAmount(fromAmount);
    _validateAmount(toAmount);

    final fromAsset = await _getAssetOrThrow(fromAssetId);
    final toAsset = await _getAssetOrThrow(toAssetId);

    final legs = <TransactionLeg>[
      TransactionLeg(
        id: _db.generateId(),
        transactionId: transactionId,
        accountId: accountId,
        assetId: fromAssetId,
        amount: -_roundAmount(fromAmount, fromAsset.decimals),
        role: LegRole.main,
      ),
      TransactionLeg(
        id: _db.generateId(),
        transactionId: transactionId,
        accountId: accountId,
        assetId: toAssetId,
        amount: _roundAmount(toAmount, toAsset.decimals),
        role: LegRole.main,
      ),
    ];

    if (feeAssetId != null && feeAmount != null && feeAmount != 0.0) {
      _validateAmount(feeAmount);
      final feeAsset = await _getAssetOrThrow(feeAssetId);
      legs.add(
        TransactionLeg(
          id: _db.generateId(),
          transactionId: transactionId,
          accountId: accountId,
          assetId: feeAssetId,
          amount: -_roundAmount(feeAmount, feeAsset.decimals),
          role: LegRole.fee,
        ),
      );
    }

    return legs;
  }

  Future<List<TransactionLeg>> _buildAdjustmentLegs(
    String transactionId,
    Map<String, dynamic> params,
  ) async {
    final accountId = params['accountId'] as String;
    final assetId = params['assetId'] as String;
    final amount = params['amount'] as double;

    final asset = await _getAssetOrThrow(assetId);
    final roundedAmount = _roundAmount(amount, asset.decimals);

    return [
      TransactionLeg(
        id: _db.generateId(),
        transactionId: transactionId,
        accountId: accountId,
        assetId: assetId,
        amount: roundedAmount,
        role: LegRole.main,
      ),
    ];
  }

  void _validateLegs(
    TransactionType type,
    List<TransactionLeg> legs,
    Map<String, dynamic> params,
  ) {
    if (legs.isEmpty) {
      throw DomainError.create(
        DomainErrorCategory.invalidAmount,
        'Transaction must have at least one leg',
      );
    }

    switch (type) {
      case TransactionType.expense:
        if (params['categoryId'] == null) {
          throw DomainError.create(
            DomainErrorCategory.missingCategory,
            'Category is required for expenses',
          );
        }
        break;
      case TransactionType.transfer:
        if (legs.length != 2) {
          throw DomainError.create(
            DomainErrorCategory.invalidAmount,
            'Transfer must have exactly 2 legs',
          );
        }
        break;
      case TransactionType.trade:
        if (legs.length < 2) {
          throw DomainError.create(
            DomainErrorCategory.invalidAmount,
            'Trade must have at least 2 legs',
          );
        }
        break;
      default:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Delete & Read Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionRepo.delete(transactionId);
    await _analytics.logEvent(
      'transaction_deleted',
      parameters: {'transaction_id': transactionId},
    );
  }

  @override
  Future<Transaction?> getTransaction(String transactionId) async {
    return await _transactionRepo.getById(transactionId);
  }

  @override
  Future<List<TransactionLeg>> getLegsForTransaction(
    String transactionId,
  ) async {
    return await _transactionRepo.getLegsForTransaction(transactionId);
  }
}
