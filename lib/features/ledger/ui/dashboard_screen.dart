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

class DashboardScreen extends StatefulWidget {
  final NavigationService navigation;
  final PortfolioValuationService portfolioService;
  final PriceUpdateService priceUpdateService;
  final BalanceService balanceService;
  final BalanceValuationService valuationService;
  final AnalyticsService analytics;

  const DashboardScreen({
    required this.navigation,
    required this.portfolioService,
    required this.priceUpdateService,
    required this.balanceService,
    required this.valuationService,
    required this.analytics,
    super.key,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PortfolioValuation? _portfolio;
  List<ValuatedAssetBalance> _topHoldings = [];
  bool _loading = true;
  bool _updatingPrices = false;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    widget.analytics.logScreenView('dashboard');
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final portfolio = await widget.portfolioService.getPortfolioValue();
      final allBalances = await widget.balanceService.getAllBalances();
      final valuatedBalances = await widget.valuationService.valuate(
        allBalances,
      );

      // Sort by USD value and take top 5
      valuatedBalances.sort((a, b) {
        final aVal = a.usdValue ?? 0;
        final bVal = b.usdValue ?? 0;
        return bVal.compareTo(aVal);
      });

      if (!mounted) return;
      setState(() {
        _portfolio = portfolio;
        _topHoldings = valuatedBalances.take(5).toList();
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

  Future<void> _updatePrices() async {
    if (_updatingPrices) return;

    setState(() => _updatingPrices = true);
    final l10n = context.l10n;

    try {
      final result = await widget.priceUpdateService.updateAllPrices();

      if (!mounted) return;
      setState(() => _updatingPrices = false);

      final msg = result.failureCount == 0
          ? l10n
                .get(L10nKeys.ledgerDashboardPricesUpdated)
                .replaceAll('{success}', '${result.successCount}')
                .replaceAll('{failed}', '0')
          : l10n
                .get(L10nKeys.ledgerDashboardPricesUpdated)
                .replaceAll('{success}', '${result.successCount}')
                .replaceAll('{failed}', '${result.failureCount}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: result.failureCount == 0
                ? Colors.green
                : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingPrices = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get(L10nKeys.ledgerDashboardPriceUpdateFailed)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get(L10nKeys.ledgerDashboardTitle)),
        actions: [
          if (_updatingPrices)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _updatePrices,
              tooltip: l10n.get(L10nKeys.ledgerDashboardUpdatePrices),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => widget.navigation.goToRoute('settings'),
            tooltip: l10n.get(L10nKeys.ledgerSettingsTitle),
          ),
        ],
      ),
      body: _buildBody(theme, l10n),
      bottomNavigationBar: LedgerBottomNav(
        currentTab: LedgerTab.dashboard,
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

    if (_portfolio == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.get(L10nKeys.ledgerDashboardNoAssets),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    widget.navigation.goToRoute('transaction_editor'),
                icon: const Icon(Icons.add),
                label: Text(l10n.get(L10nKeys.ledgerActionAddTransaction)),
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
          if (_portfolio!.isPriceDataStale) _buildStaleWarning(theme, l10n),
          _buildPortfolioCard(theme, l10n),
          const SizedBox(height: 24),
          _buildBreakdown(theme, l10n),
          if (_topHoldings.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildTopHoldings(theme, l10n),
          ],
          const SizedBox(height: 24),
          _buildQuickActions(theme, l10n),
          const SizedBox(height: 80), // FAB clearance
        ],
      ),
    );
  }

  Widget _buildStaleWarning(ThemeData theme, LocalizationService l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.get(L10nKeys.ledgerErrorStalePrice),
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _updatingPrices ? null : _updatePrices,
            child: Text(l10n.get(L10nKeys.ledgerDashboardUpdatePrices)),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(ThemeData theme, LocalizationService l10n) {
    final portfolio = _portfolio!;

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get(L10nKeys.ledgerDashboardTotalPortfolio),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${MoneyFormatting.formatCurrency(portfolio.totalValue)}',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (portfolio.lastPriceUpdate != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n
                    .get(L10nKeys.ledgerDashboardLastUpdate)
                    .replaceAll(
                      '{time}',
                      MoneyFormatting.formatRelativeTime(
                        portfolio.lastPriceUpdate!,
                        (key) => l10n.get(key),
                      ),
                    ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown(ThemeData theme, LocalizationService l10n) {
    final portfolio = _portfolio!;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get(L10nKeys.ledgerDashboardTopHoldings),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              theme,
              l10n,
              Icons.currency_bitcoin,
              l10n.get(L10nKeys.ledgerDashboardCrypto),
              '\$${MoneyFormatting.formatCurrency(portfolio.cryptoValue)}',
            ),
            const Divider(height: 24),
            _buildMetricRow(
              theme,
              l10n,
              Icons.account_balance,
              l10n.get(L10nKeys.ledgerDashboardFiat),
              '\$${MoneyFormatting.formatCurrency(portfolio.fiatValue)}',
            ),
            if (portfolio.otherValue > 0) ...[
              const Divider(height: 24),
              _buildMetricRow(
                theme,
                l10n,
                Icons.category,
                'Other',
                '\$${MoneyFormatting.formatCurrency(portfolio.otherValue)}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    ThemeData theme,
    LocalizationService l10n,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyLarge),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopHoldings(ThemeData theme, LocalizationService l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            l10n.get(L10nKeys.ledgerDashboardTopHoldings),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ..._topHoldings.map((valuated) {
          final balance = valuated.balance;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  balance.asset.symbol.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                balance.asset.symbol,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(balance.asset.name),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    MoneyFormatting.formatBalance(
                      balance.totalBalance,
                      balance.asset.decimals,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (valuated.usdValue != null)
                    Text(
                      '\$${MoneyFormatting.formatCurrency(valuated.usdValue!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme, LocalizationService l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            l10n.get(L10nKeys.ledgerDashboardQuickActions),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l10n.get(L10nKeys.ledgerActionAddTransaction)),
              onPressed: () =>
                  widget.navigation.goToRoute('transaction_editor'),
            ),
            ActionChip(
              avatar: const Icon(Icons.account_balance, size: 18),
              label: Text(l10n.get(L10nKeys.ledgerActionViewAccounts)),
              onPressed: () => widget.navigation.goToRoute('accounts'),
            ),
            ActionChip(
              avatar: const Icon(Icons.widgets, size: 18),
              label: Text(l10n.get(L10nKeys.ledgerActionManageAssets)),
              onPressed: () => widget.navigation.goToRoute('assets'),
            ),
          ],
        ),
      ],
    );
  }
}
