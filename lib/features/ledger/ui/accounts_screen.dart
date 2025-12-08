import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/i18n/string_keys.dart';
import '../data/repositories_interfaces.dart';
import '../domain/models.dart';

class AccountsScreen extends StatefulWidget {
  final NavigationService navigation;
  final AccountRepository accountRepo;
  final AnalyticsService analytics;

  const AccountsScreen({
    required this.navigation,
    required this.accountRepo,
    required this.analytics,
    super.key,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  bool _loading = true;
  bool _saving = false;
  List<Account> _accounts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.analytics.logScreenView('accounts');
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final accounts = await widget.accountRepo.getAll();
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showEditor({Account? account}) async {
    final l10n = context.l10n;

    final nameController = TextEditingController(text: account?.name ?? '');
    final notesController = TextEditingController(text: account?.notes ?? '');
    AccountType type = account?.type ?? AccountType.bank;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                account == null
                    ? l10n.get(L10nKeys.ledgerCommonAdd)
                    : l10n.get(L10nKeys.ledgerCommonEdit),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AccountType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: AccountType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      type = value;
                    });
                  }
                },
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.get(L10nKeys.ledgerCommonCancel)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.get(L10nKeys.ledgerCommonSave)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != true) return;

    final name = nameController.text.trim();
    final notes = notesController.text.trim();

    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final newAccount = Account(
        id: account?.id ?? const Uuid().v4(),
        name: name,
        type: type,
        notes: notes.isEmpty ? null : notes,
        createdAt: now,
        updatedAt: now,
      );

      if (account == null) {
        await widget.accountRepo.insert(newAccount);
      } else {
        await widget.accountRepo.update(newAccount);
      }

      await _loadAccounts();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.get(L10nKeys.ledgerCommonClose),
          onPressed: () => widget.navigation.goBack(),
        ),
        title: Text(l10n.get(L10nKeys.ledgerCommonAccounts)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _accounts.isEmpty
          ? Center(child: Text(l10n.get(L10nKeys.ledgerMoneyNoAccounts)))
          : ListView.separated(
              itemCount: _accounts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final account = _accounts[index];
                return ListTile(
                  leading: Icon(_iconForAccountType(account.type)),
                  title: Text(account.name),
                  subtitle: account.notes != null ? Text(account.notes!) : null,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditor(account: account);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.get(L10nKeys.ledgerCommonEdit)),
                      ),
                    ],
                  ),
                  onTap: () => _showEditor(account: account),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : () => _showEditor(),
        child: const Icon(Icons.add),
      ),
    );
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
