import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/di.dart';
import '../../../app/presentation/error_presenter.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/i18n/string_keys.dart';
import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class TransactionEditorScreen extends StatefulWidget {
  final NavigationService navigation;
  final TransactionService transactionService;
  final AnalyticsService analytics;

  const TransactionEditorScreen({
    required this.navigation,
    required this.transactionService,
    required this.analytics,
    super.key,
  });

  @override
  State<TransactionEditorScreen> createState() =>
      _TransactionEditorScreenState();
}

class _TransactionEditorScreenState extends State<TransactionEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  TransactionType _type = TransactionType.expense;
  DateTime _timestamp = DateTime.now();
  final _descriptionController = TextEditingController();

  Account? _selectedAccount;
  Account? _toAccount;
  Asset? _selectedAsset;
  Asset? _fromAsset;
  Asset? _toAsset;
  Asset? _feeAsset;
  Category? _selectedCategory;

  final _amountController = TextEditingController();
  final _toAmountController = TextEditingController();
  final _feeAmountController = TextEditingController();

  List<Asset> _assets = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.analytics.logScreenView('transaction_editor');
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _toAmountController.dispose();
    _feeAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final assetRepo = ServiceLocator().get<AssetRepository>();
      final accountRepo = ServiceLocator().get<AccountRepository>();
      final categoryRepo = ServiceLocator().get<CategoryRepository>();

      final assets = await assetRepo.getAll();
      final accounts = await accountRepo.getAll();
      final categories = await categoryRepo.getAll();

      if (mounted) {
        setState(() {
          _assets = assets;
          _accounts = accounts;
          _categories = categories;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorPresenter.showError(
          context,
          e is AppError
              ? e
              : AppError(
                  category: ErrorCategory.unknown,
                  message: e.toString(),
                  originalError: e,
                ),
          screen: 'transaction_editor',
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final description = _descriptionController.text.trim();

      switch (_type) {
        case TransactionType.income:
          await widget.transactionService.createIncome(
            accountId: _selectedAccount!.id,
            assetId: _selectedAsset!.id,
            amount: _parseAmount(_amountController.text),
            categoryId: _selectedCategory?.id,
            description: description,
            timestamp: _timestamp,
          );
          break;

        case TransactionType.expense:
          await widget.transactionService.createExpense(
            accountId: _selectedAccount!.id,
            assetId: _selectedAsset!.id,
            amount: _parseAmount(_amountController.text),
            categoryId: _selectedCategory!.id,
            description: description,
            timestamp: _timestamp,
          );
          break;

        case TransactionType.transfer:
          await widget.transactionService.createTransfer(
            fromAccountId: _selectedAccount!.id,
            toAccountId: _toAccount!.id,
            assetId: _selectedAsset!.id,
            amount: _parseAmount(_amountController.text),
            description: description,
            timestamp: _timestamp,
          );
          break;

        case TransactionType.trade:
          await widget.transactionService.createTrade(
            accountId: _selectedAccount!.id,
            fromAssetId: _fromAsset!.id,
            fromAmount: _parseAmount(_amountController.text),
            toAssetId: _toAsset!.id,
            toAmount: _parseAmount(_toAmountController.text),
            feeAssetId: _feeAsset?.id,
            feeAmount: _feeAmountController.text.isEmpty
                ? null
                : _parseAmount(_feeAmountController.text),
            description: description,
            timestamp: _timestamp,
          );
          break;

        case TransactionType.adjustment:
          await widget.transactionService.createAdjustment(
            accountId: _selectedAccount!.id,
            assetId: _selectedAsset!.id,
            amount: _parseAmount(_amountController.text),
            description: description,
            timestamp: _timestamp,
          );
          break;
      }

      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.get(L10nKeys.ledgerTxEditorCreated)),
            backgroundColor: Colors.green,
          ),
        );
        widget.navigation.goBack();
      }
    } on AppError catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);
      ErrorPresenter.showError(context, e, screen: 'transaction_editor');
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);
      ErrorPresenter.showError(
        context,
        AppError(
          category: ErrorCategory.unknown,
          message: e.toString(),
          originalError: e,
        ),
        screen: 'transaction_editor',
      );
    }
  }

  double _parseAmount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const AppError(
        category: ErrorCategory.badRequest,
        message: 'Amount cannot be empty',
      );
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed == 0.0) {
      throw const AppError(
        category: ErrorCategory.badRequest,
        message: 'Invalid amount',
      );
    }

    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get(L10nKeys.ledgerTxEditorTitle)),
        actions: [
          if (_saving)
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
              icon: const Icon(Icons.check),
              onPressed: _save,
              tooltip: l10n.get(L10nKeys.ledgerCommonSave),
            ),
        ],
      ),
      body: _loading
          ? LoadingIndicator(message: l10n.get(L10nKeys.ledgerCommonLoading))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTypeSelector(theme, l10n),
                  const SizedBox(height: 24),
                  _buildDateTimePicker(theme, l10n),
                  const SizedBox(height: 16),
                  _buildDescriptionField(l10n),
                  const SizedBox(height: 24),
                  ..._buildTypeSpecificFields(theme, l10n),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(l10n.get(L10nKeys.ledgerTxEditorCreate)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme, LocalizationService l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get(L10nKeys.ledgerTxEditorType),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TransactionType.values.map((type) {
            final isSelected = type == _type;
            return ChoiceChip(
              label: Text(l10n.get('ledger.tx_type.${type.name}')),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _type = type);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(ThemeData theme, LocalizationService l10n) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: Text(l10n.get(L10nKeys.ledgerTxEditorDateTime)),
      subtitle: Text(_formatDateTime(_timestamp)),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _timestamp,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );

        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_timestamp),
          );

          if (time != null) {
            setState(() {
              _timestamp = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            });
          }
        }
      },
    );
  }

  Widget _buildDescriptionField(LocalizationService l10n) {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorDescription),
        hintText: l10n.get(L10nKeys.ledgerTxEditorDescriptionHint),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.get(L10nKeys.ledgerTxEditorDescriptionRequired);
        }
        return null;
      },
    );
  }

  List<Widget> _buildTypeSpecificFields(
    ThemeData theme,
    LocalizationService l10n,
  ) {
    switch (_type) {
      case TransactionType.income:
      case TransactionType.expense:
        return [
          _buildAccountDropdown(l10n),
          const SizedBox(height: 16),
          _buildAssetDropdown(l10n),
          const SizedBox(height: 16),
          _buildAmountField(l10n, L10nKeys.ledgerTxEditorAmount),
          const SizedBox(height: 16),
          _buildCategoryDropdown(
            l10n,
            _type == TransactionType.income ? 'income' : 'expense',
          ),
        ];

      case TransactionType.transfer:
        return [
          _buildAccountDropdown(
            l10n,
            label: L10nKeys.ledgerTxEditorFromAccount,
          ),
          const SizedBox(height: 16),
          _buildToAccountDropdown(l10n),
          const SizedBox(height: 16),
          _buildAssetDropdown(l10n),
          const SizedBox(height: 16),
          _buildAmountField(l10n, L10nKeys.ledgerTxEditorAmount),
        ];

      case TransactionType.trade:
        return [
          _buildAccountDropdown(l10n),
          const SizedBox(height: 16),
          _buildFromAssetDropdown(l10n),
          const SizedBox(height: 16),
          _buildAmountField(
            l10n,
            L10nKeys.ledgerTxEditorAmountPaid,
            controller: _amountController,
          ),
          const SizedBox(height: 16),
          _buildToAssetDropdown(l10n),
          const SizedBox(height: 16),
          _buildAmountField(
            l10n,
            L10nKeys.ledgerTxEditorAmountReceived,
            controller: _toAmountController,
          ),
          const SizedBox(height: 16),
          _buildFeeAssetDropdown(l10n),
          if (_feeAsset != null) ...[
            const SizedBox(height: 16),
            _buildAmountField(
              l10n,
              L10nKeys.ledgerTxEditorFeeAmount,
              controller: _feeAmountController,
            ),
          ],
        ];

      case TransactionType.adjustment:
        return [
          _buildAccountDropdown(l10n),
          const SizedBox(height: 16),
          _buildAssetDropdown(l10n),
          const SizedBox(height: 16),
          _buildAmountField(
            l10n,
            L10nKeys.ledgerTxEditorAmount,
            helperText: l10n.get(L10nKeys.ledgerTxEditorAdjustmentHelper),
          ),
        ];
    }
  }

  Widget _buildAccountDropdown(LocalizationService l10n, {String label = ''}) {
    final labelText = label.isEmpty ? L10nKeys.ledgerTxEditorAccount : label;
    return DropdownButtonFormField<Account>(
      initialValue: _selectedAccount,
      decoration: InputDecoration(labelText: l10n.get(labelText)),
      items: _accounts
          .map(
            (account) =>
                DropdownMenuItem(value: account, child: Text(account.name)),
          )
          .toList(),
      onChanged: (account) => setState(() => _selectedAccount = account),
      validator: (value) => value == null
          ? l10n.get(L10nKeys.ledgerTxEditorAccountRequired)
          : null,
    );
  }

  Widget _buildToAccountDropdown(LocalizationService l10n) {
    return DropdownButtonFormField<Account>(
      initialValue: _toAccount,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorToAccount),
      ),
      items: _accounts
          .where((a) => a.id != _selectedAccount?.id)
          .map(
            (account) =>
                DropdownMenuItem(value: account, child: Text(account.name)),
          )
          .toList(),
      onChanged: (account) => setState(() => _toAccount = account),
      validator: (value) => value == null
          ? l10n.get(L10nKeys.ledgerTxEditorToAccountRequired)
          : null,
    );
  }

  Widget _buildAssetDropdown(LocalizationService l10n) {
    return DropdownButtonFormField<Asset>(
      initialValue: _selectedAsset,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorAsset),
      ),
      items: _assets
          .map(
            (asset) => DropdownMenuItem(
              value: asset,
              child: Text('${asset.symbol} - ${asset.name}'),
            ),
          )
          .toList(),
      onChanged: (asset) => setState(() => _selectedAsset = asset),
      validator: (value) =>
          value == null ? l10n.get(L10nKeys.ledgerTxEditorAssetRequired) : null,
    );
  }

  Widget _buildFromAssetDropdown(LocalizationService l10n) {
    return DropdownButtonFormField<Asset>(
      initialValue: _fromAsset,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorFromAsset),
      ),
      items: _assets
          .map(
            (asset) => DropdownMenuItem(
              value: asset,
              child: Text('${asset.symbol} - ${asset.name}'),
            ),
          )
          .toList(),
      onChanged: (asset) => setState(() => _fromAsset = asset),
      validator: (value) => value == null
          ? l10n.get(L10nKeys.ledgerTxEditorFromAssetRequired)
          : null,
    );
  }

  Widget _buildToAssetDropdown(LocalizationService l10n) {
    return DropdownButtonFormField<Asset>(
      initialValue: _toAsset,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorToAsset),
      ),
      items: _assets
          .where((a) => a.id != _fromAsset?.id)
          .map(
            (asset) => DropdownMenuItem(
              value: asset,
              child: Text('${asset.symbol} - ${asset.name}'),
            ),
          )
          .toList(),
      onChanged: (asset) => setState(() => _toAsset = asset),
      validator: (value) => value == null
          ? l10n.get(L10nKeys.ledgerTxEditorToAssetRequired)
          : null,
    );
  }

  Widget _buildFeeAssetDropdown(LocalizationService l10n) {
    return DropdownButtonFormField<Asset>(
      initialValue: _feeAsset,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorFeeAsset),
        hintText: l10n.get(L10nKeys.ledgerTxEditorFeeAssetHint),
      ),
      items: [
        DropdownMenuItem<Asset>(
          value: null,
          child: Text(l10n.get(L10nKeys.ledgerTxEditorNoFee)),
        ),
        ..._assets.map(
          (asset) => DropdownMenuItem(
            value: asset,
            child: Text('${asset.symbol} - ${asset.name}'),
          ),
        ),
      ],
      onChanged: (asset) => setState(() => _feeAsset = asset),
    );
  }

  Widget _buildCategoryDropdown(LocalizationService l10n, String kind) {
    final filteredCategories = _categories
        .where((c) => c.kind.name == kind || c.kind == CategoryKind.mixed)
        .toList();

    return DropdownButtonFormField<Category>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: l10n.get(L10nKeys.ledgerTxEditorCategory),
      ),
      items: filteredCategories
          .map(
            (category) =>
                DropdownMenuItem(value: category, child: Text(category.name)),
          )
          .toList(),
      onChanged: (category) => setState(() => _selectedCategory = category),
      validator: (value) {
        if (_type == TransactionType.expense && value == null) {
          return l10n.get(L10nKeys.ledgerTxEditorCategoryRequired);
        }
        return null;
      },
    );
  }

  Widget _buildAmountField(
    LocalizationService l10n,
    String labelKey, {
    TextEditingController? controller,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller ?? _amountController,
      decoration: InputDecoration(
        labelText: l10n.get(labelKey),
        helperText: helperText,
        prefixIcon: const Icon(Icons.attach_money),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\-?\d*\.?\d*')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.get(L10nKeys.ledgerTxEditorAmountRequired);
        }
        final amount = double.tryParse(value.trim());
        if (amount == null || amount == 0) {
          return l10n.get(L10nKeys.ledgerTxEditorAmountInvalid);
        }
        return null;
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
