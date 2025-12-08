import 'package:flutter/material.dart';
import '../../../app/presentation/error_presenter.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/i18n/string_keys.dart';
import '../../../shared/utils/money_formatting.dart';
import '../domain/services.dart';
import 'widgets/ledger_bottom_nav.dart';

class MoneyScreen extends StatefulWidget {
  final NavigationService navigation;
  final MoneySummaryService summaryService;
  final AnalyticsService analytics;

  const MoneyScreen({
    required this.navigation,
    required this.summaryService,
    required this.analytics,
    super.key,
  });

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  MoneyPeriod _period = MoneyPeriod.thisMonth;
  MoneySummary? _summary;
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

      if (!mounted) return;

      setState(() {
        _summary = summary;
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

    if (_summary == null) {
      return EmptyState(
        message: l10n.get(L10nKeys.ledgerCommonNoData),
        icon: Icons.account_balance_wallet,
      );
    }

    return RefreshIndicator(
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
    final summary = _summary!;
    final net = summary.netIncome;
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
              _periodLabel(l10n, _period),
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
                    value: MoneyFormatting.formatCurrency(summary.totalIncome),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    theme,
                    label: l10n.get(L10nKeys.ledgerMoneyTotalExpenses),
                    value: MoneyFormatting.formatCurrency(
                      summary.totalExpenses,
                    ),
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
                  MoneyFormatting.formatCurrency(net),
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
    final balances = _summary!.fiatBalances;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerMoneyAccounts),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(b.asset.symbol.substring(0, 1).toUpperCase()),
                  ),
                  title: Text('${b.asset.symbol} • ${b.asset.name}'),
                  subtitle: usd != null
                      ? Text('\$${MoneyFormatting.formatCurrency(usd)}')
                      : null,
                  trailing: Text(
                    MoneyFormatting.formatBalance(total, b.asset.decimals),
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
    final txs = _summary!.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerMoneyTransactions),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(tx.description),
                  subtitle: Text(MoneyFormatting.formatDate(tx.timestamp)),
                  trailing: Chip(
                    label: Text(
                      l10n.get('ledger.tx_type.${tx.type.name}'),
                      style: theme.textTheme.bodySmall,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onTap: () {
                    // Future: navigate to transaction detail
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, LocalizationService l10n) {
    final totals = _summary!.categoryTotals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerMoneyCategories),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(entry.key),
                  trailing: Text(
                    MoneyFormatting.formatCurrency(entry.value),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
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
}
