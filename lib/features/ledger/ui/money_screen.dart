import 'package:flutter/material.dart';

import '../../../app/presentation/error_presenter.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/i18n/string_keys.dart';
import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

enum MoneyPeriod { thisMonth, lastMonth, allTime }

class MoneyScreen extends StatefulWidget {
  final NavigationService navigation;
  final BalanceService balanceService;
  final TransactionRepository transactionRepo;
  final CategoryRepository categoryRepo;
  final AnalyticsService analytics;

  const MoneyScreen({
    required this.navigation,
    required this.balanceService,
    required this.transactionRepo,
    required this.categoryRepo,
    required this.analytics,
    super.key,
  });

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  MoneyPeriod _period = MoneyPeriod.thisMonth;

  List<TotalAssetBalance>? _fiatBalances;
  List<Transaction>? _recentTransactions;
  Map<String, double>? _categoryTotals;

  double _totalIncome = 0;
  double _totalExpenses = 0;

  bool _loading = true;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    widget.analytics.logScreenView('money');
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();

      DateTime? from;
      DateTime? to;

      switch (_period) {
        case MoneyPeriod.thisMonth:
          from = DateTime(now.year, now.month, 1);
          to = DateTime(now.year, now.month + 1, 1);
          break;
        case MoneyPeriod.lastMonth:
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          from = lastMonth;
          to = DateTime(lastMonth.year, lastMonth.month + 1, 1);
          break;
        case MoneyPeriod.allTime:
          from = null;
          to = null;
          break;
      }

      // 1) Balances – reuse BalanceService properly
      final allBalances = await widget.balanceService.getAllBalances();
      final fiatBalances = allBalances
          .where((b) => b.asset.type == AssetType.fiat)
          .toList();

      // 2) Transactions for selected period (income/expense only)
      final txs = await widget.transactionRepo.getAll(
        limit: 200,
        after: from,
        before: to,
      );

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

      // 3) Categories
      final categories = await widget.categoryRepo.getAll();
      final categoryMap = {for (final c in categories) c.id: c};

      final categoryTotals = <String, double>{};
      double totalIncome = 0.0;
      double totalExpenses = 0.0;

