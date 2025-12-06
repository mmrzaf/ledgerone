import 'package:flutter/material.dart';

import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/i18n/string_keys.dart';
import '../data/database.dart';
import '../domain/models.dart';

class CryptoScreen extends StatefulWidget {
  final NavigationService navigation;
  final BalanceService balanceService;
  final AssetRepository assetRepo;

  const CryptoScreen({
    required this.navigation,
    required this.balanceService,
    required this.assetRepo,
    super.key,
  });

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TotalAssetBalance>? _cryptoBalances;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final cryptoOnly = allBalances
          .where((b) => b.asset.type == AssetType.crypto)
          .toList();

      if (!mounted) return;

      setState(() {
        _cryptoBalances = cryptoOnly;
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
        title: Text(l10n.get(L10nKeys.ledgerCryptoTitle)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.get(L10nKeys.ledgerCryptoByAsset)),
            Tab(text: l10n.get(L10nKeys.ledgerCryptoByAccount)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAssetView(theme, l10n),
                _buildAccountView(theme, l10n),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.navigation.goToRoute('transaction_editor'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAssetView(ThemeData theme, LocalizationService l10n) {
    if (_cryptoBalances == null || _cryptoBalances!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.currency_bitcoin,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.get(L10nKeys.ledgerCryptoNoAssets),
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

    double totalValue = 0;
    for (final balance in _cryptoBalances!) {
      if (balance.usdValue != null) {
        totalValue += balance.usdValue!;
      }
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          child: Column(
            children: [
              Text(
                l10n.get(L10nKeys.ledgerCryptoTotalValue),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_formatCurrency(totalValue)}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cryptoBalances!.length,
              itemBuilder: (context, index) {
                return _buildAssetCard(theme, _cryptoBalances![index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(ThemeData theme, TotalAssetBalance balance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          radius: 24,
          child: Text(
            balance.asset.symbol.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(balance.asset.symbol, style: theme.textTheme.titleMedium),
        subtitle: Text(balance.asset.name),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  Widget _buildAccountView(ThemeData theme, LocalizationService l10n) {
    return Center(
      child: Text(
        l10n.get(L10nKeys.ledgerCryptoByAccount),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildBottomNav(LocalizationService l10n) {
    return BottomNavigationBar(
      currentIndex: 1,
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
}
