import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class MoneySummaryServiceImpl implements MoneySummaryService {
  final BalanceService _balanceService;
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;

  MoneySummaryServiceImpl({
    required BalanceService balanceService,
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
  }) : _balanceService = balanceService,
       _transactionRepo = transactionRepo,
       _categoryRepo = categoryRepo;

  @override
  Future<MoneySummary> getSummary(MoneyPeriod period) async {
    // Calculate date range
    final (from, to) = _calculateDateRange(period);

    // Get fiat balances only
    final allBalances = await _balanceService.getAllBalances();
    final fiatBalances = allBalances
        .where((b) => b.asset.type == AssetType.fiat)
        .toList();

    // Get transactions for period
    final txs = await _transactionRepo.getAll(
      limit: 200,
      after: from,
      before: to,
    );

    // Filter to income/expense only
    final incomeExpenseTxs =
        txs
            .where(
              (t) =>
                  t.type == TransactionType.income ||
                  t.type == TransactionType.expense,
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final recentTxs = incomeExpenseTxs.take(20).toList();

    // Build category lookup
    final categories = await _categoryRepo.getAll();
    final categoryMap = {for (final c in categories) c.id: c};

    // Compute totals
    final categoryTotals = <String, double>{};
    double totalIncome = 0.0;
    double totalExpenses = 0.0;

    for (final tx in incomeExpenseTxs) {
      final legs = await _transactionRepo.getLegsForTransaction(tx.id);

      for (final leg in legs) {
        // Category aggregation
        if (leg.categoryId != null) {
          final cat = categoryMap[leg.categoryId];
          if (cat != null) {
            final key = cat.name;
            final amountAbs = leg.amount.abs();
            categoryTotals[key] = (categoryTotals[key] ?? 0.0) + amountAbs;
          }
        }

        // Income/expense totals (main leg only)
        if (leg.role == LegRole.main) {
          if (tx.type == TransactionType.income) {
            totalIncome += leg.amount;
          } else if (tx.type == TransactionType.expense) {
            totalExpenses += leg.amount.abs();
          }
        }
      }
    }

    return MoneySummary(
      fiatBalances: fiatBalances,
      recentTransactions: recentTxs,
      categoryTotals: categoryTotals,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netIncome: totalIncome - totalExpenses,
      period: period,
    );
  }

  (DateTime?, DateTime?) _calculateDateRange(MoneyPeriod period) {
    final now = DateTime.now();

    switch (period) {
      case MoneyPeriod.thisMonth:
        final from = DateTime(now.year, now.month, 1);
        final to = DateTime(now.year, now.month + 1, 1);
        return (from, to);

      case MoneyPeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final from = lastMonth;
        final to = DateTime(lastMonth.year, lastMonth.month + 1, 1);
        return (from, to);

      case MoneyPeriod.allTime:
        return (null, null);
    }
  }
}
