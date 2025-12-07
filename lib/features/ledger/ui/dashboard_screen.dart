import 'package:flutter/material.dart';

import '../../../app/presentation/error_presenter.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/i18n/string_keys.dart';
import '../domain/services.dart';

class DashboardScreen extends StatefulWidget {
  final NavigationService navigation;
  final PortfolioValuationService portfolioService;
  final PriceUpdateService priceUpdateService;
  final AnalyticsService analytics;

  const DashboardScreen({
    required this.navigation,
    required this.portfolioService,
    required this.priceUpdateService,
    required this.analytics,
    super.key,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PortfolioValuation? _portfolio;
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

      if (!mounted) return;

      setState(() {
        _portfolio = portfolio;
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
    if (!mounted) return;

    setState(() => _updatingPrices = true);

    try {
      final result = await widget.priceUpdateService.updateAllPrices();

      if (!mounted) return;

      setState(() => _updatingPrices = false);

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

      ErrorPresenter.showError(
        context,
        e is AppError
            ? e
            : AppError(
                category: ErrorCategory.unknown,
                message: e.toString(),
                originalError: e,
              ),
        screen: 'dashboard',
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
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => widget.navigation.goToRoute('settings'),
            tooltip: l10n.get(L10nKeys.ledgerNavSettings),
          ),
        ],
      ),
      body: _buildBody(theme, l10n),
      bottomNavigationBar: _buildBottomNav(l10n),
    );
  }

  Widget _buildBody(ThemeData theme, LocalizationService l10n) {
    if (_loading) {
      return LoadingIndicator(message: l10n.get(L10nKeys.ledgerCommonLoading));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ErrorCard(
            error: _error!,
            screen: 'dashboard',
            onRetry: _loadData,
          ),
        ),
      );
    }

    if (_portfolio == null) {
      return EmptyState(
        message: l10n.get(L10nKeys.ledgerDashboardNoAssets),
        icon: Icons.account_balance_wallet,
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
          _buildQuickActions(theme, l10n),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStaleWarning(ThemeData theme, LocalizationService l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.get(L10nKeys.ledgerErrorStalePrice),
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(ThemeData theme, LocalizationService l10n) {
    final portfolio = _portfolio!;
    final totalValue = portfolio.totalValue;
    final cryptoValue = portfolio.cryptoValue;
    final fiatValue = portfolio.fiatValue;

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
                if (portfolio.lastPriceUpdate != null)
                  Text(
                    l10n.get(
                      L10nKeys.ledgerDashboardLastUpdate,
                      args: {
                        'time': _formatTime(l10n, portfolio.lastPriceUpdate!),
                      },
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
