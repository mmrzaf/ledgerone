import 'package:flutter/material.dart';

import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/i18n/string_keys.dart';
import '../data/database.dart';
import '../domain/models.dart';
import '../services/price_update_service.dart';

class DashboardScreen extends StatefulWidget {
  final NavigationService navigation;
  final BalanceService balanceService;
  final PriceUpdateService priceUpdateService;

  const DashboardScreen({
    required this.navigation,
    required this.balanceService,
    required this.priceUpdateService,
    super.key,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, double>? _portfolio;
  List<TotalAssetBalance>? _topAssets;
  bool _loading = true;
  bool _updatingPrices = false;
  String? _errorMessage;
  DateTime? _lastPriceUpdate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final portfolio = await widget.balanceService.getPortfolioValue();
      final allBalances = await widget.balanceService.getAllBalances();

      allBalances.sort((a, b) {
        if (a.usdValue != null && b.usdValue != null) {
          return b.usdValue!.compareTo(a.usdValue!);
        }
        if (a.usdValue != null) return -1;
        if (b.usdValue != null) return 1;
        return a.asset.symbol.compareTo(b.asset.symbol);
      });

      if (!mounted) return;

      setState(() {
        _portfolio = portfolio;
        _topAssets = allBalances.take(5).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _updatePrices() async {
    if (!mounted) return;

    setState(() => _updatingPrices = true);

    try {
      final result = await widget.priceUpdateService.updateAllPrices();

      if (!mounted) return;

      setState(() {
        _updatingPrices = false;
        _lastPriceUpdate = DateTime.now();
      });

      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.get(
              L10nKeys.ledgerDashboardPricesUpdated,
              args: {
                'success': result.successCount.toString(),
                'failed': result.failureCount.toString(),
              },
            ),
          ),
          backgroundColor: result.failureCount == 0
              ? Colors.green
              : Colors.orange,
        ),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      setState(() => _updatingPrices = false);

      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get(L10nKeys.ledgerDashboardPriceUpdateFailed)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get(L10nKeys.ledgerDashboardTitle)),
        actions: [
          if (_updatingPrices)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
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
              // semanticLabel: l10n.get(L10nKeys.ledgera11yUpdatePrices),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => widget.navigation.goToRoute('settings'),
            tooltip: l10n.get(L10nKeys.ledgerNavSettings),
            // semanticLabel: l10n.get(L10nKeys.ledgerA11yOpenSettings),
          ),
        ],
      ),
      body: _buildBody(theme, l10n),
      bottomNavigationBar: _buildBottomNav(l10n),
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
              l10n.get(L10nKeys.ledgerCommonLoading),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.get(L10nKeys.retry)),
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
          _buildPortfolioCard(theme, l10n),
          const SizedBox(height: 24),
          _buildTopAssetsCard(theme, l10n),
          const SizedBox(height: 24),
          _buildQuickActions(theme, l10n),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(ThemeData theme, LocalizationService l10n) {
    final totalValue = _portfolio?['total'] ?? 0.0;
    final cryptoValue = _portfolio?['crypto'] ?? 0.0;
    final fiatValue = _portfolio?['fiat'] ?? 0.0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.get(L10nKeys.ledgerDashboardTotalPortfolio),
                  style: theme.textTheme.titleMedium,
                ),
                if (_lastPriceUpdate != null)
                  Text(
                    l10n.get(
                      L10nKeys.ledgerDashboardLastUpdate,
                      args: {'time': _formatTime(l10n, _lastPriceUpdate!)},
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${_formatCurrency(totalValue)}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPortfolioMetric(
                    theme,
                    l10n,
                    L10nKeys.ledgerDashboardCrypto,
                    cryptoValue,
                    Icons.currency_bitcoin,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPortfolioMetric(
                    theme,
                    l10n,
                    L10nKeys.ledgerDashboardFiat,
                    fiatValue,
                    Icons.account_balance,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioMetric(
    ThemeData theme,
    LocalizationService l10n,
    String labelKey,
    double value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(l10n.get(labelKey), style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${_formatCurrency(value)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAssetsCard(ThemeData theme, LocalizationService l10n) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get(L10nKeys.ledgerDashboardTopHoldings),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_topAssets == null || _topAssets!.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.get(L10nKeys.ledgerDashboardNoAssets),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._topAssets!.map((balance) => _buildAssetRow(theme, balance)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetRow(ThemeData theme, TotalAssetBalance balance) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              balance.asset.symbol.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(balance.asset.symbol, style: theme.textTheme.titleSmall),
                Text(
                  balance.asset.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatBalance(balance.totalBalance, balance.asset.decimals),
                style: theme.textTheme.titleSmall,
              ),
              if (balance.usdValue != null)
                Text(
                  '\$${_formatCurrency(balance.usdValue!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, LocalizationService l10n) {
    final actions = [
      (L10nKeys.ledgerActionAddTransaction, Icons.add, 'transaction_editor'),
      (L10nKeys.ledgerActionViewAccounts, Icons.account_balance, 'accounts'),
      (L10nKeys.ledgerActionManageAssets, Icons.widgets, 'assets'),
      (L10nKeys.ledgerActionBackupData, Icons.backup, 'settings'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerDashboardQuickActions),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final (labelKey, icon, route) = actions[index];
            return _buildActionButton(theme, l10n, labelKey, icon, route);
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ThemeData theme,
    LocalizationService l10n,
    String labelKey,
    IconData icon,
    String route,
  ) {
    return ElevatedButton(
      onPressed: () => widget.navigation.goToRoute(route),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.get(labelKey),
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(LocalizationService l10n) {
    return BottomNavigationBar(
      currentIndex: 0,
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
        if (index == 1) {
          widget.navigation.goToRoute('crypto');
        } else if (index == 2) {
          widget.navigation.goToRoute('money');
        }
      },
    );
  }

  String _formatCurrency(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatBalance(double value, int decimals) {
    return value.toStringAsFixed(decimals);
  }

  String _formatTime(LocalizationService l10n, DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return l10n.get(L10nKeys.ledgerDashboardJustNow);
    }
    if (diff.inMinutes < 60) {
      return l10n.get(
        L10nKeys.ledgerDashboardMinutesAgo,
        args: {'minutes': diff.inMinutes.toString()},
      );
    }
    if (diff.inHours < 24) {
      return l10n.get(
        L10nKeys.ledgerDashboardHoursAgo,
        args: {'hours': diff.inHours.toString()},
      );
    }
    return l10n.get(
      L10nKeys.ledgerDashboardDaysAgo,
      args: {'days': diff.inDays.toString()},
    );
  }
}