      // Walk all income/expense txs once, compute both sums + category totals
      for (final tx in incomeExpenseTxs) {
        final legs = await widget.transactionRepo.getLegsForTransaction(tx.id);

        for (final leg in legs) {
          // Category-based aggregation (use abs so totals are positive)
          if (leg.categoryId != null) {
            final cat = categoryMap[leg.categoryId];
            if (cat != null) {
              final key = cat.name;
              final amountAbs = leg.amount.abs();
              categoryTotals[key] = (categoryTotals[key] ?? 0.0) + amountAbs;
            }
          }

          // Income / expense totals (main leg only)
          if (leg.role == LegRole.main) {
            if (tx.type == TransactionType.income) {
              totalIncome += leg.amount;
            } else if (tx.type == TransactionType.expense) {
              // expenses are usually negative in legs; normalise to positive
              totalExpenses += leg.amount < 0 ? -leg.amount : leg.amount;
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _fiatBalances = fiatBalances;
        _recentTransactions = recentTxs;
        _categoryTotals = categoryTotals;
        _totalIncome = totalIncome;
        _totalExpenses = totalExpenses;
        _loading = false;
      });
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppError(
          category: ErrorCategory.unknown,
          message: e.toString(),
          originalError: e,
        );
      });
    }
  }

  void _onPeriodChanged(MoneyPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    widget.analytics.logEvent(
      'money_period_changed',
      parameters: {'period': period.name},
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get(L10nKeys.ledgerMoneyTitle))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorCard(error: _error!, screen: 'moeny')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodChips(theme, l10n),
                    const SizedBox(height: 16),
                    _buildSummaryCard(theme, l10n),
                    const SizedBox(height: 24),
                    _buildAccountsSection(theme, l10n),
                    const SizedBox(height: 24),
                    _buildTransactionsSection(theme, l10n),
                    const SizedBox(height: 24),
                    _buildCategoriesSection(theme, l10n),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNav(l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.navigation.goToRoute('transaction_editor'),
        tooltip: l10n.get(L10nKeys.ledgerActionAddTransaction),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPeriodChips(ThemeData theme, LocalizationService l10n) {
    String label(MoneyPeriod p) {
      switch (p) {
        case MoneyPeriod.thisMonth:
          return l10n.get(L10nKeys.ledgerMoneyThisMonth);
        case MoneyPeriod.lastMonth:
          return 'Last month'; // TODO: add i18n key
        case MoneyPeriod.allTime:
          return 'All time'; // TODO: add i18n key
      }
    }

    return Row(
      children: MoneyPeriod.values.map((p) {
        final selected = _period == p;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label(p)),
            selected: selected,
            onSelected: (_) => _onPeriodChanged(p),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, LocalizationService l10n) {
    final net = _totalIncome - _totalExpenses;
    final netColor = net >= 0 ? Colors.green : theme.colorScheme.error;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get(L10nKeys.ledgerMoneyThisMonth),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    theme,
                    label: l10n.get(L10nKeys.ledgerMoneyTotalIncome),
                    value: _formatCurrency(_totalIncome),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    theme,
                    label: l10n.get(L10nKeys.ledgerMoneyTotalExpenses),
                    value: _formatCurrency(_totalExpenses),
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  l10n.get(L10nKeys.ledgerMoneyNetIncome),
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  _formatCurrency(net),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: netColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsSection(ThemeData theme, LocalizationService l10n) {
    final balances = _fiatBalances ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerMoneyAccounts),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (balances.isEmpty)
          Text(
            l10n.get(L10nKeys.ledgerMoneyNoAccounts),
            style: theme.textTheme.bodySmall,
          )
        else
          Column(
            children: balances.map((b) {
              final total = b.totalBalance;
              final usd = b.usdValue;
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(b.asset.symbol.substring(0, 1).toUpperCase()),
                  ),
                  title: Text('${b.asset.symbol} • ${b.asset.name}'),
                  subtitle: usd != null
                      ? Text('\$${_formatCurrency(usd)}')
                      : null,
                  trailing: Text(
                    _formatBalance(total, b.asset.decimals),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTransactionsSection(ThemeData theme, LocalizationService l10n) {
    final txs = _recentTransactions ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerMoneyTransactions),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (txs.isEmpty)
          Text(
            l10n.get(L10nKeys.ledgerMoneyNoTransactions),
            style: theme.textTheme.bodySmall,
          )
        else
          Column(
            children: txs.map((tx) {
              return Card(
                elevation: 0,
                child: ListTile(
                  title: Text(tx.description),
                  subtitle: Text(_formatDateTime(tx.timestamp)),
                  trailing: Text(tx.type.displayName),
                  onTap: () {
                    // future: pass tx id for editing
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, LocalizationService l10n) {
    final totals = _categoryTotals ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerMoneyCategories),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (totals.isEmpty)
          Text(
            l10n.get(L10nKeys.ledgerCommonNoData),
            style: theme.textTheme.bodySmall,
          )
        else
          Column(
            children: totals.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                trailing: Text(_formatCurrency(entry.value)),
              );
            }).toList(),
          ),
      ],
    );
  }

  // Bottom nav copied from Dashboard/Crypto for consistency
  Widget _buildBottomNav(LocalizationService l10n) {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        switch (index) {
          case 0:
            widget.navigation.goToRoute('dashboard');
            break;
          case 1:
            widget.navigation.goToRoute('crypto');
            break;
          case 2:
            // Already here
            break;
          case 3:
            widget.navigation.goToRoute('settings');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: l10n.get(L10nKeys.ledgerNavDashboard),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.currency_bitcoin),
          label: l10n.get(L10nKeys.ledgerNavCrypto),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_balance_wallet),
          label: l10n.get(L10nKeys.ledgerNavMoney),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: l10n.get(L10nKeys.ledgerNavSettings),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _formatBalance(double value, int decimals) {
    return value.toStringAsFixed(decimals);
  }

  String _formatDateTime(DateTime dt) {
    // simple ISO-like for now
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
