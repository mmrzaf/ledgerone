import 'package:flutter/material.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/i18n/string_keys.dart';
import '../../../shared/utils/money_formatting.dart';
import '../domain/models.dart';
import '../domain/services.dart';
import 'widgets/ledger_bottom_nav.dart';

class MoneyScreen extends StatefulWidget {
  final NavigationService navigation;
  final MoneySummaryService summaryService;
  final BalanceValuationService valuationService;
  final AnalyticsService analytics;

  const MoneyScreen({
    required this.navigation,
    required this.summaryService,
    required this.valuationService,
    required this.analytics,
    super.key,
  });

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  MoneyPeriod _period = MoneyPeriod.thisMonth;
  MoneySummary? _summary;
  List<ValuatedAssetBalance> _valuatedBalances = [];
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
      final summary = await widget.summaryService.getSummary(_period);
      final valuated = await widget.valuationService.valuate(
        summary.fiatBalances,
      );

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _valuatedBalances = valuated;
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
      body: _buildBody(theme, l10n),
      bottomNavigationBar: LedgerBottomNav(
        currentTab: LedgerTab.money,
        navigation: widget.navigation,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.navigation.goToRoute('transaction_editor'),
        icon: const Icon(Icons.add),
        label: Text(l10n.get(L10nKeys.ledgerActionAddTransaction)),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, LocalizationService l10n) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.get(L10nKeys.ledgerCommonLoadingData),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                _error!.message,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.get(L10nKeys.retry)),
              ),
            ],
          ),
        ),
      );
    }

    if (_summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.get(L10nKeys.ledgerCommonNoData),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodChips(theme, l10n),
          const SizedBox(height: 16),
          _buildSummaryCard(theme, l10n),
          const SizedBox(height: 24),
          _buildAccountsSection(theme, l10n),
          const SizedBox(height: 24),
          _buildTransactionsSection(theme, l10n),
          if (_summary!.categoryTotals.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildCategoriesSection(theme, l10n),
          ],
          const SizedBox(height: 80), // FAB clearance
        ],
      ),
    );
  }

  Widget _buildPeriodChips(ThemeData theme, LocalizationService l10n) {
    String label(MoneyPeriod p) {
      switch (p) {
        case MoneyPeriod.thisMonth:
          return l10n.get(L10nKeys.ledgerMoneyThisMonth);
        case MoneyPeriod.lastMonth:
          return 'Last month';
        case MoneyPeriod.allTime:
          return 'All time';
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, LocalizationService l10n) {
    final summary = _summary!;
    final net = summary.netIncome;
    final netColor = net >= 0 ? Colors.green : theme.colorScheme.error;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _periodLabel(l10n, _period),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    theme,
                    l10n,
                    label: l10n.get(L10nKeys.ledgerMoneyTotalIncome),
                    value: MoneyFormatting.formatCurrency(summary.totalIncome),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    theme,
                    l10n,
                    label: l10n.get(L10nKeys.ledgerMoneyTotalExpenses),
                    value: MoneyFormatting.formatCurrency(
                      summary.totalExpenses,
                    ),
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.get(L10nKeys.ledgerMoneyNetIncome),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${MoneyFormatting.formatCurrency(net.abs())}',
                  style: theme.textTheme.headlineSmall?.copyWith(
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
    ThemeData theme,
    LocalizationService l10n, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$$value',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsSection(ThemeData theme, LocalizationService l10n) {
    if (_valuatedBalances.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get(L10nKeys.ledgerMoneyAccounts),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.get(L10nKeys.ledgerMoneyNoAccounts),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerMoneyAccounts),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._valuatedBalances.map((valuated) {
          final balance = valuated.balance;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(
                  balance.asset.symbol.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                '${balance.asset.symbol} • ${balance.asset.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: valuated.usdValue != null
                  ? Text(
                      '\$${MoneyFormatting.formatCurrency(valuated.usdValue!)}',
                    )
                  : null,
              trailing: Text(
                MoneyFormatting.formatBalance(
                  balance.totalBalance,
                  balance.asset.decimals,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTransactionsSection(ThemeData theme, LocalizationService l10n) {
    final txs = _summary!.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.get(L10nKeys.ledgerMoneyTransactions),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (txs.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Future: navigate to full transaction list
                },
                child: const Text('See all'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (txs.isEmpty)
          Text(
            l10n.get(L10nKeys.ledgerMoneyNoTransactions),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          )
        else
          ...txs.map((tx) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => widget.navigation.goToRoute(
                  'transaction_editor',
                  params: {'id': tx.id},
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _colorForType(tx.type).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconForType(tx.type),
                          color: _colorForType(tx.type),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              MoneyFormatting.formatDate(tx.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          l10n.get('ledger.tx_type.${tx.type.name}'),
                          style: theme.textTheme.bodySmall,
                        ),
                        padding: EdgeInsets.zero,
                        backgroundColor: _colorForType(
                          tx.type,
                        ).withValues(alpha: 0.1),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, LocalizationService l10n) {
    final totals = _summary!.categoryTotals;
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerMoneyCategories),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...entries.take(5).map((entry) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.tertiaryContainer,
                child: Icon(
                  Icons.category,
                  size: 20,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              title: Text(entry.key),
              trailing: Text(
                '\$${MoneyFormatting.formatCurrency(entry.value)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _periodLabel(LocalizationService l10n, MoneyPeriod period) {
    switch (period) {
      case MoneyPeriod.thisMonth:
        return l10n.get(L10nKeys.ledgerMoneyThisMonth);
      case MoneyPeriod.lastMonth:
        return 'Last month';
      case MoneyPeriod.allTime:
        return 'All time';
    }
  }

  Color _colorForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
      case TransactionType.trade:
        return Colors.purple;
      case TransactionType.adjustment:
        return Colors.orange;
    }
  }

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.trade:
        return Icons.compare_arrows;
      case TransactionType.adjustment:
        return Icons.edit;
    }
  }
}
