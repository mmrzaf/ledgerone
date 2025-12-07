import 'package:flutter/material.dart';

import '../../../app/presentation/error_presenter.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/i18n/string_keys.dart';
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

class _MoneyScreenState extends State<MoneyScreen> {
  List<TotalAssetBalance>? _fiatBalances;
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
      final allBalances = await widget.balanceService.getAllBalances();
      final fiatOnly = allBalances
          .where((b) => b.asset.type == AssetType.fiat)
          .toList();

      if (!mounted) return;

      setState(() {
        _fiatBalances = fiatOnly;
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
      appBar: AppBar(title: Text(l10n.get(L10nKeys.ledgerMoneyTitle))),
      body: _buildBody(theme, l10n),
      bottomNavigationBar: _buildBottomNav(l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.navigation.goToRoute('transaction_editor'),
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

    if (_fiatBalances == null || _fiatBalances!.isEmpty) {
      return EmptyState(
        message: l10n.get(L10nKeys.ledgerMoneyNoAccounts),
        icon: Icons.account_balance,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fiatBalances!.length,
        itemBuilder: (context, index) {
          return _buildFiatCard(theme, _fiatBalances![index]);
        },
      ),
    );
  }

  Widget _buildFiatCard(ThemeData theme, TotalAssetBalance balance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          radius: 24,
          child: Icon(
            Icons.account_balance,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(balance.asset.symbol, style: theme.textTheme.titleMedium),
        subtitle: Text(balance.asset.name),
        trailing: Text(
          _formatBalance(balance.totalBalance, balance.asset.decimals),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
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
}
