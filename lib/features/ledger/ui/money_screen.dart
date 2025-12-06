import 'package:flutter/material.dart';

import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/i18n/string_keys.dart';
import '../data/database.dart';
import '../domain/models.dart';

class MoneyScreen extends StatefulWidget {
  final NavigationService navigation;
  final BalanceService balanceService;

  const MoneyScreen({
    required this.navigation,
    required this.balanceService,
    super.key,
  });

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TotalAssetBalance>? _fiatBalances;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _loading = true);

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
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAccountsView(theme, l10n),
                _buildTransactionsView(theme, l10n),
                _buildCategoriesView(theme, l10n),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.navigation.goToRoute('transaction_editor'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAccountsView(ThemeData theme, LocalizationService l10n) {
    if (_fiatBalances == null || _fiatBalances!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.get(L10nKeys.ledgerMoneyNoAccounts),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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

  Widget _buildTransactionsView(ThemeData theme, LocalizationService l10n) {
    return Center(
      child: Text(
        l10n.get(L10nKeys.ledgerMoneyNoTransactions),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildCategoriesView(ThemeData theme, LocalizationService l10n) {
    return Center(
      child: Text(
        l10n.get(L10nKeys.ledgerMoneyCategories),
        style: theme.textTheme.bodyLarge,
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
