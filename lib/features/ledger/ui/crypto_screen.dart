import 'package:flutter/material.dart';
import '../../../app/presentation/error_presenter.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/i18n/string_keys.dart';
import '../../../shared/utils/money_formatting.dart';
import '../domain/models.dart';
import '../domain/services.dart';
import 'widgets/ledger_bottom_nav.dart';

class CryptoScreen extends StatefulWidget {
  final NavigationService navigation;
  final BalanceService balanceService;
  final AnalyticsService analytics;

  const CryptoScreen({
    required this.navigation,
    required this.balanceService,
    required this.analytics,
    super.key,
  });

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen>
    with SingleTickerProviderStateMixin {
  List<TotalAssetBalance>? _cryptoBalances;
  Map<String, List<AssetBalance>>? _accountBalances;
  bool _loading = true;
  AppError? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.analytics.logScreenView('crypto');
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
      final cryptoOnly = allBalances
          .where((b) => b.asset.type == AssetType.crypto)
          .toList();

      final Map<String, List<AssetBalance>> byAccount = {};
      for (final balance in cryptoOnly) {
        for (final accountBalance in balance.accountBalances) {
          if (accountBalance.balance != 0) {
            byAccount.putIfAbsent(accountBalance.accountId, () => []);
            byAccount[accountBalance.accountId]!.add(accountBalance);
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _cryptoBalances = cryptoOnly;
        _accountBalances = byAccount;
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
        title: Text(l10n.get(L10nKeys.ledgerCryptoTitle)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.get(L10nKeys.ledgerCryptoByAsset)),
            Tab(text: l10n.get(L10nKeys.ledgerCryptoByAccount)),
          ],
        ),
      ),
      body: _buildBody(theme, l10n),
      bottomNavigationBar: LedgerBottomNav(
        currentTab: LedgerTab.crypto,
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
          child: ErrorCard(
            error: _error!,
            screen: 'crypto',
            onRetry: _loadData,
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [_buildAssetView(theme, l10n), _buildAccountView(theme, l10n)],
    );
  }

  Widget _buildAssetView(ThemeData theme, LocalizationService l10n) {
    if (_cryptoBalances == null || _cryptoBalances!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.get(L10nKeys.ledgerCryptoNoAssets),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  widget.navigation.goToRoute('transaction_editor'),
              icon: const Icon(Icons.add),
              label: Text(l10n.get(L10nKeys.ledgerActionAddTransaction)),
            ),
          ],
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
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Column(
            children: [
              Text(
                l10n.get(L10nKeys.ledgerCryptoTotalValue),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${MoneyFormatting.formatCurrency(totalValue)}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '${_cryptoBalances!.length} ${l10n.get(L10nKeys.ledgerCryptoAssets)}',
                style: theme.textTheme.bodySmall,
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
                return _buildAssetCard(theme, l10n, _cryptoBalances![index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountView(ThemeData theme, LocalizationService l10n) {
    if (_accountBalances == null || _accountBalances!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.get(L10nKeys.ledgerCryptoNoAccounts),
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
        itemCount: _accountBalances!.length,
        itemBuilder: (context, index) {
          final accountId = _accountBalances!.keys.elementAt(index);
          final balances = _accountBalances![accountId]!;
          return _buildAccountCard(theme, l10n, accountId, balances);
        },
      ),
    );
  }

  Widget _buildAssetCard(
    ThemeData theme,
    LocalizationService l10n,
    TotalAssetBalance balance,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAssetDetail(balance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.asset.symbol,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          balance.asset.name,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        MoneyFormatting.formatBalance(
                          balance.totalBalance,
                          balance.asset.decimals,
                        ),
                        style: theme.textTheme.titleSmall,
                      ),
                      if (balance.usdValue != null)
                        Text(
                          '\$${MoneyFormatting.formatCurrency(balance.usdValue!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (balance.accountBalances.length > 1) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...balance.accountBalances.take(3).map((ab) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ab.account.name, style: theme.textTheme.bodySmall),
                        Text(
                          MoneyFormatting.formatBalance(
                            ab.balance,
                            balance.asset.decimals,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (balance.accountBalances.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${balance.accountBalances.length - 3} more accounts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    ThemeData theme,
    LocalizationService l10n,
    String accountId,
    List<AssetBalance> balances,
  ) {
    final account = balances.first.account;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAccountDetail(account, balances),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    radius: 24,
                    child: Icon(
                      _iconForAccountType(account.type),
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${balances.length} ${l10n.get(L10nKeys.ledgerCryptoAssets)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: balances.take(5).map((balance) {
                  return Chip(
                    label: Text(
                      '${balance.asset.symbol}: ${MoneyFormatting.formatBalance(balance.balance, balance.asset.decimals)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssetDetail(TotalAssetBalance balance) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        radius: 30,
                        child: Text(
                          balance.asset.symbol.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              balance.asset.symbol,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              balance.asset.name,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Balance',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              MoneyFormatting.formatBalance(
                                balance.totalBalance,
                                balance.asset.decimals,
                              ),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (balance.usdValue != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'USD Value',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                '\$${MoneyFormatting.formatCurrency(balance.usdValue!)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Holdings by Account',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: balance.accountBalances.length,
                      itemBuilder: (context, index) {
                        final ab = balance.accountBalances[index];
                        return ListTile(
                          leading: Icon(_iconForAccountType(ab.account.type)),
                          title: Text(ab.account.name),
                          trailing: Text(
                            MoneyFormatting.formatBalance(
                              ab.balance,
                              balance.asset.decimals,
                            ),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAccountDetail(Account account, List<AssetBalance> balances) {
    // Implementation similar to asset detail
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
