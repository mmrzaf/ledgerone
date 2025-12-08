import 'package:flutter/material.dart';
import '../../../app/di.dart';
import '../../../app/presentation/error_presenter.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/i18n/string_keys.dart';
import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class MoneyScreen extends StatefulWidget {
  final NavigationService navigation;
  final BalanceService balanceService;
  final AnalyticsService analytics;

  const MoneyScreen({
    required this.navigation,
    required this.balanceService,
    required this.analytics,
    super.key,
  });

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen>
    with SingleTickerProviderStateMixin {
  List<TotalAssetBalance>? _fiatBalances;
  List<Transaction>? _recentTransactions;
  Map<String, double>? _categoryTotals;
  bool _loading = true;
  AppError? _error;
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.analytics.logScreenView('money');
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final allBalances = await widget.balanceService.getAllBalances();
      final fiatOnly = allBalances
          .where((b) => b.asset.type == AssetType.fiat)
          .toList();

      // Load transactions for current month
      final transactionRepo = ServiceLocator().get<TransactionRepository>();
      final startOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
      );
      final endOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
        23,
        59,
        59,
      );

      final transactions = await transactionRepo.getAll(
        after: startOfMonth,
        before: endOfMonth,
      );

      // Filter for income/expense only and calculate category totals
      final categoryRepo = ServiceLocator().get<CategoryRepository>();
      final categories = await categoryRepo.getAll();
      final categoryMap = {for (var c in categories) c.id: c};

      final Map<String, double> categoryTotals = {};
      final incomeExpenseTransactions = <Transaction>[];

      for (final tx in transactions) {
        if (tx.type == TransactionType.income ||
            tx.type == TransactionType.expense) {
          incomeExpenseTransactions.add(tx);

          // Get legs and sum by category
          final legs = await transactionRepo.getLegsForTransaction(tx.id);
          for (final leg in legs) {
            if (leg.categoryId != null) {
              final category = categoryMap[leg.categoryId];
              if (category != null) {
                categoryTotals[category.name] =
                    (categoryTotals[category.name] ?? 0) + leg.amount.abs();
              }
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _fiatBalances = fiatOnly;
        _recentTransactions = incomeExpenseTransactions;
        _categoryTotals = categoryTotals;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get(L10nKeys.ledgerMoneyTitle)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.get(L10nKeys.ledgerMoneyAccounts)),
            Tab(text: l10n.get(L10nKeys.ledgerMoneyTransactions)),
            Tab(text: l10n.get(L10nKeys.ledgerMoneyCategories)),
          ],
        ),
      ),
      body: _buildBody(theme, l10n),
      bottomNavigationBar: _buildBottomNav(l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.navigation.goToRoute('transaction_editor'),
        tooltip: l10n.get(L10nKeys.ledgerActionAddTransaction),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, LocalizationService l10n) {
    if (_loading) {
      return LoadingIndicator(message: l10n.get(L10nKeys.ledgerCommonLoading));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorCard(error: _error!, screen: 'money', onRetry: _loadData),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAccountsView(theme, l10n),
        _buildTransactionsView(theme, l10n),
        _buildCategoriesView(theme, l10n),
      ],
    );
  }

  Widget _buildAccountsView(ThemeData theme, LocalizationService l10n) {
    if (_fiatBalances?.isEmpty ?? true) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.get(L10nKeys.ledgerMoneyNoAccounts),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => widget.navigation.goToRoute('accounts'),
              icon: const Icon(Icons.add),
              label: Text(l10n.get(L10nKeys.ledgerCommonAccounts)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fiatBalances!.length,
        itemBuilder: (context, index) {
          final balance = _fiatBalances![index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(
                  Icons.account_balance,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(
                balance.asset.symbol,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(balance.asset.name),
              trailing: Text(
                _formatBalance(balance.totalBalance, balance.asset.decimals),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: balance.accountBalances.map((ab) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  leading: Icon(_iconForAccountType(ab.account.type), size: 20),
                  title: Text(ab.account.name),
                  trailing: Text(
                    _formatBalance(ab.balance, balance.asset.decimals),
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsView(ThemeData theme, LocalizationService l10n) {
    if (_recentTransactions == null || _recentTransactions!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.get(L10nKeys.ledgerMoneyNoTransactions),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  widget.navigation.goToRoute('transaction_editor'),
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
            ),
          ],
        ),
      );
    }

    // Calculate month summary
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final tx in _recentTransactions!) {
      if (tx.type == TransactionType.income) {
        // Get transaction legs to sum amounts
        ServiceLocator()
            .get<TransactionRepository>()
            .getLegsForTransaction(tx.id)
            .then((legs) {
              for (final leg in legs) {
                if (leg.amount > 0) totalIncome += leg.amount;
              }
            });
      } else if (tx.type == TransactionType.expense) {
        ServiceLocator()
            .get<TransactionRepository>()
            .getLegsForTransaction(tx.id)
            .then((legs) {
              for (final leg in legs) {
                if (leg.amount < 0) totalExpenses += leg.amount.abs();
              }
            });
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                      _loadData();
                    },
                  ),
                  Text(
                    '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed:
                        _selectedMonth.month < DateTime.now().month ||
                            _selectedMonth.year < DateTime.now().year
                        ? () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month + 1,
                              );
                            });
                            _loadData();
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      theme,
                      l10n.get(L10nKeys.ledgerMoneyTotalIncome),
                      totalIncome,
                      Colors.green,
                      Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      theme,
                      l10n.get(L10nKeys.ledgerMoneyTotalExpenses),
                      totalExpenses,
                      Colors.red,
                      Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                theme,
                l10n.get(L10nKeys.ledgerMoneyNetIncome),
                totalIncome - totalExpenses,
                totalIncome - totalExpenses >= 0 ? Colors.green : Colors.red,
                totalIncome - totalExpenses >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recentTransactions!.length,
              itemBuilder: (context, index) {
                return _buildTransactionCard(
                  theme,
                  l10n,
                  _recentTransactions![index],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesView(ThemeData theme, LocalizationService l10n) {
    if (_categoryTotals == null || _categoryTotals!.isEmpty) {
      return Center(child: Text(l10n.get(L10nKeys.ledgerMoneyNoTransactions)));
    }

    final sortedCategories = _categoryTotals!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = _categoryTotals!.values.fold<double>(
      0,
      (sum, val) => sum + val,
    );

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final entry = sortedCategories[index];
          final percentage = total > 0 ? (entry.value / total * 100) : 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${_formatCurrency(entry.value)}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${_formatCurrency(value)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    ThemeData theme,
    LocalizationService l10n,
    Transaction tx,
  ) {
    final isIncome = tx.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        title: Text(tx.description),
        subtitle: Text(_formatDate(tx.timestamp)),
        trailing: FutureBuilder<List<TransactionLeg>>(
          future: ServiceLocator()
              .get<TransactionRepository>()
              .getLegsForTransaction(tx.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final amount = snapshot.data!.fold<double>(
              0,
              (sum, leg) => sum + leg.amount.abs(),
            );
            return Text(
              '\$${_formatCurrency(amount)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
        ),
        onTap: () {
          // Navigate to transaction detail/edit
        },
      ),
    );
  }

  Widget _buildBottomNav(LocalizationService l10n) {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
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
      ],
      onTap: (index) {
        if (index == 0) {
          widget.navigation.goToRoute('dashboard');
        } else if (index == 1) {
          widget.navigation.goToRoute('crypto');
        }
      },
    );
  }

  String _formatBalance(double value, int decimals) {
    return value.toStringAsFixed(decimals);
  }

  String _formatCurrency(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  IconData _iconForAccountType(AccountType type) {
    switch (type) {
      case AccountType.exchange:
        return Icons.currency_bitcoin;
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.wallet:
        return Icons.account_balance_wallet;
      case AccountType.cash:
        return Icons.money;
      case AccountType.other:
        return Icons.account_circle;
    }
  }
}
